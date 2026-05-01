package com.offchat.off_chat

import android.os.Build
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val gattServerChannel = "off_chat/ble_gatt_server"
    private val gattServerEvents = "off_chat/ble_gatt_server_events"
    private var bleGattServer: BleGattServer? = null
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        bleGattServer = BleGattServer(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, gattServerChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "initialize" -> {
                        // eventSink may not be set yet, that's OK — it will be set when stream connects
                        val success = bleGattServer?.initialize(eventSink) ?: false
                        result.success(success)
                    }
                    "startAdvertising" -> {
                        val success = bleGattServer?.startAdvertising() ?: false
                        result.success(success)
                    }
                    "stopAdvertising" -> {
                        bleGattServer?.stopAdvertising()
                        result.success(true)
                    }
                    "sendNotification" -> {
                        val data = call.argument<List<Int>>("data")?.toByteArray()
                        if (data != null) {
                            val success = bleGattServer?.sendNotification(data) ?: false
                            result.success(success)
                        } else {
                            result.success(false)
                        }
                    }
                    "dispose" -> {
                        bleGattServer?.close()
                        bleGattServer = null
                        result.success(true)
                    }
                    "setAdapterName" -> {
                        val name = call.argument<String>("name") ?: ""
                        val success = bleGattServer?.setAdapterName(name) ?: false
                        result.success(success)
                    }
                    "getRingerMode" -> {
                        val mode = bleGattServer?.getRingerMode() ?: "normal"
                        result.success(mode)
                    }
                    "notifyMessage" -> {
                        bleGattServer?.notifyMessage()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, gattServerEvents)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    bleGattServer?.setEventSink(events)
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    bleGattServer?.setEventSink(null)
                }
            })
    }

    override fun onDestroy() {
        bleGattServer?.close()
        bleGattServer = null
        super.onDestroy()
    }
}

private fun List<Int>.toByteArray(): ByteArray {
    return ByteArray(size) { this[it].toByte() }
}
