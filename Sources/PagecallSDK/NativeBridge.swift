//
//  NativeBridge.swift
//
//
//  Created by 록셉 on 2022/07/26.
//

import Foundation
import WebKit

enum BridgeEvent: String, Codable {
    case audioDevices, audioVolume, audioStatus, mediaStat, audioEnded, videoEnded, screenshareEnded, connected, disconnected, meetingEnded, error
}

enum BridgeAction: String, Codable {
    case createSession, start, stop, getPermissions, requestPermissions, pauseAudio, resumeAudio, getAudioDevices, setAudioDevice
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

    init(webView: WKWebView) {
        self.webview = webView
    }
}

class NativeBridge {
    let webview: WKWebView
    let emitter: WebViewEmitter
    let chimeController: ChimeController

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

            switch bridgeAction {
            case .createSession:
                if let payloadData = payload?.data(using: .utf8) {
                    self.chimeController.createMeetingSession(joinMeetingData: payloadData) { (error: Error?) in
                        if let error = error { print("Failed to createMeetingSession: \(error.localizedDescription)") }
                        else {
                            self.response(requestId: requestId)
                        }
                    }
                }
            case .start:
                self.chimeController.start { (error: Error?) in
                    if let error = error { print("Failed to start: \(error.localizedDescription)") }
                    else {
                        self.response(requestId: requestId)
                    }
                }
            case .stop:
                self.chimeController.stop { (error: Error?) in
                    if let error = error {
                        print("Failed to stop: \(error.localizedDescription)")
                        self.response(requestId: requestId, errorMessage: error.localizedDescription)
                    } else {
                        self.response(requestId: requestId)
                    }
                }
            case .getPermissions:
                if let payloadData = payload?.data(using: .utf8) {
                    if let permissions = self.chimeController.getPermissions(constraint: payloadData, callback: { (error: Error?) in
                        if let error = error {
                            print("Failed to getPermissions: \(error.localizedDescription)")
                            self.response(requestId: requestId, errorMessage: error.localizedDescription)
                        }
                    }) {
                        self.response(requestId: requestId, data: permissions)
                    }
                }
                self.response(requestId: requestId, data: data)
            case .pauseAudio:
                self.chimeController.pauseAudio { (error: Error?) in
                    if let error = error { print("Failed to pauseAudio: \(error.localizedDescription)") }
                }
            case .resumeAudio:
                self.chimeController.resumeAudio { (error: Error?) in
                    if let error = error { print("Failed to resumeAudio: \(error.localizedDescription)") }
                }
            case .setAudioDevice:
                if let payloadData = payload?.data(using: .utf8) {
                    self.chimeController.setAudioDevice(deviceData: payloadData) { (error: Error?) in
                        if let error = error { print("Failed to setAudioDevice: \(error.localizedDescription)") }
                    }
                }
            case .getAudioDevices:
                let mediaDeviceInfoList = self.chimeController.getAudioDevices()
                do {
                    let data = try JSONEncoder().encode(mediaDeviceInfoList)
                    self.response(requestId: requestId, data: data)
                } catch {
                    print("Failed to getAudioDevices")
                    self.response(requestId: requestId, errorMessage: error.localizedDescription)
                }

            default:
                break
            }
        } catch let error as NSError {
            print(error)
        }
    }
}
