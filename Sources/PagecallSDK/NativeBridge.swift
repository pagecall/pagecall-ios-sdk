//
//  NativeBridge.swift
//
//
//  Created by 록셉 on 2022/07/26.
//

import Foundation
import WebKit

class NativeBridge {
    let webview: WKWebView
    let ChimeController: ChimeController = .init()

    init(webview: WKWebView) { self.webview = webview }

    func emit(eventName: String) {
        self.webview.evaluateJavaScript("window.PagecallNative.emit('\(eventName)')") { _, error in
            if let error = error {
                NSLog("Failed to PagecallNative.emit \(error)")
            }
        }
    }

    func emit(eventName: String, data: Data) {
        if let string = String(data: data, encoding: .utf8) {
            self.webview.evaluateJavaScript("window.PagecallNative.emit('\(eventName)','\(string)')") { _, error in
                if let error = error {
                    NSLog("Failed to PagecallNative.emit \(error)")
                }
            }
        }
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

    func messageHandler(message: String) {
        do {
            let data = message.data(using: .utf8)!
            guard let jsonArray = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
            else {
                NSLog("Failed to JSONSerialization")
                return
            }
            guard let action = jsonArray["action"] as? String, let requestId = jsonArray["requestId"] as? String?, let payload = jsonArray["payload"] as? String? else {
                return
            }

            switch action {
            case "connect":
                print("connect")
                if let payloadData = payload?.data(using: .utf8) {
                    self.ChimeController.connect(joinMeetingData: payloadData)
                }
            case "pauseAudio":
                print("pause audio")
            case "resumeAudio":
                print("resume audio")
            case "setAudioDevice":
                print("set audio device")
            case "getAudioDevices":
                print("get audio devices")
                let data = try JSONSerialization.data(withJSONObject: [])
                self.response(requestId: requestId, data: data)
            default:
                break
            }
        } catch let error as NSError {
            print(error)
        }
    }
}
