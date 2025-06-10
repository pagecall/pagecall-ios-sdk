import AVFoundation
import Combine

class AudioSessionManager {
    private weak var emitter: WebViewEmitter?

    private var cancellables = Set<AnyCancellable>()

    private let activationTrigger = PassthroughSubject<Void, Never>()

    private var volumeRecorder: VolumeRecorder?

    init(_ callManager: CallManager) {
        self.emitter = callManager.getEmitter()

        if #available(iOS 14.5, *) {
            try? AVAudioSession().setPrefersNoInterruptionsFromSystemAlerts(true)
        }

        NotificationCenter.default.addObserver(self, selector: #selector(handleRouteChange), name: AVAudioSession.routeChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption), name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleMediaServicesReset), name: AVAudioSession.mediaServicesWereResetNotification, object: nil)

        var retryTimer: Timer?
        var retryDelay: TimeInterval = 0.5

        activationTrigger.prepend(()).sink { [weak self] _ in
            guard let strongSelf = self else { return }
            let audioSession: AVAudioSession = AVAudioSession.sharedInstance()
            do {
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
                        strongSelf.emitter?.error(name: "AVAudioSession", message: "setPreferredDataSource: \(error.localizedDescription)")
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

                try audioSession.setCategory(.playAndRecord, mode: .videoChat, options: options) // MI에서는 default일 경우 에어팟 연결이 해제된다.
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

                retryTimer?.invalidate()
                retryTimer = nil
                retryDelay = 0.5

                do {
                    strongSelf.volumeRecorder?.destroy()
                    strongSelf.volumeRecorder = try VolumeRecorder(strongSelf)
                } catch {
                    strongSelf.emitter?.error(name: "AVAudioSession", message: "Failed to initialize volumeRecorder: \(error.localizedDescription)")
                }
            } catch {
                strongSelf.emitter?.error(name: "AVAudioSession", message: "activationError: \(error.localizedDescription), nextRetryDelay: \(retryDelay)")

                DispatchQueue.main.async {
                    retryTimer = Timer.scheduledTimer(withTimeInterval: retryDelay, repeats: false) { [weak self] _ in
                        retryDelay *= 2
                        self?.activationTrigger.send()
                    }
                }
            }
        }
        .store(in: &cancellables)
    }

    func averagePower() -> Float? {
        return self.volumeRecorder?.averagePower()
    }

    func dispose() {
        NotificationCenter.default.removeObserver(self)
        cancellables.forEach { $0.cancel() }
        volumeRecorder?.destroy()
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
        activationTrigger.send()
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

    @objc private func handleMediaServicesReset(notification: Notification) {
        self.emitter?.log(name: "AVAudioSession", message: "MediaServicesReset notification name=\(notification.name)")

        let detail = notification.userInfo as? [String: Any] ?? [String: Any]()
        print("[AudioSessionManager] mediaServicesWereReset", detail)
        guard let payload = try? JSONSerialization.data(withJSONObject: detail, options: .withoutEscapingSlashes) else { return }
        self.emitter?.emit(eventName: .mediaServicesReset, data: payload)
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
