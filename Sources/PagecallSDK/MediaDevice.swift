//
//  MediaDevice.swift
//
//
//  Created by 록셉 on 2022/08/12.
//

enum MediaDeviceKind: String, Codable {
    case audioinput, audiooutput, videoinput
}

struct MediaDeviceInfo: Codable {
    let deviceId: String
    let groupId: String
    let kind: MediaDeviceKind
    let label: String

    static let audioDefault = MediaDeviceInfo(deviceId: "audio0", groupId: "", kind: .audioinput, label: "Default")
}
