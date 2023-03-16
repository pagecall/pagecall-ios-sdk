//
//  NativeBridge.swift
//
//
//  Created by 록셉 on 2022/07/26.
//

import Foundation
import WebKit
import AVFoundation

enum BridgeEvent: String, Codable {
    case audioDevice, audioDevices, audioVolume, audioStatus, audioSessionRouteChanged, audioSessionInterrupted, mediaStat, audioEnded, videoEnded, screenshareEnded, connected, disconnected, meetingEnded, log, error
}

enum BridgeAction: String, Codable {
    case initialize, dispose, start, getPermissions, requestPermission, pauseAudio, resumeAudio, getAudioDevices, setAudioDevice, requestAudioVolume
}

struct ErrorEvent: Codable {
    let name: String
    let message: String?
}

class WebViewEmitter {
    let webview: WKWebView

    func emit(eventName: BridgeEvent) {
        self.webview.evaluateJavaScript("window.PagecallNative.emit('\(eventName)')") { _, error in
            if let error = error {
                NSLog("Failed to PagecallNative.emit \(error)")
            }
        }
    }

    func emit(eventName: BridgeEvent, message: String) {
        self.webview.evaluateJavaScript("window.PagecallNative.emit('\(eventName)','\(message)')") { _, error in
            if let error = error {
                NSLog("Failed to PagecallNative.emit \(error)")
            }
        }
    }

    func emit(eventName: BridgeEvent, data: Data) {
        if let string = String(data: data, encoding: .utf8) {
            self.emit(eventName: eventName, message: string)
        }
    }

    func error(name: String, message: String?) {
        NSLog("errorLog \(name) \(String(describing: message))")
        guard let data = try? JSONEncoder().encode(ErrorEvent(name: name, message: message)) else { return }
        self.emit(eventName: .error, data: data)
    }

    func log(name: String, message: String?) {
        NSLog("log \(name) \(String(describing: message))")
        guard let data = try? JSONEncoder().encode(ErrorEvent(name: name, message: message)) else { return }
        self.emit(eventName: .log, data: data)
    }

    init(webView: WKWebView) {
        self.webview = webView
    }
}

class NativeBridge {
    let webview: WKWebView
    let emitter: WebViewEmitter
    var mediaController: MediaController?

    init(webview: WKWebView) {
        self.webview = webview
        self.emitter = .init(webView: self.webview)
    }

    func response(requestId: String?) {
        guard let requestId = requestId else {
            return
        }

        self.webview.evaluateJavaScript("window.PagecallNative.response('\(requestId)')") { _, error in
            if let error = error {
                NSLog("Failed to PagecallNative.response \(error)")
            }
        }
    }

    func response(requestId: String?, data: Data) {
        guard let requestId = requestId else {
            return
        }

        let string = String(data: data, encoding: .utf8)
        if let string = string {
            DispatchQueue.main.async {
                self.webview.evaluateJavaScript("window.PagecallNative.response('\(requestId)','\(string)')") { _, error in
                    if let error = error {
                        NSLog("Failed to PagecallNative.response \(error)")
                    }
                }
            }
        }
    }

