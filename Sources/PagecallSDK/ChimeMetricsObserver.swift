//
//  ChimeMetricsObserver.swift
//
//
//  Created by 록셉 on 2022/10/21.
//

import AmazonChimeSDK
import Foundation

enum StatKind: String, Codable {
    case audioPacketsSentLossPercent, audioPacketsReceivedLossPercent
}

struct MediaStat: Codable {
    let event: String
    let key: StatKind
    let value: Int
}

class ChimeMetricsObserver: MetricsObserver {
    let emitter: WebViewEmitter

    func sendStat(kind: StatKind, value: Int) {
        guard let data = try? JSONEncoder().encode(MediaStat(event: "audio", key: kind, value: value)) else { return }
        emitter.emit(eventName: .mediaStat, data: data)
    }

    func metricsDidReceive(metrics: [AnyHashable: Any]) {
        if let metric = metrics[ObservableMetric.audioReceivePacketLossPercent] as? Int {
            sendStat(kind: .audioPacketsReceivedLossPercent, value: metric)
        }
        if let metric = metrics[ObservableMetric.audioSendPacketLossPercent] as? Int {
            sendStat(kind: .audioPacketsSentLossPercent, value: metric)
        }
    }

    init(emitter: WebViewEmitter) {
        self.emitter = emitter
    }
}
