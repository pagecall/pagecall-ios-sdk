//
//  ChimeDeviceChangeObserver.swift
//
//
//  Created by 록셉 on 2022/12/14.
//

import AmazonChimeSDK
import Foundation

class ChimeDeviceChangeObserver: DeviceChangeObserver {
    let emitter: WebViewEmitter

    func audioDeviceDidChange(freshAudioDeviceList: [AmazonChimeSDK.MediaDevice]) {
        let audioDeviceInfoList = freshAudioDeviceList.map { mediaDevice in
            MediaDeviceInfo(deviceId: mediaDevice.label, groupId: "DefaultGroupId", kind: .audioinput, label: mediaDevice.label)
        }

        if let data = try? JSONEncoder().encode(audioDeviceInfoList) {
            self.emitter.emit(eventName: .audioDevices, data: data)
        }
    }

    init(emitter: WebViewEmitter) {
        self.emitter = emitter
    }
}
