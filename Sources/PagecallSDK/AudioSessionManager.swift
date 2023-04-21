import AVFoundation

class AudioSessionManager {
    static let shared = AudioSessionManager()
    public var desiredMode: AVAudioSession.Mode?
    public weak var emitter: WebViewEmitter?

    private init() {}

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
        if audioSession.category != .playAndRecord {
            try? audioSession.setCategory(.playAndRecord, options: options)
            try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        }
        if let desiredMode = desiredMode, desiredMode != audioSession.mode {
            try? audioSession.setMode(desiredMode)
        }
    }

    @objc private func handleRouteChange(notification: Notification) {
        self.emitter?.log(name: "AVAudioSession", message: "AudioSessionRouteChange notification name=\(notification.name)")
        print("AudioSessionRouteChange notification name=\(notification.name)")
        let audioSession = AVAudioSession.sharedInstance()
        guard let routeChangeReason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: routeChangeReason) else { return }
        let currentRouteOutputs: [[String: String]] = audioSession.currentRoute.outputs.map { output in
            return ["portType": output.portType.rawValue,
                    "portName": output.portName,
                    "uid": output.uid]
        }

        guard let payload = try? JSONSerialization.data(withJSONObject: ["reason": reason.description,
                                                                         "outputs": currentRouteOutputs,
                                                                         "category": audioSession.category.rawValue] as [String: Any],
                                                        options: .withoutEscapingSlashes) else { return }

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
        print("AudioSessionInterruption notification name=\(notification.name)")

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

        guard let payload = try? JSONSerialization.data(withJSONObject: ["type": payloadType,
                                                                         "reason": payloadReason,
                                                                         "options": payloadOptions] as [String: Any],
                                                        options: .withoutEscapingSlashes) else { return }
        self.emitter?.emit(eventName: .audioSessionInterrupted, data: payload)
    }

    func startHandlingInterruption() {
        self.setAudioSessionCategory()
        NotificationCenter.default.addObserver(self, selector: #selector(handleRouteChange), name: AVAudioSession.routeChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption), name: AVAudioSession.interruptionNotification, object: nil)
    }

    func stopHandlingInterruption() {
        NotificationCenter.default.removeObserver(self)
    }
}
