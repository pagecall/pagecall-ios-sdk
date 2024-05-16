//
//  MiController.swift
//  
//
//  Created by Jaeseong Seo on 2023/03/16.
//

struct TransportPayload: Codable {
    let id: String
    let iceParameters: String
    let iceCandidates: String
    let dtlsParameters: String
    let sctpParameters: String?
}

struct MiInitialPayload: Codable {
    let rtpCapabilities: String
    let send: TransportPayload
    let recv: TransportPayload
}

enum ConsumeKind: Codable {
    case video, audio
}

extension String {
    func jsonObject() -> Any? {
        if let data = self.data(using: .utf8), let object = try? JSONSerialization.jsonObject(with: data) {
            return object
        } else {
            return nil
        }
    }

    static func from(jsonObject: Any) -> String? {
        if let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject), let stringifiedJson = String(data: jsonData, encoding: .utf8) {
            return stringifiedJson
        } else {
            return nil
        }
    }
}

class MiController: MediaController {

    let emitter: WebViewEmitter

    init(emitter: WebViewEmitter, initialPayload: MiInitialPayload) throws {
        self.emitter = emitter
    }
    func getMediaStats() -> String {
        return String("")
    }

    func consume(data: Data, callback: (Error?) -> Void) {}

    func start(callback: @escaping (Error?) -> Void) {}

    func pauseAudio() -> Bool {
        return false
    }

    func resumeAudio() -> Bool {
        return false
    }

    func dispose() {}
    deinit {
        self.dispose()
    }
    private var volumeRecorder: VolumeRecorder?

    func getAudioVolume() -> Float {
        return 0
    }
}
