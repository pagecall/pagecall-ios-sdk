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

    let realtimeObserver: ChimeRealtimeObserver
    let audioVideoObserver: ChimeAudioVideoObserver
    let metricsObserver: ChimeMetricsObserver
    let deviceChangeObserver: ChimeDeviceChangeObserver

    init(configuration: MeetingSessionConfiguration, logger: AmazonChimeSDK.Logger, emitter: WebViewEmitter) {
        let meetingSession = DefaultMeetingSession(configuration: configuration, logger: logger)
        self.meetingSession = meetingSession

        self.realtimeObserver = ChimeRealtimeObserver(emitter: emitter, myAttendeeId: meetingSession.configuration.credentials.attendeeId)
        self.audioVideoObserver = ChimeAudioVideoObserver(emitter: emitter)
        self.metricsObserver = ChimeMetricsObserver(emitter: emitter)
        self.deviceChangeObserver = ChimeDeviceChangeObserver(emitter: emitter, meetingSession: self.meetingSession)

        meetingSession.audioVideo.addRealtimeObserver(observer: realtimeObserver)
        meetingSession.audioVideo.addAudioVideoObserver(observer: audioVideoObserver)
        meetingSession.audioVideo.addMetricsObserver(observer: metricsObserver)
        meetingSession.audioVideo.addDeviceChangeObserver(observer: deviceChangeObserver)

    }

    func start(callback: (Error?) -> Void) {
        do {
            try meetingSession.audioVideo.start()

            _ = meetingSession.audioVideo.realtimeSetVoiceFocusEnabled(enabled: true)

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

        meetingSession.audioVideo.removeRealtimeObserver(observer: realtimeObserver)
        meetingSession.audioVideo.removeAudioVideoObserver(observer: audioVideoObserver)
        meetingSession.audioVideo.removeMetricsObserver(observer: metricsObserver)
        meetingSession.audioVideo.removeDeviceChangeObserver(observer: deviceChangeObserver)
    }
}
