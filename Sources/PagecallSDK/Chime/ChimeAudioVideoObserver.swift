//
//  ChimeAudioVideoObserver.swift
//
//
//  Created by 록셉 on 2022/08/24.
//

import AmazonChimeSDK
import Foundation

class ChimeAudioVideoObserver: AudioVideoObserver {
    let emitter: WebViewEmitter

    func audioSessionDidStartConnecting(reconnecting: Bool) {}
    func audioSessionDidStart(reconnecting: Bool) {
        print("connect")
        self.emitter.emit(eventName: .connected)
    }

    func audioSessionDidDrop() {}

    func audioSessionDidStopWithStatus(sessionStatus: MeetingSessionStatus) {
        print("disconnect \(sessionStatus)")
        self.emitter.emit(eventName: .disconnected)
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
