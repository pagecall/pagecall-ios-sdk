//
//  ChimeController.swift
//
//
//  Created by 록셉 on 2022/07/27.
//

import AmazonChimeSDK
import AVFoundation

class ChimeLogger: Logger {
    private let consoleLogger = ConsoleLogger(name: "DefaultMeetingSession", level: LogLevel.INFO)
    private let emitter: WebViewEmitter

    init(emitter: WebViewEmitter) {
        self.emitter = emitter
    }

    func `default`(msg: String) {
        consoleLogger.default(msg: msg)
    }

    func debug(debugFunction: () -> String) {
        consoleLogger.debug(debugFunction: debugFunction)
    }

    func info(msg: String) {
        consoleLogger.info(msg: msg)
    }

    func fault(msg: String) {
        consoleLogger.fault(msg: msg)
        emitter.error(name: "ChimeFault", message: msg)
    }

    func error(msg: String) {
        consoleLogger.fault(msg: msg)
        emitter.error(name: "ChimeError", message: msg)
    }

    func setLogLevel(level: AmazonChimeSDK.LogLevel) {
        consoleLogger.setLogLevel(level: level)
    }

    func getLogLevel() -> AmazonChimeSDK.LogLevel {
        return consoleLogger.getLogLevel()
    }

}

class ChimeController: MediaController {
    let emitter: WebViewEmitter

    let meetingSession: DefaultMeetingSession

    let realtimeObserver: ChimeRealtimeObserver
    let audioVideoObserver: ChimeAudioVideoObserver
    let metricsObserver: ChimeMetricsObserver
    let deviceChangeObserver: ChimeDeviceChangeObserver

    init(emitter: WebViewEmitter, configuration: MeetingSessionConfiguration) {
        self.emitter = emitter

        meetingSession = DefaultMeetingSession(configuration: configuration, logger: ChimeLogger(emitter: emitter))

        realtimeObserver = ChimeRealtimeObserver(emitter: emitter, myAttendeeId: configuration.credentials.attendeeId)
        audioVideoObserver = ChimeAudioVideoObserver(emitter: emitter)
        metricsObserver = ChimeMetricsObserver(emitter: emitter)
        deviceChangeObserver = ChimeDeviceChangeObserver(emitter: emitter, meetingSession: self.meetingSession)

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
            callback(error)
        }
    }

    func pauseAudio() -> Bool {
        return meetingSession.audioVideo.realtimeLocalMute()
    }

    func resumeAudio() -> Bool {
        return meetingSession.audioVideo.realtimeLocalUnmute()
    }

    func setAudioDevice(deviceId: String, callback: (Error?) -> Void) {
        let audioDevices = meetingSession.audioVideo.listAudioDevices()

        let audioDevice = audioDevices.first { mediaDevice in mediaDevice.label == deviceId }

        guard let audioDevice = audioDevice else {
            callback(PagecallError(message: "Missing device with id: \(deviceId)"))
            return
        }

        meetingSession.audioVideo.chooseAudioDevice(mediaDevice: audioDevice)
        callback(nil)
    }

    func getAudioDevices() -> [MediaDeviceInfo] {
        return meetingSession.audioVideo.listAudioDevices().map(MediaDeviceInfo.init)
    }

    func dispose() {
        meetingSession.audioVideo.stop()

        meetingSession.audioVideo.removeRealtimeObserver(observer: realtimeObserver)
        meetingSession.audioVideo.removeAudioVideoObserver(observer: audioVideoObserver)
        meetingSession.audioVideo.removeMetricsObserver(observer: metricsObserver)
        meetingSession.audioVideo.removeDeviceChangeObserver(observer: deviceChangeObserver)
    }

    deinit {
        dispose()
    }
}
