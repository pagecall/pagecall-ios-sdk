//
//  NativeBridge.swift
//
//
//  Created by 록셉 on 2022/07/26.
//

import WebKit
import AVFoundation

enum BridgeEvent: String, Codable {
    case audioDevice, audioDevices, audioVolume, audioStatus, audioSessionRouteChanged, audioSessionInterrupted, mediaStat, audioEnded, videoEnded, screenshareEnded, connected, disconnected, meetingEnded, log, error
    case connectTransport
}

enum BridgeRequest: String, Codable {
    case produce
}

enum BridgeAction: String, Codable {
    case initialize, dispose, start, getPermissions, requestPermission, pauseAudio, resumeAudio, getAudioDevices, setAudioDevice, requestAudioVolume, consume, response
}

class NativeBridge {
    let webview: WKWebView
    let emitter: WebViewEmitter
    var desiredMode: AVAudioSession.Mode?
    var mediaController: MediaController? {
        didSet {
            stopHandlingInterruption()
            if let mediaController = mediaController {
                if let _ = mediaController as? ChimeController {
                    desiredMode = .default
                } else {
                    desiredMode = .videoChat
                }
                startHandlingInterruption()
            }
        }
    }

    init(webview: WKWebView) {
        self.webview = webview
        self.emitter = .init(webView: self.webview)
    }

