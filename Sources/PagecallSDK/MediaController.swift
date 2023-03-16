//
//  MediaController.swift
//  
//
//  Created by Jaeseong Seo on 2023/03/16.
//

import AVFoundation

extension AVAudioSession.RouteChangeReason {
    var description: String {
        switch self {
        case .newDeviceAvailable:
            return "NewDeviceAvailable"
        case .oldDeviceUnavailable:
            return "OldDeviceUnavailable"
        case .categoryChange:
            return "CategoryChange"
        case .override:
            return "Override"
        case .wakeFromSleep:
            return "WakeFromSleep"
        case .noSuitableRouteForCategory:
            return "NoSuitableRouteForCategory"
        case .routeConfigurationChange:
            return "RouteConfigurationChange"
        default:
            return "Unknown"
        }
    }
}
extension AVAudioSession.InterruptionType {
    var description: String {
        switch self {
        case .began:
            return "Began"
        case .ended:
            return "Ended"
        default:
            return "Unknown"
        }
    }
}
extension AVAudioSession.InterruptionReason {
    var description: String {
        switch self {
        case .default:
            return "Default"
        case .builtInMicMuted:
            return "BuiltInMicMuted"
        default:
            return "Unknown"
        }
    }
}

extension AVAudioSession.InterruptionOptions {
    var description: String {
        switch self {
        case .shouldResume:
            return "ShouldResume"
        default:
            return "Unknown"
        }
    }
}

protocol MediaController {
    func start(callback: (Error?) -> Void)
    func stop(callback: (Error?) -> Void)
    func pauseAudio(callback: (Error?) -> Void)
    func resumeAudio(callback: (Error?) -> Void)
    func dispose(callback: (Error?) -> Void)
    func setAudioDevice(deviceId: String, callback: (Error?) -> Void)
    func getAudioDevices() -> [MediaDeviceInfo]
    func requestAudioVolume(callback: @escaping (Float?, Error?) -> Void)
}

struct MediaConstraints: Codable {
    var audio: Bool?
    var video: Bool?
}

struct MediaType: Codable {
    var mediaType: String
}

extension MediaController {
    func getPermissions(constraint: Data, callback: (Error?) -> Void) -> Data? {
        guard let mediaType = try? JSONDecoder().decode(MediaConstraints.self, from: constraint) else {
            callback(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Wrong Constraint"]))
            return nil
        }

        func getAudioStatus() -> Bool? {
            if let audio = mediaType.audio {
                if !audio { return nil }
                let status = AVCaptureDevice.authorizationStatus(for: .audio)
                switch status {
                    case .notDetermined: return nil
                    case .restricted: return false
                    case .denied: return false
                    case .authorized: return true
                    default: return nil
                }
            } else { return nil }
        }
        func getVideoStatus() -> Bool? {
            if let video = mediaType.video {
                if !video { return nil }
                let status = AVCaptureDevice.authorizationStatus(for: .video)
                switch status {
                    case .notDetermined: return nil
                    case .restricted: return false
                    case .denied: return false
                    case .authorized: return true
                    default: return nil
                }
            } else { return nil }
        }

        if let data = try? JSONEncoder().encode(MediaConstraints(audio: getAudioStatus(), video: getVideoStatus())) {
            return data
        } else {
            callback(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to getPermissions"]))
            return nil
        }
    }

    func requestPermission(data: Data, callback: @escaping (Bool?, Error?) -> Void) {
        guard let mediaType = try? JSONDecoder().decode(MediaType.self, from: data) else {
            callback(nil, NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Wrong Constraint"]))
            return
        }

        func requestPermission(callback: @escaping (Bool) -> Void) {
            if mediaType.mediaType == "audio" {
                AVCaptureDevice.requestAccess(for: .audio) {
                    isGranted in callback(isGranted)
                }
            } else if mediaType.mediaType == "video" {
                AVCaptureDevice.requestAccess(for: .video) {
                    isGranted in callback(isGranted)
                }
            } else { callback(false) }
        }

        requestPermission { isGranted in callback(isGranted, nil) }
    }
}
