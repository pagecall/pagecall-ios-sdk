//
//  ChimeAudioVideoObserver.swift
//
//
//  Created by 록셉 on 2022/08/24.
//

import AmazonChimeSDK

class ChimeAudioVideoObserver: AudioVideoObserver {
    let emitter: WebViewEmitter

    func audioSessionDidStartConnecting(reconnecting: Bool) {}
    func audioSessionDidStart(reconnecting: Bool) {
        self.emitter.emit(eventName: .connected, json: ["reconnecting": reconnecting])
    }

    func audioSessionDidDrop() {}

    func audioSessionDidStopWithStatus(sessionStatus: MeetingSessionStatus) {
        self.emitter.emit(eventName: .disconnected, json: ["statusCode": sessionStatus.statusCode])
    }

    func audioSessionDidCancelReconnect() {}
    func connectionDidRecover() {}
    func connectionDidBecomePoor() {}
    func videoSessionDidStartConnecting() {}
    func videoSessionDidStartWithStatus(sessionStatus: MeetingSessionStatus) {}
    func videoSessionDidStopWithStatus(sessionStatus: MeetingSessionStatus) {}
    func remoteVideoSourcesDidBecomeAvailable(sources: [RemoteVideoSource]) {}
    func remoteVideoSourcesDidBecomeUnavailable(sources: [RemoteVideoSource]) {}

    init(emitter: WebViewEmitter) {
        self.emitter = emitter
    }
}
