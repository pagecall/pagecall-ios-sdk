import CoreBluetooth

// Notification name 정의
extension Notification.Name {
    static let applePencilConnectionChanged = Notification.Name("applePencilConnectionChanged")
}

class ApplePencilMonitor: NSObject, CBCentralManagerDelegate {

    private var centralManager: CBCentralManager!
    private var timer: Timer!
    private var applePencilConnected: Bool = false
    
    override init() {
        if Bundle.main.infoDictionary?["NSBluetoothAlwaysUsageDescription"] != nil {
            super.init()
            self.centralManager = CBCentralManager(delegate: self, queue: nil)
        } else {
            print("[ApplePencilMonitor] NSBluetoothAlwaysUsageDescription key is not found in Info.plist")
            super.init()
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            self.startPolling()
        } else {
            self.stopPolling()
        }
    }

    private func startPolling() {
        self.timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { timer in
            let services = [CBUUID(string: "180A")] // 180A is the service UUID for Device Information
            let devices = self.centralManager.retrieveConnectedPeripherals(withServices: services)
            for device in devices {
                if device.name == "Apple Pencil" {
                    // Pencil is connected
                    if !self.applePencilConnected {
                        self.applePencilConnected = true
                        NotificationCenter.default.post(name: .applePencilConnectionChanged, object: nil, userInfo: ["connected": true])
                    }
                    return
                }
            }
            // If no pencil is found
            if self.applePencilConnected {
                self.applePencilConnected = false
                NotificationCenter.default.post(name: .applePencilConnectionChanged, object: nil, userInfo: ["connected": false])
            }
        }
    }

    private func stopPolling() {
        self.timer?.invalidate()
        self.timer = nil
    }
    
    func dispose() {
        self.stopPolling()
        self.centralManager = nil
    }
    deinit {
        self.dispose()
    }
}
