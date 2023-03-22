//
//  MediaDevice.swift
//
//
//  Created by 록셉 on 2022/08/12.
//

import AmazonChimeSDK

enum MediaDeviceKind: String, Codable {
    case audioinput, audiooutput, videoinput
}

struct MediaDeviceInfo: Codable {
    let deviceId: String
    let groupId: String
    let kind: MediaDeviceKind
    let label: String

    init(mediaDevice: MediaDevice) {
        self.deviceId = mediaDevice.label
        self.groupId = "DefaultGroupId"
        self.kind = .audioinput
        self.label = mediaDevice.label
    }

    init(deviceId: String, groupId: String, kind: MediaDeviceKind, label: String) {
        self.deviceId = deviceId
        self.groupId = groupId
        self.kind = kind
        self.label = label
    }

    static let audioDefault = MediaDeviceInfo(deviceId: "audio0", groupId: "", kind: .audioinput, label: "Default")
}
