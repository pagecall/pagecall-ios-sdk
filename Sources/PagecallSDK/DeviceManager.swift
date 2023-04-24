import AVFoundation

class DeviceManager {
    static func getAuthorizationStatusAsBool(for type: AVMediaType) -> Bool? {
        let status = AVCaptureDevice.authorizationStatus(for: type)
        switch status {
        case .notDetermined: return nil
        case .restricted: return false
        case .denied: return false
        case .authorized: return true
        default: return nil
        }
    }

    static func requestAccess(for type: AVMediaType, callback: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: type, completionHandler: callback)
    }
}
