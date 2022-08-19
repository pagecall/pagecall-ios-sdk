//
//  MediaDevice.swift
//
//
//  Created by 록셉 on 2022/08/12.
//

import Foundation

enum MediaDeviceKind: String, Codable {
    case audioinput, audiooutput, videoinput
}

struct MediaDeviceInfo: Codable {
    var deviceId: String
    var groupId: String
    var kind: MediaDeviceKind
    var label: String
}
