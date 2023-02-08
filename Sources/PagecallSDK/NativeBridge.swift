//
//  NativeBridge.swift
//
//
//  Created by 록셉 on 2022/07/26.
//

import Foundation
import WebKit

enum BridgeEvent: String, Codable {
    case audioDevice, audioDevices, audioVolume, audioStatus, audioSessionRouteChanged, audioSessionInterrupted, mediaStat, audioEnded, videoEnded, screenshareEnded, connected, disconnected, meetingEnded, log, error
}

enum BridgeAction: String, Codable {
    case createSession, `init`, start, stop, getPermissions, requestPermission, pauseAudio, resumeAudio, getAudioDevices, setAudioDevice, requestAudioVolume, dispose
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
    var chimeController: ChimeController?

    init(webview: WKWebView) {
        self.webview = webview
        self.emitter = .init(webView: self.webview)
        self.chimeController = .init(emitter: self.emitter)
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
            self.webview.evaluateJavaScript("window.PagecallNative.response('\(requestId)','\(string)')") { _, error in
                if let error = error {
                    NSLog("Failed to PagecallNative.response \(error)")
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

            if bridgeAction == .`init` {
                if let _ = self.chimeController {
                    self.response(requestId: requestId, errorMessage: "ChimeController already exists")
                } else {
                    self.chimeController = .init(emitter: self.emitter)
                    self.response(requestId: requestId)
                }
            } else if let chimeController = self.chimeController {
                switch bridgeAction {
                case .`init`:
                    print("impossible to receive .`init` as a case when chimeController exists")
                case .createSession:
                    if let payloadData = payload?.data(using: .utf8) {
                        chimeController.createMeetingSession(joinMeetingData: payloadData) { (error: Error?) in
                            if let error = error {
                                self.emitter.error(name: "Failed to createMeetingSession", message: error.localizedDescription)
                            } else {
                                self.response(requestId: requestId)
                            }
                        }
                    }
                case .start:
                    chimeController.start { (error: Error?) in
                        if let error = error {
                            self.emitter.error(name: "Failed to start", message: error.localizedDescription)
                        } else {
                            self.response(requestId: requestId)
                        }
                    }
                case .stop:
                    chimeController.stop { (error: Error?) in
                        if let error = error {
                            self.emitter.error(name: "Failed to stop", message: error.localizedDescription)
                            self.response(requestId: requestId, errorMessage: error.localizedDescription)
                        } else {
                            self.response(requestId: requestId)
                        }
                    }
                case .dispose:
                    chimeController.dispose { (error: Error?) in
                        if let error = error {
                            print("Failed to dispose: \(error.localizedDescription)")
                            self.response(requestId: requestId, errorMessage: error.localizedDescription)
                        } else {
                            self.chimeController = nil
                            self.response(requestId: requestId)
                        }
                    }
                case .getPermissions:
                    if let payloadData = payload?.data(using: .utf8) {
                        if let permissions = chimeController.getPermissions(constraint: payloadData, callback: { (error: Error?) in
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
                case .requestPermission:
                    if let payloadData = payload?.data(using: .utf8) {
                        chimeController.requestPermission(data: payloadData, callback: { (isGranted: Bool?, error: Error?) in
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
                case .pauseAudio:
                    chimeController.pauseAudio { (error: Error?) in
                        if let error = error {
                            self.emitter.error(name: "Failed to pauseAudio", message: error.localizedDescription)
                        }
                    }
                case .resumeAudio:
                    chimeController.resumeAudio { (error: Error?) in
                        if let error = error {
                            self.emitter.error(name: "Failed to resumeAudio", message: error.localizedDescription)
                        }
                    }
                case .setAudioDevice:
                    if let payloadData = payload?.data(using: .utf8) {
                        chimeController.setAudioDevice(deviceData: payloadData) { (error: Error?) in
                            if let error = error {
                                self.emitter.error(name: "Failed to setAudioDevice", message: error.localizedDescription)
                            }
                        }
                    }
                case .getAudioDevices:
                    let mediaDeviceInfoList = chimeController.getAudioDevices()
                    do {
                        let data = try JSONEncoder().encode(mediaDeviceInfoList)
                        self.response(requestId: requestId, data: data)
                    } catch {
                        self.emitter.error(name: "Failed to getAudioDevices", message: error.localizedDescription)
                        self.response(requestId: requestId, errorMessage: error.localizedDescription)
                    }
                case .requestAudioVolume:
                    chimeController.requestAudioVolume { volume, error in
                        if let error = error {
                            self.emitter.error(name: "Failed to requestAudioVolume", message: error.localizedDescription)
                            self.response(requestId: requestId, errorMessage: error.localizedDescription)
                        } else if let volume = volume {
                            guard let data = try? JSONEncoder().encode(volume) else { return }
                            self.response(requestId: requestId, data: data)
                        }
                    }
                }
            } else {
                self.response(requestId: requestId, errorMessage: "ChimeController does not exist")
            }

        } catch let error as NSError {
            print(error)
        }
    }

    public func disconnect() {
        if let chimeController = self.chimeController {
              chimeController.dispose { (error: Error?) in
                if let error = error {
                    self.emitter.error(name: "ChimeController", message: "failed to dispose: \(error.localizedDescription)")
                } else {
                    self.emitter.log(name: "ChimeController", message: "dispose success")
                    self.chimeController = nil
                }
            }

        }
    }
}
