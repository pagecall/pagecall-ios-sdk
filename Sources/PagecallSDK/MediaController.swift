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
    var emitter: WebViewEmitter { get }
    func start(callback: @escaping (Error?) -> Void)
    func pauseAudio(callback: (Error?) -> Void)
    func resumeAudio(callback: (Error?) -> Void)
    func requestAudioVolume(callback: @escaping (Float?, Error?) -> Void)
    func dispose()
}
