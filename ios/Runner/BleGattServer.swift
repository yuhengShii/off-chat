import Foundation
import CoreBluetooth
import Flutter

class BleGattServer: NSObject {
    private var peripheralManager: CBPeripheralManager?
    private var rxCharacteristic: CBMutableCharacteristic?
    private var eventSink: FlutterEventSink?
    private var isReady = false

    private let nusServiceUuid = CBUUID(string: "6e400001-b5a3-f393-e0a9-e50e24dcca9e")
    private let txCharUuid = CBUUID(string: "6e400002-b5a3-f393-e0a9-e50e24dcca9e")
    private let rxCharUuid = CBUUID(string: "6e400003-b5a3-f393-e0a9-e50e24dcca9e")

    override init() {
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }

    func initialize(sink: @escaping FlutterEventSink) -> Bool {
        eventSink = sink
        return true
    }

    func sendNotification(data: FlutterStandardTypedData) -> Bool {
        guard isReady, let rxChar = rxCharacteristic else { return false }

        let value = Data(data.data)
        return peripheralManager?.updateValue(value, for: rxChar, onSubscribedCentrals: nil) ?? false
    }

    func close() {
        peripheralManager?.stopAdvertising()
        peripheralManager = nil
        eventSink = nil
    }
}

extension BleGattServer: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            let txCharacteristic = CBMutableCharacteristic(
                type: txCharUuid,
                properties: [.write, .writeWithoutResponse],
                value: nil,
                permissions: .writeable
            )

            let rxCharacteristic = CBMutableCharacteristic(
                type: rxCharUuid,
                properties: [.notify],
                value: nil,
                permissions: .readable
            )
            self.rxCharacteristic = rxCharacteristic

            let service = CBMutableService(type: nusServiceUuid, primary: true)
            service.characteristics = [txCharacteristic, rxCharacteristic]

            peripheralManager?.add(service)

            peripheralManager?.startAdvertising([
                CBAdvertisementDataServiceUUIDsKey: [nusServiceUuid]
            ])
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            if request.characteristic.uuid == txCharUuid {
                peripheral.respond(to: request, withResult: .success)

                if let value = request.value {
                    let args: [String: Any] = [
                        "type": "data",
                        "data": [UInt8](value)
                    ]
                    eventSink?(args)
                }
            }
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        eventSink?(["type": "connected"])
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        eventSink?(["type": "disconnected"])
    }
}
