//
//  ChimeController.swift
//
//
//  Created by 록셉 on 2022/07/27.
//

import AmazonChimeSDK
import AVFoundation

class ChimeController: MediaController {
    let emitter: WebViewEmitter
    let chimeMeetingSession: ChimeMeetingSession
    var audioRecorder: AVAudioRecorder?

    init(emitter: WebViewEmitter, configuration: MeetingSessionConfiguration) {
        self.emitter = emitter

        let logger = ConsoleLogger(name: "DefaultMeetingSession", level: LogLevel.INFO)
        let chimeMeetingSession = ChimeMeetingSession(configuration: configuration, logger: logger, emitter: emitter)
        self.chimeMeetingSession = chimeMeetingSession

        self.setAudioSessionCategory()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleAudioSessionRouteChange),
                                               name: AVAudioSession.routeChangeNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleAudioSessionInterruption),
                                               name: AVAudioSession.interruptionNotification,
                                               object: nil)
    }

    @objc private func handleAudioSessionInterruption(notification: Notification) {
        self.emitter.log(name: "AVAudioSession", message: "AudioSessionInterruption notification name=\(notification.name)")

        var payloadType: String
        var payloadReason: String
        var payloadOptions: String

        if notification.name == AVAudioSession.interruptionNotification {
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
    }

    @objc private func handleAudioSessionRouteChange(notification: Notification) {
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

    private func normalizeSoundLevel(level: Float) -> Float {
        let lowLevel: Float = -40
        let highLevel: Float = -10

        var level = max(0.0, level - lowLevel)
        level = min(level, highLevel - lowLevel)
        return level / (highLevel - lowLevel) // scaled to 0.0 ~ 1
    }

    func requestAudioVolume(callback: @escaping (Float?, Error?) -> Void) {
        if let audioRecorder = audioRecorder {
            audioRecorder.updateMeters()
            let averagePower = audioRecorder.averagePower(forChannel: 0)
            let nomalizedVolume = normalizeSoundLevel(level: averagePower)
            callback(nomalizedVolume, nil)
            return
        }
        do {
            let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = documentPath.appendingPathComponent("nothing.m4a")
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            let audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            self.audioRecorder = audioRecorder
            audioRecorder.isMeteringEnabled = true
            audioRecorder.record()

            audioRecorder.updateMeters()
            let averagePower = audioRecorder.averagePower(forChannel: 0)
            let nomalizedVolume = normalizeSoundLevel(level: averagePower)
            callback(nomalizedVolume, nil)
        } catch {
            callback(nil, NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "AudioRecorder is not exist"]))
        }
    }

    func start(callback: (Error?) -> Void) {
        chimeMeetingSession.start { (error: Error?) in
            if error != nil {
                callback(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to start session"]))
            } else {
                try? AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.mixWithOthers, .allowBluetooth])
                callback(nil)
            }
        }
    }

    func pauseAudio(callback: (Error?) -> Void) {
            let isSucceed = chimeMeetingSession.pauseAudio()
            if isSucceed {
                callback(nil)
            } else {
                callback(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed at chimeMeetingSession.pauseAudio"]))
            }
    }

    func resumeAudio(callback: (Error?) -> Void) {
            let isSucceed = chimeMeetingSession.resumeAudio()
            if isSucceed {
                callback(nil)
            } else {
                callback(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed at chimeMeetingSession.resumeAudio"]))
                return
            }
    }

    func setAudioDevice(deviceId: String, callback: (Error?) -> Void) {
        chimeMeetingSession.setAudioDevice(label: deviceId)
        callback(nil)
    }

    func getAudioDevices() -> [MediaDeviceInfo] {
        let audioDevices = chimeMeetingSession.getAudioDevices()
        return audioDevices.map(MediaDeviceInfo.init)
    }

    func dispose() {
        NotificationCenter.default.removeObserver(self)
        if let audioRecorder = self.audioRecorder {
            audioRecorder.stop()
            self.audioRecorder = nil
        }
        chimeMeetingSession.dispose()
    }
}
