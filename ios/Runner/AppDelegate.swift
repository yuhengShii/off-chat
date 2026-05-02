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

    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "Runner") else {
      return
    }
    let messenger = registrar.messenger()

    let gattServerChannel = FlutterMethodChannel(name: "off_chat/ble_gatt_server", binaryMessenger: messenger)
    let gattServerEvents = FlutterEventChannel(name: "off_chat/ble_gatt_server_events", binaryMessenger: messenger)

    bleGattServer = BleGattServer()

    gattServerChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
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

    gattServerEvents.setStreamHandler(GattServerStreamHandler(
      onListen: { [weak self] (eventSink: @escaping FlutterEventSink) in
        self?.eventSink = eventSink
      },
      onCancel: { [weak self] in
        self?.eventSink = nil
      }
    ))
  }
}

private class GattServerStreamHandler: NSObject, FlutterStreamHandler {
  private let onListen: (FlutterEventSink) -> Void
  private let onCancel: () -> Void

  init(onListen: @escaping (FlutterEventSink) -> Void, onCancel: @escaping () -> Void) {
    self.onListen = onListen
    self.onCancel = onCancel
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    onListen(events)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    onCancel()
    return nil
  }
}
