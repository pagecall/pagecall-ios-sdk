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
        meetingSession.audioVideo.addAudioVideoObserver(observer: ChimeAudioVideoObserver(emitter: emitter))
    }

    func start(callback: (Error?) -> Void) {
        do {
            try meetingSession.audioVideo.start()
            callback(nil)
        } catch {
            print(error)
            callback(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to start audioVideo"]))
        }
    }

    func stop() {
        meetingSession.audioVideo.stop()
    }

    func pauseAudio() -> Bool {
        return meetingSession.audioVideo.realtimeLocalMute()
    }

    func resumeAudio() -> Bool {
        return meetingSession.audioVideo.realtimeLocalUnmute()
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

    func dispose() {
        meetingSession.audioVideo.stop()
    }
}
