//
//  ChimeController.swift
//
//
//  Created by 록셉 on 2022/07/27.
//

import AmazonChimeSDK
import AVFoundation
import Foundation

class ChimeController {
    let emitter: WebViewEmitter
    var chimeMeetingSession: ChimeMeetingSession?

    init(emitter: WebViewEmitter) {
        self.emitter = emitter

        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                print("granted")
            } else {
                print("rejected")
            }
        }
    }

    func createMeetingSession(joinMeetingData: Data, callback: (Error?) -> Void) {
        let logger = ConsoleLogger(name: "DefaultMeetingSession", level: LogLevel.INFO)

        let meetingSessionConfiguration = JoinRequestService.getMeetingSessionConfiguration(data: joinMeetingData)

        guard let meetingSessionConfiguration = meetingSessionConfiguration else {
            callback(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse joinMeetingData"]))
            return
        }
        if let prevChimeMeetingSession = self.chimeMeetingSession {
            prevChimeMeetingSession.dispose()
        }

        let chimeMeetingSession = ChimeMeetingSession(configuration: meetingSessionConfiguration, logger: logger, emitter: emitter)
        self.chimeMeetingSession = chimeMeetingSession
        callback(nil)
    }

    func start(callback: (Error?) -> Void) {
        if let chimeMeetingSession = chimeMeetingSession {
            chimeMeetingSession.start { (error: Error?) in
                if error != nil {
                    callback(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to start session"]))
                } else {
                    callback(nil)
                }
            }
        } else {
            callback(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "ChimeMeetingSession not exist"]))
        }
    }

    func stop(callback: (Error?) -> Void) {
        if let chimeMeetingSession = chimeMeetingSession {
            chimeMeetingSession.stop()
            callback(nil)
        } else {
            callback(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "ChimeMeetingSession not exist"]))
        }
    }

    func pauseAudio(callback: (Error?) -> Void) {
        if let chimeMeetingSession = chimeMeetingSession {
            let isSucceed = chimeMeetingSession.pauseAudio()
            if isSucceed {
                callback(nil)
            } else {
                callback(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed at chimeMeetingSession.pauseAudio"]))
            }
        } else {
            callback(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "ChimeMeetingSession not exist"]))
        }
    }

    func resumeAudio(callback: (Error?) -> Void) {
        if let chimeMeetingSession = chimeMeetingSession {
            let isSucceed = chimeMeetingSession.resumeAudio()
            if isSucceed {
                callback(nil)
            } else {
                callback(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed at chimeMeetingSession.pauseAudio"]))
                return
            }
        } else {
            callback(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "ChimeMeetingSession not exist"]))
        }
    }

    func setAudioDevice(deviceData: Data, callback: (Error?) -> Void) {
        let jsonDecoder = JSONDecoder()
        struct DeviceId: Codable {
            var deviceId: String
        }

        guard let deviceId = try? jsonDecoder.decode(DeviceId.self, from: deviceData) else {
            callback(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "DeviceId not exist"]))
            return
        }

        guard let chimeMeetingSession = chimeMeetingSession else {
            callback(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "ChimeMeetingSession not exist"]))
            return
        }

        chimeMeetingSession.setAudioDevice(label: deviceId.deviceId)
        callback(nil)
    }

    func getAudioDevices() -> [MediaDeviceInfo] {
        guard let chimeMeetingSession = chimeMeetingSession else {
            return []
        }

        let audioDevices = chimeMeetingSession.getAudioDevices()

        return audioDevices.map { mediaDevice in
            MediaDeviceInfo(deviceId: mediaDevice.label, groupId: "DefaultGroupId", kind: .audioinput, label: mediaDevice.label)
        }
    }
}
