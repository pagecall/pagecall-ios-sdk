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

    init(webview: WKWebView) { self.webview = webview }

    func emit(eventName: String, data: Data) {
        let string = String(data: data, encoding: .utf8)
        if let string = string {
            self.webview.evaluateJavaScript("window.PagecallNative.emit('\(eventName)','\(string)')")
        }
    }

    func messageHandler(message: String) {
        let data = message.data(using: .utf8)!

        do {
            guard let jsonArray = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
            else {
                NSLog("Failed to JSONSerialization")
                return
            }
            guard let action = jsonArray["action"] as? String, let requestId = jsonArray["requestId"] as? String? else {
                return
            }

            func response(data: Data) {
                guard let requestId = requestId else {
                    return
                }
                let string = String(data: data, encoding: .utf8)
                if let string = string {
                    self.webview.evaluateJavaScript("window.PagecallNative.response('\(requestId)','\(string)')")
                }
            }

            switch action {
            case "pauseAudio":
                print("pause audio")
            case "resumeAudio":
                print("resume audio")
            case "setAudioDevice":
                print("set audio device")
            case "getAudioDevices":
                print("get audio devices")
                let data = try JSONSerialization.data(withJSONObject: [])
                response(data: data)
            default:
                break
            }

        } catch let error as NSError {
            print(error)
        }
    }
}
