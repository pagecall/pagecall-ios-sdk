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

    init(emitter: WebViewEmitter, configuration: MeetingSessionConfiguration) {
        self.emitter = emitter

        let logger = ConsoleLogger(name: "DefaultMeetingSession", level: LogLevel.INFO)
        let chimeMeetingSession = ChimeMeetingSession(configuration: configuration, logger: logger, emitter: emitter)
        self.chimeMeetingSession = chimeMeetingSession
    }

    func start(callback: (Error?) -> Void) {
        chimeMeetingSession.start(callback: callback)
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
        chimeMeetingSession.dispose()
    }

    deinit {
        dispose()
    }
}