    func response(requestId: String?, errorMessage: String) {
        guard let requestId = requestId else {
            return
        }

        self.webview.evaluateJavaScript("window.PagecallNative.throw('\(requestId)','\(errorMessage)')") { _, error in
            if let error = error {
                NSLog("Failed to PagecallNative.response \(error)")
            }
        }
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

            if bridgeAction == .getPermissions {
                if let payloadData = payload?.data(using: .utf8) {
                    if let permissions = NativeBridge.getPermissions(constraint: payloadData, callback: { (error: Error?) in
                        if let error = error {
                            self.emitter.error(name: "Failed to getPermissions", message: error.localizedDescription)
                            self.response(requestId: requestId, errorMessage: error.localizedDescription)
                        }
                    }) {
                        self.response(requestId: requestId, data: permissions)
                    }
                } else {
                    self.response(requestId: requestId, errorMessage: "Wrong payload")
                }
                return
            } else if bridgeAction == .requestPermission {
                if let payloadData = payload?.data(using: .utf8) {
                    NativeBridge.requestPermission(data: payloadData, callback: { (isGranted: Bool?, error: Error?) in
                        if let error = error {
                            self.emitter.error(name: "Failed to requestPermission", message: error.localizedDescription)
                            self.response(requestId: requestId, errorMessage: error.localizedDescription)
                        } else if let isGranted = isGranted {
                            guard let data = try? JSONEncoder().encode(isGranted) else { return }
                            self.response(requestId: requestId, data: data)
                        }
                    })
                } else {
                    self.response(requestId: requestId, errorMessage: "Wrong payload")
                }
                return
            } else if bridgeAction == .initialize {
                if let _ = mediaController {
                    self.response(requestId: requestId, errorMessage: "Must be disposed first")
                    return
                }
                guard let payloadData = payload?.data(using: .utf8) else {
                    self.response(requestId: requestId, errorMessage: "Missing payload")
                    return
                }
                struct MiPayload: Codable {
                    let plugin: String
                }
                if let meetingSessionConfiguration = JoinRequestService.getMeetingSessionConfiguration(data: payloadData) {
                    mediaController = ChimeController(emitter: emitter, configuration: meetingSessionConfiguration)
                    self.response(requestId: requestId)
                } else if let _ = try? JSONDecoder().decode(MiPayload.self, from: payloadData) {
                    // TODO make use of the payload
                    mediaController = MiController()
                }
            }

            guard let mediaController = mediaController else {
                self.response(requestId: requestId, errorMessage: "Missing mediaController, initialize first")
                return
            }

            switch bridgeAction {
            case .start:
                mediaController.start { (error: Error?) in
                    if let error = error {
                        self.emitter.error(name: "Failed to start", message: error.localizedDescription)
                    } else {
                        self.response(requestId: requestId)
                    }
                }
            case .dispose:
                mediaController.dispose()
                self.response(requestId: requestId)
            case .pauseAudio:
                mediaController.pauseAudio { (error: Error?) in
                    if let error = error {
                        self.emitter.error(name: "Failed to pauseAudio", message: error.localizedDescription)
                    }
                }
            case .resumeAudio:
                mediaController.resumeAudio { (error: Error?) in
                    if let error = error {
                        self.emitter.error(name: "Failed to resumeAudio", message: error.localizedDescription)
                    }
                }
            case .setAudioDevice:
                struct DeviceId: Codable {
                    var deviceId: String
                }
                guard let payloadData = payload?.data(using: .utf8), let deviceId = try? JSONDecoder().decode(DeviceId.self, from: payloadData) else {
                    let message = "deviceId does not exist"
                    self.emitter.error(name: message, message: message)
                    return
                }

                mediaController.setAudioDevice(deviceId: deviceId.deviceId) { (error: Error?) in
                    if let error = error {
                        self.emitter.error(name: "Failed to setAudioDevice", message: error.localizedDescription)
                    }
                }
            case .getAudioDevices:
                let mediaDeviceInfoList = mediaController.getAudioDevices()
                do {
                    let data = try JSONEncoder().encode(mediaDeviceInfoList)
                    self.response(requestId: requestId, data: data)
                } catch {
                    self.emitter.error(name: "Failed to getAudioDevices", message: error.localizedDescription)
                    self.response(requestId: requestId, errorMessage: error.localizedDescription)
                }
            case .requestAudioVolume:
                mediaController.requestAudioVolume { volume, error in
                    if let error = error {
                        self.emitter.error(name: "Failed to requestAudioVolume", message: error.localizedDescription)
                        self.response(requestId: requestId, errorMessage: error.localizedDescription)
                    } else if let volume = volume {
                        guard let data = try? JSONEncoder().encode(volume) else { return }
                        self.response(requestId: requestId, data: data)
                    }
                }
            case .initialize: fatalError()
            case .getPermissions: fatalError()
            case .requestPermission: fatalError()
            }
        } catch let error as NSError {
            print(error)
        }
    }

    public func disconnect() {
        mediaController?.dispose()
        mediaController = nil
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
