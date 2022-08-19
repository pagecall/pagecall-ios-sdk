//
//  ChimeMeetingSession.swift
//
//
//  Created by 록셉 on 2022/08/19.
//

import AmazonChimeSDK
import Foundation

class ChimeMeetingSession {
    let meetingSession: DefaultMeetingSession

    init(configuration: MeetingSessionConfiguration, logger: AmazonChimeSDK.Logger, emitter: WebViewEmitter) {
        let meetingSession = DefaultMeetingSession(configuration: configuration, logger: logger)
        self.meetingSession = meetingSession

        meetingSession.audioVideo.addRealtimeObserver(observer: ChimeRealtimeObserver(emitter: emitter, myAttendeeId: meetingSession.configuration.credentials.attendeeId))

        do { try meetingSession.audioVideo.start()
            print("succeed")
        } catch {
            print(error)
        }
    }

    func pauseAudio() -> Bool {
        return meetingSession.audioVideo.realtimeLocalMute()
    }

    func resumeAudio() -> Bool {
        return meetingSession.audioVideo.realtimeLocalMute()
    }

    func setAudioDevice(label: String) {
        let audioDevices = meetingSession.audioVideo.listAudioDevices()

        let audioDevice = audioDevices.first { mediaDevice in mediaDevice.label == label }

        guard let audioDevice = audioDevice else {
            print("failed to find mediaDevice with label")
            return
        }

        meetingSession.audioVideo.chooseAudioDevice(mediaDevice: audioDevice)
    }

    func getAudioDevices() -> [MediaDevice] {
        return meetingSession.audioVideo.listAudioDevices()
    }
}
