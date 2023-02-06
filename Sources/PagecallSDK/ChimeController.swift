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
    var audioRecorder: AVAudioRecorder?

    init(emitter: WebViewEmitter) {
        self.emitter = emitter
        self.setAudioSessionCategory()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleAudioSessionRouteChange),
                                               name: AVAudioSession.routeChangeNotification,
                                               object: nil)
    }

    @objc private func handleAudioSessionRouteChange(notification: Notification) {
        self.emitter.log(name: "AVAudioSession", message: "AudioSessionRouteChange notification name=\(notification.name)")
        let audioSession = AVAudioSession.sharedInstance()
        guard let routeChangeReason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
        let reason = AVAudioSession.RouteChangeReason(rawValue: routeChangeReason) else { return }

        switch reason {
        case AVAudioSession.RouteChangeReason.unknown:
            self.emitter.log(name: "AVAudioSession", message: "AudioSessionRouteChange Reason : The reason is unknown.")
        case AVAudioSession.RouteChangeReason.newDeviceAvailable:
            self.emitter.log(name: "AVAudioSession", message: "AudioSessionRouteChange Reason : A new device became available")
        case AVAudioSession.RouteChangeReason.oldDeviceUnavailable:
            self.emitter.log(name: "AVAudioSession", message: "AudioSessionRouteChange Reason : The old device became unavailable")
        case AVAudioSession.RouteChangeReason.categoryChange:
            self.emitter.log(name: "AVAudioSession", message: "AudioSessionRouteChange Reason : The audio category has changed")
            self.emitter.log(name: "AVAudioSession", message: "AudioSessionRouteChange Category = \(audioSession.category.rawValue)")
        case AVAudioSession.RouteChangeReason.override:
            self.emitter.log(name: "AVAudioSession", message: "AudioSessionRouteChange Reason : The route has been overridden")
        case AVAudioSession.RouteChangeReason.wakeFromSleep:
            self.emitter.log(name: "AVAudioSession", message: "AudioSessionRouteChange Reason : The device woke from sleep.")
        case AVAudioSession.RouteChangeReason.noSuitableRouteForCategory:
            self.emitter.log(name: "AVAudioSession", message: "AudioSessionRouteChange Reason : Returned when there is no route for the current category")
        case AVAudioSession.RouteChangeReason.routeConfigurationChange:
            self.emitter.log(name: "AVAudioSession", message: "AudioSessionRouteChange Reason : Indicates that the set of input and/our output ports has not changed, but some aspect of their configuration has changed.")
        default:
            break
        }

        let currentRoute = audioSession.currentRoute
        if !currentRoute.outputs.isEmpty {
            for description in currentRoute.outputs {
                self.emitter.log(name: "AVAudioSession", message: "AudioSessionRouteChange | portType=\(description.portType), portName=\(description.portName), UID=\(description.uid)")
            }
        } else {
            self.emitter.log(name: "AVAudioSession", message: "AudioSessionRouteChange | requires connection to device")
        }
        self.setAudioSessionCategory()
        /**
         * TODO: setIdiomPhoneOutputAudioPort() 
         * Ref: https://github.com/pplink/pagecall-ios-sdk/blob/main/PageCallSDK/PageCallSDK/Classes/PCMainViewController.m#L673-L841
         */
    }

    private func setAudioSessionCategory() {
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

    public func deleteMeetingSession() {
        if let chimeMeetingSession = chimeMeetingSession {
            chimeMeetingSession.dispose()
            self.chimeMeetingSession = nil
        }
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
        if let chimeMeetingSession = chimeMeetingSession {
            chimeMeetingSession.start { (error: Error?) in
                if error != nil {
                    callback(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to start session"]))
                } else {
                    try? AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.mixWithOthers, .allowBluetooth])
                    callback(nil)
                }
            }
        } else {
            callback(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "ChimeMeetingSession not exist"]))
        }
    }

    func stop(callback: (Error?) -> Void) {
        if let audioRecorder = audioRecorder {
            audioRecorder.stop()
            self.audioRecorder = nil
        }
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

        return audioDevices.map(MediaDeviceInfo.init)
    }

    func dispose(callback: (Error?) -> Void) {
        NotificationCenter.default.removeObserver(self)

        if self.audioRecorder != nil && self.chimeMeetingSession != nil {
            audioRecorder?.stop()
            self.audioRecorder = nil

            chimeMeetingSession?.dispose()
            self.chimeMeetingSession = nil

            callback(nil)
        } else {
            callback(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "chimeMeetingSession and audioRecorder not exist"]))
        }
    }
}
