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

    func connect(joinMeetingData: Data, callback: (Error?) -> Void) {
        let logger = ConsoleLogger(name: "DefaultMeetingSession", level: LogLevel.INFO)

        let meetingSessionConfiguration = JoinRequestService.getMeetingSessionConfiguration(data: joinMeetingData)

        guard let meetingSessionConfiguration = meetingSessionConfiguration else {
            callback(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse joinMeetingData"]))
            return
        }

        self.chimeMeetingSession = ChimeMeetingSession(configuration: meetingSessionConfiguration, logger: logger, emitter: self.emitter)

        callback(nil)
    }

    func pauseAudio(callback: (Error?) -> Void) {
        if let chimeMeetingSession = self.chimeMeetingSession {
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
        if let chimeMeetingSession = self.chimeMeetingSession {
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

        guard let chimeMeetingSession = self.chimeMeetingSession else {
            callback(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "ChimeMeetingSession not exist"]))
            return
        }

        chimeMeetingSession.setAudioDevice(label: deviceId.deviceId)
        callback(nil)
    }

    func getAudioDevices() -> [MediaDeviceInfo] {
        let audioDevices = self.chimeMeetingSession?.getAudioDevices()

        guard let audioDevices = audioDevices else {
            return []
        }

        let audioDeviceInfoList = audioDevices.map { mediaDevice in
            MediaDeviceInfo(deviceId: mediaDevice.label, groupId: "DefaultGroupId", kind: .audioinput, label: mediaDevice.label)
        }

        return audioDeviceInfoList
    }
}
