package com.offchat.off_chat

import android.app.NotificationChannel
import android.app.NotificationManager
import android.bluetooth.*
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.content.Context
import android.media.RingtoneManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.ParcelUuid
import android.util.Log
import io.flutter.plugin.common.EventChannel
import java.util.*

class BleGattServer(private val context: Context) {
    companion object {
        private const val TAG = "BleGattServer"
        private val mainHandler = Handler(Looper.getMainLooper())
    }

    /** 在主线程上安全地发送 EventSink 事件 */
    private fun emitEvent(event: Map<String, Any?>) {
        mainHandler.post {
            try {
                eventSink?.success(event)
                Log.d(TAG, "emitEvent ok: type=${event["type"]}")
            } catch (e: Exception) {
                Log.e(TAG, "emitEvent failed: ${e.message}", e)
            }
        }
    }

    private var gattServer: BluetoothGattServer? = null
    private var connectedDevice: BluetoothDevice? = null
    private var eventSink: EventChannel.EventSink? = null
    private var isAdvertising = false

    private val nusServiceUuid = UUID.fromString("6e400001-b5a3-f393-e0a9-e50e24dcca9e")
    private val txCharUuid = UUID.fromString("6e400002-b5a3-f393-e0a9-e50e24dcca9e")
    private val rxCharUuid = UUID.fromString("6e400003-b5a3-f393-e0a9-e50e24dcca9e")

    fun initialize(sink: EventChannel.EventSink?): Boolean {
        if (sink != null) eventSink = sink
        return try {
            val manager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
            val server = manager.openGattServer(context, gattServerCallback)
            if (server == null) {
                Log.e(TAG, "openGattServer returned null")
                return false
            }
            gattServer = server

            val txCharacteristic = BluetoothGattCharacteristic(
                txCharUuid,
                BluetoothGattCharacteristic.PROPERTY_WRITE or BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE,
                BluetoothGattCharacteristic.PERMISSION_WRITE
            )

            val rxCharacteristic = BluetoothGattCharacteristic(
                rxCharUuid,
                BluetoothGattCharacteristic.PROPERTY_NOTIFY,
                BluetoothGattCharacteristic.PERMISSION_READ
            )

            val service = BluetoothGattService(
                nusServiceUuid,
                BluetoothGattService.SERVICE_TYPE_PRIMARY
            )
            service.addCharacteristic(txCharacteristic)
            service.addCharacteristic(rxCharacteristic)

            gattServer?.addService(service)
            Log.d(TAG, "initialize: service added, server=$gattServer")
            true
        } catch (e: Exception) {
            Log.e(TAG, "initialize failed: ${e.message}", e)
            false
        }
    }

    fun setEventSink(sink: EventChannel.EventSink?) {
        this.eventSink = sink
    }

    fun startAdvertising(): Boolean {
        if (isAdvertising) return true
        return try {
            val bluetoothAdapter = (context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager).adapter
            val advertiser = bluetoothAdapter.bluetoothLeAdvertiser ?: return false

            val settings = AdvertiseSettings.Builder()
                .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_BALANCED)
                .setConnectable(true)
                .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_MEDIUM)
                .build()

            val data = AdvertiseData.Builder()
                .addServiceUuid(ParcelUuid(nusServiceUuid))
                .build()

            // 设备名放在 scan response 中，避免 advertising data (31 字节限制) 超限
            val scanResponse = AdvertiseData.Builder()
                .setIncludeDeviceName(true)
                .build()

