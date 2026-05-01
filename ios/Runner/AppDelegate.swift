import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  var bleGattServer: BleGattServer?
  var eventSink: FlutterEventSink?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let messenger = engineBridge.pluginRegistry.methodChannelMessenger()
    let gattServerChannel = FlutterMethodChannel(name: "off_chat/ble_gatt_server", binaryMessenger: messenger)
    let gattServerEvents = FlutterEventChannel(name: "off_chat/ble_gatt_server_events", binaryMessenger: messenger)

    bleGattServer = BleGattServer()

    gattServerChannel.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "initialize":
        if let sink = self?.eventSink {
          result(self?.bleGattServer?.initialize(sink: sink) ?? false)
        } else {
          result(false)
        }
      case "startAdvertising":
        result(true) // iOS CBPeripheralManager starts advertising after service is added
      case "stopAdvertising":
        self?.bleGattServer?.close()
        result(true)
      case "sendNotification":
        if let args = call.arguments as? [String: Any],
           let data = args["data"] as? FlutterStandardTypedData {
          result(self?.bleGattServer?.sendNotification(data: data) ?? false)
        } else {
          result(false)
        }
      case "dispose":
        self?.bleGattServer?.close()
        self?.bleGattServer = nil
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    gattServerEvents.setStreamHandler(StreamHandler { [weak self] (eventSink: @escaping FlutterEventSink) in
      self?.eventSink = eventSink
    } onCancel: { [weak self] in
      self?.eventSink = nil
    })
  }
}
