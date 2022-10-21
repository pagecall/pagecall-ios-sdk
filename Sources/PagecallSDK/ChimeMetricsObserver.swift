//
//  ChimeMetricsObserver.swift
//
//
//  Created by 록셉 on 2022/10/21.
//

import AmazonChimeSDK
import Foundation

enum StatKind: String, Codable {
    case audioReceivePacketLossPercent, audioSendPacketLossPercent
}

struct MediaStat: Codable {
    let event: String
    let key: StatKind
    let value: Int
}

class ChimeMetricsObserver: MetricsObserver {
    let emitter: WebViewEmitter

    func metricsDidReceive(metrics: [AnyHashable: Any]) {
        if let metric = metrics[ObservableMetric.audioReceivePacketLossPercent] as? Int {
            guard let data = try? JSONEncoder().encode(MediaStat(event: "audio", key: .audioReceivePacketLossPercent, value: metric)) else { return }
            emitter.emit(eventName: .mediaStat, data: data)
        }
        if let metric = metrics[ObservableMetric.audioSendPacketLossPercent] as? Int {
            guard let data = try? JSONEncoder().encode(MediaStat(event: "audio", key: .audioSendPacketLossPercent, value: metric)) else { return }
            emitter.emit(eventName: .mediaStat, data: data)
        }
    }

    init(emitter: WebViewEmitter) {
        self.emitter = emitter
    }
}
