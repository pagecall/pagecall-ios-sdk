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
    let audioRecorder: AVAudioRecorder?

    init(emitter: WebViewEmitter) {
        self.emitter = emitter
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playAndRecord, mode: .default, options: [])

        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentPath.appendingPathComponent("nothing.m4a")
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            let audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            self.audioRecorder = audioRecorder
            audioRecorder.isMeteringEnabled = true
            audioRecorder.record()
        } catch {
            self.audioRecorder = nil
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

    private func normalizeSoundLevel(level: Float) -> Float {
        let lowLevel: Float = -40
        let highLevel: Float = -10

        var level = max(0.0, level - lowLevel)
        level = min(level, highLevel - lowLevel)
        return level / (highLevel - lowLevel) // scaled to 0.0 ~ 1
    }

    func requestAudioVolume(callback: @escaping (Float?, Error?) -> Void) {
        guard let audioRecorder = audioRecorder else {
            callback(nil, NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "AudioRecorder is not exist"]))
            return
        }
        audioRecorder.updateMeters()
        let averagePower = audioRecorder.averagePower(forChannel: 0)
        print(averagePower)
        let nomalizedVolume = normalizeSoundLevel(level: averagePower)
        print(nomalizedVolume)
        callback(nomalizedVolume, nil)
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

    func getPermissions(constraint: Data, callback: (Error?) -> Void) -> Data? {
        struct MediaType: Codable {
            var audio: Bool?
            var video: Bool?
        }

        guard let mediaType = try? JSONDecoder().decode(MediaType.self, from: constraint) else {
            callback(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Wrong Constraint"]))
            return nil
        }

        func getAudioStatus() -> Bool? {
            if let audio = mediaType.audio {
                if !audio { return nil }
                let status = AVCaptureDevice.authorizationStatus(for: .audio)
                switch status {
                    case .notDetermined: return nil
                    case .restricted: return false
                    case .denied: return false
                    case .authorized: return true
                    default: return nil
                }
            } else { return nil }
        }
        func getVideoStatus() -> Bool? {
            if let video = mediaType.video {
                if !video { return nil }
                let status = AVCaptureDevice.authorizationStatus(for: .video)
                switch status {
                    case .notDetermined: return nil
                    case .restricted: return false
                    case .denied: return false
                    case .authorized: return true
                    default: return nil
                }
            } else { return nil }
        }

        if let data = try? JSONEncoder().encode(MediaType(audio: getAudioStatus(), video: getVideoStatus())) {
            return data
        } else {
            callback(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to getPermissions"]))
            return nil
        }
    }

    func requestPermission(data: Data, callback: @escaping (Bool?, Error?) -> Void) {
        struct MediaType: Codable {
            var mediaType: String
        }
        guard let mediaType = try? JSONDecoder().decode(MediaType.self, from: data) else {
            callback(nil, NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Wrong Constraint"]))
            return
        }

        func requestPermission(callback: @escaping (Bool) -> Void) {
            if mediaType.mediaType == "audio" {
                AVCaptureDevice.requestAccess(for: .audio) {
                    isGranted in callback(isGranted)
                }
            } else if mediaType.mediaType == "video" {
                AVCaptureDevice.requestAccess(for: .video) {
                    isGranted in callback(isGranted)
                }
            } else { callback(false) }
        }

        requestPermission { isGranted in callback(isGranted, nil) }
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
                callback(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed at chimeMeetingSession.resumeAudio"]))
                return
            }
        } else {
            callback(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "ChimeMeetingSession not exist"]))
        }
    }

    func setAudioDevice(deviceData: Data, callback: (Error?) -> Void) {
        struct DeviceId: Codable {
            var deviceId: String
        }

        guard let deviceId = try? JSONDecoder().decode(DeviceId.self, from: deviceData) else {
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
