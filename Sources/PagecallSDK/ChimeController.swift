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

        startHandlingInterruption()
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
        stopHandlingInterruption()
        if let audioRecorder = self.audioRecorder {
            audioRecorder.stop()
            self.audioRecorder = nil
        }
        chimeMeetingSession.dispose()
    }
}