    func messageHandler(message: String) {
        do {
            let data = message.data(using: .utf8)!
            guard let jsonArray = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
            else {
                NSLog("Failed to JSONSerialization")
                return
            }
            guard let action = jsonArray["action"] as? String, let bridgeAction = BridgeAction(rawValue: action), let requestId = jsonArray["requestId"] as? String?, let payload = jsonArray["payload"] as? String? else {
                return
            }

            print("Bridge Action: \(bridgeAction)")

            let respond: (Error?, Data?) -> Void = { error, data in
                if let error = error {
                    if let requestId = requestId {
                        self.emitter.response(requestId: requestId, errorMessage: error.localizedDescription)
                    } else {
                        self.emitter.error(name: "RequestFailed", message: error.localizedDescription)
                    }
                } else {
                    if let requestId = requestId {
                        self.emitter.response(requestId: requestId, data: data)
                    } else {
                        print("Missing requestId", jsonArray)
                        self.emitter.error(name: "RequestIdMissing", message: "\(bridgeAction) succeeded without requestId")
                    }
                }
            }

            let payloadData = payload?.data(using: .utf8)

            switch bridgeAction {
            case .initialize:
                if let _ = mediaController {
                    respond(PagecallError(message: "Must be disposed first"), nil)
                    return
                }
                guard let payloadData = payload?.data(using: .utf8) else {
                    respond(PagecallError(message: "Missing payload"), nil)
                    return
                }
                struct MiPayload: Codable {
                    let plugin: String
                }
                if let meetingSessionConfiguration = JoinRequestService.getMeetingSessionConfiguration(data: payloadData) {
                    mediaController = ChimeController(emitter: emitter, configuration: meetingSessionConfiguration)
                    respond(nil, nil)
                } else if let initialPayload = try? JSONDecoder().decode(MiInitialPayload.self, from: payloadData) {
                    do {
                        let miController = try MiController(emitter: emitter, initialPayload: initialPayload)
                        mediaController = miController
                        respond(nil, nil)
                    } catch {
                        respond(error, nil)
                    }
                }
                return
            case .getPermissions:
                guard let payloadData = payloadData else {
                    respond(PagecallError(message: "Missing payload"), nil)
                    return
                }
                if let permissions = NativeBridge.getPermissions(constraint: payloadData, callback: { (error: Error?) in
                    respond(error, nil)
                }) {
                    respond(nil, permissions)
                }
                return
            case .requestPermission:
                guard let payloadData = payloadData else {
                    respond(PagecallError(message: "Missing payload"), nil)
                    return
                }
                NativeBridge.requestPermission(data: payloadData, callback: { (isGranted: Bool?, error: Error?) in
                    if let error = error {
                        respond(error, nil)
                    } else if let isGranted = isGranted {
                        guard let data = try? JSONEncoder().encode(isGranted) else { return }
                        respond(nil, data)
                    }
                })
                return
            case .getAudioDevices:
                let deviceList: [MediaDeviceInfo] = {
                    if let chimeController = mediaController as? ChimeController {
                        return chimeController.getAudioDevices()
                    } else {
                        return [MediaDeviceInfo.audioDefault]
                    }
                }()
                do {
                    let data = try JSONEncoder().encode(deviceList)
                    respond(nil, data)
                } catch {
                    respond(error, nil)
                }
                return
            case .requestAudioVolume:
                requestAudioVolume { volume, error in
                    if let error = error {
                        respond(error, nil)
                    } else if let volume = volume {
                        guard let data = try? JSONEncoder().encode(volume) else { return }
                        respond(nil, data)
                    }
                }
                return
            case .response:
                struct ResponsePayload: Codable {
                    let eventId: String
                    let error: String?
                    let result: String?
                }
                if let payloadData = payloadData, let responsePayload = try? JSONDecoder().decode(ResponsePayload.self, from: payloadData) {
                    emitter.resolve(eventId: responsePayload.eventId, error: responsePayload.error, result: responsePayload.result)
                } else {
                    print("Invalid response data")
                }
                return
            // These actions require mediaController
            case .pauseAudio: fallthrough
            case .resumeAudio: fallthrough
            case .setAudioDevice: fallthrough
            case .consume: fallthrough
            case .dispose: fallthrough
            case .start: fallthrough
            default: break
            }

            guard let mediaController = mediaController else {
                respond(PagecallError(message: "Missing mediaController, initialize first"), nil)
                return
            }

            switch bridgeAction {
            case .start:
                mediaController.start { (error: Error?) in
                    respond(error, nil)
                }
            case .dispose:
                mediaController.dispose()
                self.mediaController = nil
                respond(nil, nil)
            case .pauseAudio:
                mediaController.pauseAudio { (error: Error?) in
                    respond(error, nil)
                }
            case .resumeAudio:
                mediaController.resumeAudio { (error: Error?) in
                    respond(error, nil)
                }
            case .setAudioDevice:
                struct DeviceId: Codable {
                    var deviceId: String
                }
                guard let payloadData = payloadData, let deviceId = try? JSONDecoder().decode(DeviceId.self, from: payloadData) else {
                    respond(PagecallError(message: "Invalid payload"), nil)
                    return
                }

                guard let chimeController = mediaController as? ChimeController else {
                    // No op for miController
                    return
                }
                chimeController.setAudioDevice(deviceId: deviceId.deviceId) { (error: Error?) in
                    respond(error, nil)
                }
            case .consume:
                if let miController = mediaController as? MiController {
                    if let payloadData = payloadData {
                        miController.consume(data: payloadData) { error in
                            respond(error, nil)
                        }
                    } else {
                        respond(PagecallError(message: "Invalid payload"), nil)
                    }
                } else {
                    respond(PagecallError(message: "consume is only effective for MI"), nil)
                }
            case .getAudioDevices: fatalError()
            case .initialize: fatalError()
            case .getPermissions: fatalError()
            case .requestPermission: fatalError()
            case .response: fatalError()
            case .requestAudioVolume: fatalError()
            }
        } catch let error as NSError {
            print(error)
        }
    }

    private func normalizeSoundLevel(level: Float) -> Float {
        let lowLevel: Float = -40
        let highLevel: Float = -10

        var level = max(0.0, level - lowLevel)
        level = min(level, highLevel - lowLevel)
        return level / (highLevel - lowLevel) // scaled to 0.0 ~ 1
    }

    private var audioRecorder: AVAudioRecorder?
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

    public func disconnect() {
        mediaController?.dispose()
        mediaController = nil
    }

    deinit {
        audioRecorder?.stop()
        disconnect()
    }
}

struct MediaConstraints: Codable {
    var audio: Bool?
    var video: Bool?
}

struct MediaType: Codable {
    var mediaType: String
}

extension NativeBridge {
    static func getPermissions(constraint: Data, callback: (Error?) -> Void) -> Data? {
        guard let mediaType = try? JSONDecoder().decode(MediaConstraints.self, from: constraint) else {
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

        if let data = try? JSONEncoder().encode(MediaConstraints(audio: getAudioStatus(), video: getVideoStatus())) {
            return data
        } else {
            callback(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to getPermissions"]))
            return nil
        }
    }

    static func requestPermission(data: Data, callback: @escaping (Bool?, Error?) -> Void) {
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
}
