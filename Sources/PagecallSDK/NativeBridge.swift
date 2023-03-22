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
    case connectTransport
}

enum BridgeRequest: String, Codable {
    case produce
}

enum BridgeAction: String, Codable {
    case initialize, dispose, start, getPermissions, requestPermission, pauseAudio, resumeAudio, getAudioDevices, setAudioDevice, requestAudioVolume, consume, response
}

struct ErrorEvent: Codable {
    let name: String
    let message: String?
}

class WebViewEmitter {
    let webview: WKWebView

    private func rawEmit(eventName: String) {
        self.rawEmit(eventName: eventName, message: nil)
    }

    private func rawEmit(eventName: String, message: String?) {
        self.rawEmit(eventName: eventName, message: message, eventId: nil)
    }

    private func rawEmit(eventName: String, message: String?, eventId: String?) {
        let args = [eventName, message, eventId].compactMap { $0 }
        let script = "window.PagecallNative.emit(\(args.map { arg in "'\(arg)'" }.joined(separator: ",")))"
        DispatchQueue.main.async {
            self.webview.evaluateJavaScript(script) { _, error in
                if let error = error {
                    NSLog("Failed to PagecallNative.emit \(error)")
                }
            }
        }
    }

    func emit(eventName: BridgeEvent) {
        self.rawEmit(eventName: eventName.rawValue)
    }

    func emit(eventName: BridgeEvent, message: String) {
        self.rawEmit(eventName: eventName.rawValue, message: message)
    }

    private var eventIdToCallback = [String: (Error?, String?) -> Void]()

    func emit(eventName: BridgeEvent, json: [String: Any]) {
        self.jsonEmit(eventName: eventName.rawValue, json: json, callback: nil)

    }
    func request(eventName: BridgeRequest, json: [String: Any], callback: @escaping ((Error?, String?) -> Void)) {
        self.jsonEmit(eventName: eventName.rawValue, json: json, callback: callback)
    }

    private func jsonEmit(eventName: String, json: [String: Any], callback: ((Error?, String?) -> Void)?) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: json), let stringifiedJson = String(data: jsonData, encoding: .utf8) else {
            callback?(PagecallError(message: "Failed to stringify"), nil)
            return
        }
        if let callback = callback {
            let eventId = UUID().uuidString
            eventIdToCallback[eventId] = callback
            self.rawEmit(eventName: eventName, message: stringifiedJson, eventId: eventId)
        } else {
            self.rawEmit(eventName: eventName, message: stringifiedJson)
        }
    }

    func resolve(eventId: String, error: String?, result: String?) {
        if let callback = eventIdToCallback[eventId] {
            eventIdToCallback.removeValue(forKey: eventId)
            if let errorMessage = error {
                callback(PagecallError(message: errorMessage), nil)
            } else {
                callback(nil, result)
            }
        } else {
            print("Event not found (id: \(eventId)")
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

    func response(requestId: String, data: Data?) {
        let script: String = {
            if let data = data, let string = String(data: data, encoding: .utf8) {
                return "window.PagecallNative.response('\(requestId)', '\(string)')"
            } else {
                return "window.PagecallNative.response('\(requestId)')"
            }
        }()
        DispatchQueue.main.async {
            self.webview.evaluateJavaScript(script) { _, error in
                if let error = error {
                    NSLog("Failed to PagecallNative.response \(error)")
                }
            }
        }
    }

    func response(requestId: String, errorMessage: String) {
        DispatchQueue.main.async {
            self.webview.evaluateJavaScript("window.PagecallNative.throw('\(requestId)','\(errorMessage)')") { _, error in
                if let error = error {
                    NSLog("Failed to PagecallNative.response \(error)")
                }
            }
        }
    }

    init(webView: WKWebView) {
        self.webview = webView
    }
}

class NativeBridge {
    let webview: WKWebView
    let emitter: WebViewEmitter
    var mediaController: MediaController? {
        didSet {
            stopHandlingInterruption()
            if let _ = mediaController {
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

            if bridgeAction == .response {
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
            } else if bridgeAction == .getPermissions {
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
            } else if bridgeAction == .requestPermission {
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
            } else if bridgeAction == .initialize {
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
            } else if bridgeAction == .getAudioDevices {
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
            case .requestAudioVolume:
                mediaController.requestAudioVolume { volume, error in
                    if let error = error {
                        respond(error, nil)
                    } else if let volume = volume {
                        guard let data = try? JSONEncoder().encode(volume) else { return }
                        respond(nil, data)
                    }
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
