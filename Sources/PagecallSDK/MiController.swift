//
//  MiController.swift
//  
//
//  Created by Jaeseong Seo on 2023/03/16.
//

import Foundation
import Mediasoup

class MiController: MediaController {
    func start(callback: (Error?) -> Void) {
        callback(PagecallError(message: "Not implemented"))
    }

    func pauseAudio(callback: (Error?) -> Void) {
        callback(PagecallError(message: "Not implemented"))
    }

    func resumeAudio(callback: (Error?) -> Void) {
        callback(PagecallError(message: "Not implemented"))
    }

    func setAudioDevice(deviceId: String, callback: (Error?) -> Void) {
        callback(PagecallError(message: "Not implemented"))
    }

    func getAudioDevices() -> [MediaDeviceInfo] {
        return []
    }

    func requestAudioVolume(callback: @escaping (Float?, Error?) -> Void) {
        callback(nil, PagecallError(message: "Not implemented"))
    }

    func dispose() {
        // TODO
    }

}
