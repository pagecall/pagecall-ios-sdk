//
//  ChimeRealtimeObserver.swift
//
//
//  Created by 록셉 on 2022/08/16.
//

import AmazonChimeSDK
import Foundation

struct AudioStatus: Codable {
    let sessionId: String
    let muted: Bool
}

class ChimeRealtimeObserver: RealtimeObserver {
    let emitter: WebViewEmitter
    let myAttendeeId: String

    func volumeDidChange(volumeUpdates: [VolumeUpdate]) {
        for currentVolumeUpdate in volumeUpdates {
            if currentVolumeUpdate.attendeeInfo.attendeeId == self.myAttendeeId {
                var audioVolume: Double = 0
                switch currentVolumeUpdate.volumeLevel {
                case .notSpeaking:
                    audioVolume = 0
                case .low:
                    audioVolume = 0.25
                case .medium:
                    audioVolume = 0.5
                case .high:
                    audioVolume = 0.75
                default:
                    break
                }
                self.emitter.emit(eventName: .audioVolume, message: String(audioVolume))
            }
        }
    }

    func signalStrengthDidChange(signalUpdates: [SignalUpdate]) {}

    func attendeesDidJoin(attendeeInfo: [AttendeeInfo]) {
        for currentAttendeeInfo in attendeeInfo {
            // mute 상태로 입장하는 유저나, 이미 mute 상태로 방에 있었던 유저는 join 이후 mute event가 불리므로 기본적으로 unmute로 판단할 수 있음
            guard let data = try? JSONEncoder().encode(AudioStatus(sessionId: currentAttendeeInfo.externalUserId, muted: false)) else { return }
            self.emitter.emit(eventName: .audioStatus, data: data)
        }
    }

    func attendeesDidLeave(attendeeInfo: [AttendeeInfo]) {}

    func attendeesDidDrop(attendeeInfo: [AttendeeInfo]) {}

    func attendeesDidMute(attendeeInfo: [AttendeeInfo]) {
        for currentAttendeeInfo in attendeeInfo {
            guard let data = try? JSONEncoder().encode(AudioStatus(sessionId: currentAttendeeInfo.externalUserId, muted: true)) else { return }
            self.emitter.emit(eventName: .audioStatus, data: data)
        }
    }

    func attendeesDidUnmute(attendeeInfo: [AttendeeInfo]) {
        for currentAttendeeInfo in attendeeInfo {
            guard let data = try? JSONEncoder().encode(AudioStatus(sessionId: currentAttendeeInfo.externalUserId, muted: false)) else { return }
            self.emitter.emit(eventName: .audioStatus, data: data)
        }
    }

    init(emitter: WebViewEmitter, myAttendeeId: String) {
        self.emitter = emitter
        self.myAttendeeId = myAttendeeId
    }
}
