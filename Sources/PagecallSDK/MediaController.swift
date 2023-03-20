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

extension MediaController {
    func setAudioSessionCategory() {
        let audioSession: AVAudioSession = AVAudioSession.sharedInstance()
        var options: AVAudioSession.CategoryOptions
        if #available(iOS 14.5, *) {
            options = [.mixWithOthers,
                    .allowBluetooth,
                    .allowAirPlay,
                    .allowBluetoothA2DP,
                    .overrideMutedMicrophoneInterruption,
                    .interruptSpokenAudioAndMixWithOthers,
                    .defaultToSpeaker]
        } else {
            options = [.mixWithOthers,
                    .allowBluetooth,
                    .allowAirPlay,
                    .allowBluetoothA2DP,
                    .defaultToSpeaker]
        }
        try? audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: options)
    }

    private func handleRouteChange(notification: Notification) {
        self.emitter.log(name: "AVAudioSession", message: "AudioSessionRouteChange notification name=\(notification.name)")
        let audioSession = AVAudioSession.sharedInstance()
        guard let routeChangeReason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: routeChangeReason) else { return }
        let currentRouteOutputs: [[String: String]] = audioSession.currentRoute.outputs.map { output in
            return ["portType": output.portType.rawValue,
                    "portName": output.portName,
                    "uid": output.uid]
        }
        if #available(iOS 13.0, *) { // .withoutEscapingSlashes is available from iOS 13
            guard let payload = try? JSONSerialization.data(withJSONObject: ["reason": reason.description,
                                                                             "outputs": currentRouteOutputs,
                                                                             "category": audioSession.category.rawValue] as [String: Any],
                                                            options: .withoutEscapingSlashes) else { return }

            self.emitter.emit(eventName: .audioSessionRouteChanged, data: payload)
        }

        if audioSession.currentRoute.outputs.isEmpty {
            self.emitter.error(name: "AVAudioSession", message: "AudioSessionRouteChange | requires connection to device")
        }
        self.setAudioSessionCategory()

        /**
         * TODO: setIdiomPhoneOutputAudioPort()
         * Ref: https://github.com/pplink/pagecall-ios-sdk/blob/main/PageCallSDK/PageCallSDK/Classes/PCMainViewController.m#L673-L841
         */
    }

    private func handleInterruption(notification: Notification) {
        self.emitter.log(name: "AVAudioSession", message: "AudioSessionInterruption notification name=\(notification.name)")

        var payloadType: String
        var payloadReason: String
        var payloadOptions: String

        if #available(iOS 14.5, *) {
            let interruptionType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            if let interruptionType = interruptionType,
               let type = AVAudioSession.InterruptionType(rawValue: interruptionType) {
                payloadType = type.description
            } else {
                payloadType = "None"
            }

            let interruptionReason = notification.userInfo?[AVAudioSessionInterruptionReasonKey] as? UInt
            if let interruptionReason = interruptionReason,
               let reason = AVAudioSession.InterruptionReason(rawValue: interruptionReason) {
                payloadReason = reason.description
            } else {
                payloadReason = "None"
            }

            let interruptionOptions = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt
            if let interruptionOptions = interruptionOptions {
                let options = AVAudioSession.InterruptionOptions(rawValue: interruptionOptions)
                payloadOptions = options.description
            } else {
                payloadOptions = "None"
            }

            guard let payload = try? JSONSerialization.data(withJSONObject: ["type": payloadType,
                                                                             "reason": payloadReason,
                                                                             "options": payloadOptions] as [String: Any],
                                                            options: .withoutEscapingSlashes) else { return }
            self.emitter.emit(eventName: .audioSessionInterrupted, data: payload)
        }
    }

    func startHandlingInterruption() {
        self.setAudioSessionCategory()
        NotificationCenter.default.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main, using: self.handleRouteChange)
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main, using: self.handleInterruption)
    }

    func stopHandlingInterruption() {
        NotificationCenter.default.removeObserver(self.handleRouteChange)
        NotificationCenter.default.removeObserver(self.handleInterruption)
    }
}
