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
    let meetingSession: MeetingSession

    func audioDeviceDidChange(freshAudioDeviceList: [AmazonChimeSDK.MediaDevice]) {
        let audioDeviceInfoList = freshAudioDeviceList.map(MediaDeviceInfo.init)

        if let data = try? JSONEncoder().encode(audioDeviceInfoList) {
            self.emitter.emit(eventName: .audioDevices, data: data)
        }

        let audioDevice = self.meetingSession.audioVideo.getActiveAudioDevice()

        if let audioDevice = audioDevice {
            let audioDeviceInfo = MediaDeviceInfo(mediaDevice: audioDevice)
            if let data = try? JSONEncoder().encode(audioDeviceInfo) {
                self.emitter.emit(eventName: .audioDevice, data: data)
            }
        }
    }

    init(emitter: WebViewEmitter, meetingSession: MeetingSession) {
        self.emitter = emitter
        self.meetingSession = meetingSession
    }
}
