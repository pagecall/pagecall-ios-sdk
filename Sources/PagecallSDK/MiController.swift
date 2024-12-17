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
    let iceServers: String?
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
                    if let error = error {
                        self.emitter.error(error)
                    } else {
                        self.emitter.error(name: "ProduceError", message: "missing error message")
                    }
                    callback(nil)
                }
            }
        } else {
            self.emitter.error(name: "ProduceError", message: "Failed to parse")
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
            emitter.log(name: "ConnectionStateChange", message: "new")
        case .checking:
            emitter.log(name: "ConnectionStateChange", message: "checking")
        case .connected:
            emitter.emit(eventName: .connected)
        case .completed:
            emitter.log(name: "ConnectionStateChange", message: "completed")
        case .failed:
            emitter.error(name: "ConnectionError", message: "Connection failed")
        case .disconnected:
            emitter.emit(eventName: .disconnected)
        case .closed:
            emitter.error(name: "ConnectionError", message: "Connection closed")
        @unknown default:
            emitter.error(name: "ConnectionError", message: "unknown case: \(connectionState)")
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
            iceServers: initialPayload.send.iceServers,
            appData: nil
        )
        recvTransport = try device.createReceiveTransport(
            id: initialPayload.recv.id,
            iceParameters: initialPayload.recv.iceParameters,
            iceCandidates: initialPayload.recv.iceCandidates,
            dtlsParameters: initialPayload.recv.dtlsParameters,
            sctpParameters: initialPayload.recv.sctpParameters,
            iceServers: initialPayload.send.iceServers,
            appData: nil
        )

        sendTransport.delegate = self
        recvTransport.delegate = self
    }
    func getMediaStats() -> String {
        return sendTransport.stats
    }

    func consume(data: Data, callback: (Error?) -> Void) {
        guard let payload = String(data: data, encoding: .utf8)?.jsonObject() as? [String: Any],
              let consumerId = payload["id"] as? String,
              let producerId = payload["producerId"] as? String,
              let kind = payload["kind"] as? String,
              let rawRtpParameters = payload["rtpParameters"],
              let rtpParameters = String.from(jsonObject: rawRtpParameters) else {
            callback(PagecallError.other(message: "Invalid payload"))
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
                self.producer = try self.sendTransport.createProducer(for: audioTrack, encodings: nil, codecOptions: nil, codec: nil, appData: nil)
                self.startVolumeScheduler()
                callback(nil)
            } catch {
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
        self.stopVolumeScheduler()
    }
    deinit {
        self.dispose()
    }
    private var volumeRecorder: VolumeRecorder?

    private func initializeVolumeRecorder() {
        self.volumeRecorder?.stop()
        do {
            let volumeRecorder = try VolumeRecorder(emitter: emitter)
            volumeRecorder.highest = -10
            volumeRecorder.lowest = -50
            self.volumeRecorder = volumeRecorder
        } catch {
            self.emitter.error(error)
        }
    }

    func getAudioVolume() -> Float {
        if let volumeRecorder = volumeRecorder {
            do {
                let volume = try volumeRecorder.requestAudioVolume()
                return volume
            } catch let error as PagecallError {
                switch error {
                case .audioRecorderBroken:
                    initializeVolumeRecorder()
                case .audioRecorderPowerOutOfRange: break
                    // do nothing yet
                case .other: break
                }
                self.emitter.error(error)
                return 0
            } catch {
                self.emitter.error(PagecallError.other(message: "Unexpected VolumeRecorder error"))
                return 0
            }
        } else {
            initializeVolumeRecorder()
            return 0
        }
    }

    private var timer: Timer?
    private func startVolumeScheduler() {
        DispatchQueue.main.async {
            self.timer?.invalidate()
            self.timer = Timer.scheduledTimer(
                timeInterval: 0.5,
                target: self,
                selector: #selector(self.emitVolume),
                userInfo: nil,
                repeats: true
            )
        }
    }

    private func stopVolumeScheduler() {
        timer?.invalidate()
        timer = nil
    }

    @objc func emitVolume() {
        let volume = getAudioVolume()
        self.emitter.emit(eventName: .audioVolume, message: String(volume))
    }
}