            advertiser.startAdvertising(settings, data, scanResponse, advertiseCallback)
            isAdvertising = true
            Log.d(TAG, "startAdvertising: success")
            true
        } catch (e: Exception) {
            Log.e(TAG, "startAdvertising failed: ${e.message}", e)
            false
        }
    }

    fun stopAdvertising() {
        try {
            val bluetoothAdapter = (context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager).adapter
            bluetoothAdapter.bluetoothLeAdvertiser?.stopAdvertising(advertiseCallback)
        } catch (_: Exception) {}
        isAdvertising = false
    }

    fun sendNotification(data: ByteArray): Boolean {
        val device = connectedDevice ?: return false
        val service = gattServer?.getService(nusServiceUuid) ?: return false
        val rxChar = service.getCharacteristic(rxCharUuid) ?: return false

        return try {
            rxChar.value = data
            gattServer?.notifyCharacteristicChanged(device, rxChar, false) ?: false
        } catch (e: Exception) {
            false
        }
    }

    fun close() {
        stopAdvertising()
        try {
            gattServer?.clearServices()
            gattServer?.close()
        } catch (_: Exception) {}
        gattServer = null
        connectedDevice = null
        eventSink = null
    }

    fun setAdapterName(name: String): Boolean {
        return try {
            val bluetoothAdapter = (context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager).adapter
            bluetoothAdapter.setName(name)
            Log.d(TAG, "setAdapterName: $name")
            true
        } catch (e: Exception) {
            Log.e(TAG, "setAdapterName failed: ${e.message}", e)
            false
        }
    }

    fun getRingerMode(): String {
        return try {
            val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as android.media.AudioManager
            when (audioManager.ringerMode) {
                android.media.AudioManager.RINGER_MODE_VIBRATE -> "vibrate"
                android.media.AudioManager.RINGER_MODE_SILENT -> "silent"
                else -> "normal"
            }
        } catch (e: Exception) {
            "normal"
        }
    }

    /** 通过 NotificationManager 发送新消息通知，系统自动处理声音/震动（尊重系统设置） */
    fun notifyMessage() {
        try {
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val channelId = "off_chat_messages"

            // Android 8.0+ 需要通知渠道
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    channelId,
                    "新消息",
                    NotificationManager.IMPORTANCE_HIGH // high = 有声音有震动
                ).apply {
                    description = "收到新聊天消息时通知"
                    enableVibration(true)
                }
                manager.createNotificationChannel(channel)
            }

            val notification = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                android.app.Notification.Builder(context, channelId)
                    .setSmallIcon(android.R.drawable.ic_dialog_info)
                    .setContentTitle("OffChat")
                    .setContentText("收到新消息")
                    .setAutoCancel(true)
                    .build()
            } else {
                android.app.Notification.Builder(context)
                    .setSmallIcon(android.R.drawable.ic_dialog_info)
                    .setContentTitle("OffChat")
                    .setContentText("收到新消息")
                    .setAutoCancel(true)
                    .setDefaults(android.app.Notification.DEFAULT_SOUND or android.app.Notification.DEFAULT_VIBRATE)
                    .build()
            }

            manager.notify(1001, notification)
            Log.d(TAG, "notifyMessage: ok")
        } catch (e: Exception) {
            Log.e(TAG, "notifyMessage failed: ${e.message}", e)
        }
    }

    private val advertiseCallback = object : AdvertiseCallback() {
        override fun onStartSuccess(settingsInEffect: AdvertiseSettings) {
            Log.d(TAG, "advertise onStartSuccess")
        }
        override fun onStartFailure(errorCode: Int) {
            Log.e(TAG, "advertise onStartFailure: $errorCode")
            isAdvertising = false
        }
    }

    private val gattServerCallback = object : BluetoothGattServerCallback() {
        override fun onCharacteristicWriteRequest(
            device: BluetoothDevice,
            requestId: Int,
            characteristic: BluetoothGattCharacteristic,
            preparedWrite: Boolean,
            responseNeeded: Boolean,
            offset: Int,
            value: ByteArray
        ) {
            Log.d(TAG, "onCharacteristicWriteRequest: uuid=${characteristic.uuid}, len=${value.size}")
            gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, offset, null)

            if (characteristic.uuid == txCharUuid) {
                emitEvent(mapOf(
                    "type" to "data",
                    "data" to value.toList()
                ))
            }
        }

        override fun onConnectionStateChange(device: BluetoothDevice, status: Int, newState: Int) {
            Log.d(TAG, "onConnectionStateChange: status=$status newState=$newState device=${device.address}")
            if (newState == BluetoothProfile.STATE_CONNECTED) {
                connectedDevice = device
                emitEvent(mapOf("type" to "connected"))
            } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                connectedDevice = null
                emitEvent(mapOf("type" to "disconnected"))
            }
        }

        override fun onServiceAdded(status: Int, service: BluetoothGattService) {
            Log.d(TAG, "onServiceAdded: status=$status uuid=${service.uuid}")
        }

        override fun onNotificationSent(device: BluetoothDevice, status: Int) {
            Log.d(TAG, "onNotificationSent: status=$status")
        }
    }
}
