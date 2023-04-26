//
//  MiController.swift
//  
//
//  Created by Jaeseong Seo on 2023/03/16.
//

import Mediasoup
import WebRTC

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

class MiController: MediaController, SendTransportDelegate, ReceiveTransportDelegate {
    func onProduce(transport: Transport, kind: MediaKind, rtpParameters: String, appData: String, callback: @escaping (String?) -> Void) {
        if let parsedRtpParams = rtpParameters.jsonObject(), let parsedAppData = appData.jsonObject() {
            emitter.request(eventName: .produce, json: [
                "kind": kind == .video ? "video" : "audio",
                "rtpParameters": parsedRtpParams,
                "appData": parsedAppData
            ]) { error, producerId in
                if let producerId = producerId {
                    callback(producerId)
                } else {
                    print("[MiController] Failed to produce: \(error?.localizedDescription ?? "missing error message")")
                    callback(nil)
                }
            }
        } else {
            print("[MiController] Failed to parse")
            callback(nil)
        }
    }

    func onProduceData(transport: Transport, sctpParameters: String, label: String, protocol dataProtocol: String, appData: String, callback: @escaping (String?) -> Void) {
        print("[MiController] onProduceData: noop")
    }

    func onConnect(transport: Transport, dtlsParameters: String) {
        guard let data = dtlsParameters.data(using: .utf8), let parsedDtlsParameters = try? JSONSerialization.jsonObject(with: data) else {
            emitter.error(name: "UnknownTransport", message: "Failed to parse dtlsParameters")
            return
        }
        if transport.id == sendTransport.id {
            emitter.emit(eventName: .connectTransport, json: ["dtlsParameters": parsedDtlsParameters, "type": "send"])
        } else if transport.id == recvTransport.id {
            emitter.emit(eventName: .connectTransport, json: ["dtlsParameters": parsedDtlsParameters, "type": "recv"])
        } else {
            emitter.error(name: "UnknownTransport", message: "Transport type is unknown (id: \(transport.id))")
        }
    }

    func onConnectionStateChange(transport: Transport, connectionState: TransportConnectionState) {
        switch connectionState {
        case .new:
            print("transport new")
        case .checking:
            print("transport checking")
        case .connected:
            print("transport connected")
        case .completed:
            print("transport completed")
        case .failed:
            emitter.error(name: "ConnectionError", message: "Connection failed")
        case .disconnected:
            emitter.error(name: "ConnectionError", message: "Disconnected")
        case .closed:
            emitter.error(name: "ConnectionError", message: "Connection closed")
        @unknown default:
            print("unknown case: \(connectionState)")
        }
    }

    private let device = Device()
    private let sendTransport: SendTransport
    private let recvTransport: ReceiveTransport
    private let factory = RTCPeerConnectionFactory()
    private var producer: Producer?
    private var consumers = [Consumer]()
    let emitter: WebViewEmitter

    init(emitter: WebViewEmitter, initialPayload: MiInitialPayload) throws {
        self.emitter = emitter

        try device.load(with: initialPayload.rtpCapabilities)
        sendTransport = try device.createSendTransport(
            id: initialPayload.send.id,
            iceParameters: initialPayload.send.iceParameters,
            iceCandidates: initialPayload.send.iceCandidates,
            dtlsParameters: initialPayload.send.dtlsParameters,
            sctpParameters: initialPayload.send.sctpParameters,
            appData: nil
        )
        recvTransport = try device.createReceiveTransport(
            id: initialPayload.recv.id,
            iceParameters: initialPayload.recv.iceParameters,
            iceCandidates: initialPayload.recv.iceCandidates,
            dtlsParameters: initialPayload.recv.dtlsParameters,
            sctpParameters: initialPayload.recv.sctpParameters,
            appData: nil
        )

        sendTransport.delegate = self
        recvTransport.delegate = self
    }

    func consume(data: Data, callback: (Error?) -> Void) {
        guard let payload = String(data: data, encoding: .utf8)?.jsonObject() as? [String: Any],
              let consumerId = payload["id"] as? String,
              let producerId = payload["producerId"] as? String,
              let kind = payload["kind"] as? String,
              let rawRtpParameters = payload["rtpParameters"],
              let rtpParameters = String.from(jsonObject: rawRtpParameters) else {
            callback(PagecallError(message: "Invalid payload"))
            return
        }
        let appData = payload["appData"] as? String
        do {
            let kind = kind == "video" ? MediaKind.video : MediaKind.audio
            let consumer = try recvTransport.consume(
                consumerId: consumerId,
                producerId: producerId,
                kind: kind,
                rtpParameters: rtpParameters,
                appData: appData
            )
            consumers.append(consumer)
            callback(nil)
        } catch {
            callback(error)
        }
    }

    func start(callback: @escaping (Error?) -> Void) {
        let audioSource = factory.audioSource(with: RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil))
        let audioTrack = factory.audioTrack(with: audioSource, trackId: "audio0")

        DispatchQueue.global(qos: .userInitiated).async {
            self.producer?.close()
            do {
                self.producer = try self.sendTransport.createProducer(for: audioTrack, encodings: nil, codecOptions: nil, appData: nil)
                callback(nil)
            } catch {
                print("Start error", error.localizedDescription)
                callback(error)
            }
        }
    }

    func pauseAudio() -> Bool {
        if let producer = producer {
            producer.pause()
            return true
        }
        return false
    }

    func resumeAudio() -> Bool {
        if let producer = producer {
            producer.resume()
            return true
        }
        return false
    }

    func dispose() {
        sendTransport.close()
        recvTransport.close()
    }

    private var volumeRecorder: VolumeRecorder?
    func getAudioVolume() -> Float {
        if let volumeRecorder = volumeRecorder {
            return volumeRecorder.requestAudioVolume()
        } else {
            let volumeRecorder = try! VolumeRecorder()
            volumeRecorder.highest = -40
            volumeRecorder.lowest = -70
            self.volumeRecorder = volumeRecorder
            return 0
        }
    }
    
    private var timer: Timer?
    func startVolumeScheduler() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(
            timeInterval: 0.5,
            target: self,
            selector: #selector(emitVolume),
            userInfo: nil,
            repeats: true
        )
    }
    
    func stopVolumeScheduler() {
        timer?.invalidate()
        timer = nil
    }
    
    @objc func emitVolume() {
        let volume = getAudioVolume()
        self.emitter.emit(eventName: .audioVolume, message: String(volume))
    }
}
