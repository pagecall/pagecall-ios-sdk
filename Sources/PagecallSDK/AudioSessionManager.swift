import AVFoundation

class AudioSessionManager {
    public var desiredMode: AVAudioSession.Mode? {
        didSet {
            setAudioSessionCategory()
        }
    }
    public weak var emitter: WebViewEmitter?

    static var instance: AudioSessionManager?

    static func shared() -> AudioSessionManager {
        if let instance = instance {
            return instance
        } else {
            let newInstance = AudioSessionManager()
            instance = newInstance
            return newInstance
        }
    }

    static func clear() {
        self.instance = nil
    }

    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleRouteChange), name: AVAudioSession.routeChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption), name: AVAudioSession.interruptionNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setAudioSessionCategory() {
        let audioSession: AVAudioSession = AVAudioSession.sharedInstance()

        if let builtin = audioSession.availableInputs?.first(where: { port in
            return port.portType == .builtInMic
        }), let front = builtin.dataSources?.first(where: { source in
            return source.orientation == .front
        }) {
            /**
             Once `MiController.start` is called and transmission begins, the microphone is arbitrarily selected.
             We explicitly set the front-facing microphone as it's most suited for calls while looking at the screen together.
             */
            do {
                try builtin.setPreferredDataSource(front)
            } catch {
                emitter?.error(name: "AVAudioSession", message: "setPreferredDataSource: \(error.localizedDescription)")
            }
        }

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
        if audioSession.category != .playAndRecord {
            do {
                try audioSession.setCategory(.playAndRecord, options: options)
            } catch {
                emitter?.error(name: "AVAudioSession", message: "setCategory: \(error.localizedDescription)")
            }
            do {
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            } catch {
                emitter?.error(name: "AVAudioSession", message: "setActive: \(error.localizedDescription)")
            }
        }
        if let desiredMode = desiredMode, desiredMode != audioSession.mode {
            do {
                try audioSession.setMode(desiredMode)
            } catch {
                emitter?.error(name: "AVAudioSession", message: "setMode: \(error.localizedDescription)")
            }
        }
    }

    @objc private func handleRouteChange(notification: Notification) {
        self.emitter?.log(name: "AVAudioSession", message: "AudioSessionRouteChange notification name=\(notification.name)")
        let audioSession = AVAudioSession.sharedInstance()
        guard let routeChangeReason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: routeChangeReason) else { return }
        let currentRouteOutputs: [[String: String]] = audioSession.currentRoute.outputs.map { output in
            return ["portType": output.portType.rawValue,
                    "portName": output.portName,
                    "uid": output.uid]
        }

        let routeChangeDetail: [String: Any] = [
            "reason": reason.description,
            "outputs": currentRouteOutputs,
            "category": audioSession.category.rawValue
        ]
        print("[AudioSessionManager] routeChange", routeChangeDetail)
        guard let payload = try? JSONSerialization.data(withJSONObject: routeChangeDetail, options: .withoutEscapingSlashes) else { return }

        self.emitter?.emit(eventName: .audioSessionRouteChanged, data: payload)

        if audioSession.currentRoute.outputs.isEmpty {
            self.emitter?.error(name: "AVAudioSession", message: "AudioSessionRouteChange | requires connection to device")
        }
        self.setAudioSessionCategory()

        /**
         * TODO: setIdiomPhoneOutputAudioPort()
         * Ref: https://github.com/pplink/pagecall-ios-sdk/blob/main/PageCallSDK/PageCallSDK/Classes/PCMainViewController.m#L673-L841
         */
    }

    @objc private func handleInterruption(notification: Notification) {
        self.emitter?.log(name: "AVAudioSession", message: "AudioSessionInterruption notification name=\(notification.name)")

        var payloadType: String
        var payloadReason = "Unknown"
        var payloadOptions: String

        if let interruptionType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
           let type = AVAudioSession.InterruptionType(rawValue: interruptionType) {
            payloadType = type.description
        } else {
            payloadType = "None"
        }

        if #available(iOS 14.5, *) {
            if let interruptionReason = notification.userInfo?[AVAudioSessionInterruptionReasonKey] as? UInt,
               let reason = AVAudioSession.InterruptionReason(rawValue: interruptionReason) {
                payloadReason = reason.description
            } else {
                payloadReason = "None"
            }
        }

        if let interruptionOptions = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt {
            let options = AVAudioSession.InterruptionOptions(rawValue: interruptionOptions)
            payloadOptions = options.description
        } else {
            payloadOptions = "None"
        }

        let interruptionDetail: [String: Any] = [
            "type": payloadType,
            "reason": payloadReason,
            "options": payloadOptions
        ]
        print("[AudioSessionManager] interrupt", interruptionDetail)
        guard let payload = try? JSONSerialization.data(withJSONObject: interruptionDetail, options: .withoutEscapingSlashes) else { return }
        self.emitter?.emit(eventName: .audioSessionInterrupted, data: payload)
    }
}

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
