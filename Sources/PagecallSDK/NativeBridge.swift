import WebKit
import AVFoundation

struct Stat: Encodable {
    var roundTripTime: Double
    var packetsLost: Int
}

enum BridgeEvent: String, Codable {
    case audioDevice, audioDevices, audioVolume, audioStatus, audioSessionRouteChanged, audioSessionInterrupted, mediaStat, audioEnded, videoEnded, screenshareEnded, connected, disconnected, log, error
    case connectTransport
}

enum BridgeRequest: String, Codable {
    case produce
}

enum BridgeAction: String, Codable {
    // 항상 유효한 요청
    case initialize, getPermissions, requestPermission, pauseAudio, resumeAudio, getAudioDevices, requestAudioVolume, getMediaStats
    case response
    // 컨트롤러 생성 후 유효한 요청
    case start, setAudioDevice, consume, dispose
}

func parseMediaStats(jsonString: String) -> Result<Stat, Error> {
    guard let jsonData = jsonString.data(using: .utf8),
          let parsedData = try? JSONSerialization.jsonObject(with: jsonData),
          let array = parsedData as? [[String: Any]] else {
        return .failure(PagecallError.other(message: "Failed to parse MI mediaStats"))
    }

    let filteredArray = array.filter { $0["type"] as? String == "remote-inbound-rtp" }
    guard let firstItem = filteredArray.first,
          let roundTripTime = firstItem["roundTripTime"] as? Double,
          let packetsLost = firstItem["packetsLost"] as? Int else {
        return .failure(PagecallError.other(message: "Required data missing"))
    }

    return .success(Stat(roundTripTime: roundTripTime * 1000.0, packetsLost: packetsLost))
}

class NativeBridge: Equatable {
    static func == (lhs: NativeBridge, rhs: NativeBridge) -> Bool {
        return lhs.id == rhs.id
    }

    private let webview: PagecallWebView
    private let emitter: WebViewEmitter

    private var mediaController: MediaController? {
        didSet {
            AudioSessionManager.shared.stopHandlingInterruption()

            if let mediaController = mediaController {
                synchronizePauseState()
                if let _ = mediaController as? ChimeController {
                    // Chime에서는 videoChat일 경우 소리가 작게 송출된다.
                    AudioSessionManager.shared.desiredMode = .default
                } else {
                    // MI에서는 default일 경우 에어팟 연결이 해제된다.
                    AudioSessionManager.shared.desiredMode = .videoChat
                }
                AudioSessionManager.shared.emitter = emitter
                AudioSessionManager.shared.startHandlingInterruption()
            }
        }
    }

    var isAudioPaused = false {
        didSet {
            synchronizePauseState()
        }
    }

    func synchronizePauseState() {
        guard let mediaController = mediaController else { return }
        let success = isAudioPaused ? mediaController.pauseAudio() : mediaController.resumeAudio()
        if success {
            emitter.log(name: "AudioStateChange", message: isAudioPaused ? "Paused" : "Resumed")
        } else {
            emitter.error(name: "AudioStateChangeError", message: isAudioPaused ? "Failed to pause" : "Failed to resume")
        }
    }

    static private var count = 0
    public let id: Int

    init(webview: PagecallWebView) {
        NativeBridge.count += 1
        id = NativeBridge.count
        self.webview = webview
        self.emitter = .init(webView: self.webview)
    }

    func messageHandler(message: String) {
        let data = message.data(using: .utf8)!
        guard let jsonArray = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            print("[NativeBridge] Failed to JSONSerialization")
            return
        }
        guard let action = jsonArray["action"] as? String, let bridgeAction = BridgeAction(rawValue: action), let requestId = jsonArray["requestId"] as? String?, let payload = jsonArray["payload"] as? String? else {
            return
        }

        print("[NativeBridge] Bridge Action: \(bridgeAction)")

        let respond: (PagecallError?, Data?) -> Void = { error, data in
            if let error = error {
                if let requestId = requestId {
                    self.emitter.response(requestId: requestId, errorMessage: error.message)
                } else {
                    self.emitter.error(error)
                }
            } else {
                if let requestId = requestId {
                    self.emitter.response(requestId: requestId, data: data)
                } else {
                    self.emitter.error(name: "RequestIdMissing", message: "\(bridgeAction) succeeded without requestId")
                }
            }
        }

        let payloadData = payload?.data(using: .utf8)

        switch bridgeAction {
        case .initialize:
            guard let payloadData = payload?.data(using: .utf8) else {
                respond(PagecallError.other(message: "Missing payload"), nil)
                return
            }
            struct MiPayload: Codable {
                let plugin: String
            }
            if let _ = self.mediaController {
                respond(PagecallError.other(message: "Must be disposed first"), nil)
                return
            }
            if let meetingSessionConfiguration = JoinRequestService.getMeetingSessionConfiguration(data: payloadData) {
                self.mediaController = ChimeController(emitter: self.emitter, configuration: meetingSessionConfiguration)
                respond(nil, nil)
            } else if let initialPayload = try? JSONDecoder().decode(MiInitialPayload.self, from: payloadData) {
                do {
                    let miController = try MiController(emitter: self.emitter, initialPayload: initialPayload)
                    self.mediaController = miController
                    respond(nil, nil)
                } catch {
                    print("[NativeBridge] error creating miController", error)
                    respond(PagecallError.other(message: error.localizedDescription), nil)
                }
            }

        case .getPermissions:
            guard let payloadData = payloadData, let mediaType = try? JSONDecoder().decode(MediaConstraints.self, from: payloadData) else {
                respond(PagecallError.other(message: "Missing or invalid payload"), nil)
                return
            }

            if let data = try? JSONEncoder().encode(
                MediaConstraints(
                    audio: mediaType.audio == true ? DeviceManager.getAuthorizationStatusAsBool(for: .audio) : nil,
                    video: mediaType.video == true ? DeviceManager.getAuthorizationStatusAsBool(for: .video) : nil
                )
            ) {
                respond(nil, data)
            } else {
                respond(PagecallError.other(message: "Failed to getPermissions"), nil)
            }
        case .getMediaStats:
            if let miController = mediaController as? MiController {
                let jsonString = miController.getMediaStats()
                switch parseMediaStats(jsonString: jsonString) {
                    case .success(let stat):
                        respond(nil, try? JSONEncoder().encode(stat))
                    case .failure(let error):
                        respond(PagecallError.other(message: error.localizedDescription), nil)
                }
            } else {
                respond(PagecallError.other(message: "Not supported in Chime yet"), nil)
            }
        case .requestPermission:
            guard let payloadData = payloadData, let mediaType = try? JSONDecoder().decode(MediaType.self, from: payloadData) else {
                respond(PagecallError.other(message: "Missing or invalid payload"), nil)
                return
            }
            let respondBool: (Bool) -> Void = { result in respond(nil, try? JSONEncoder().encode(result)) }
            switch mediaType.mediaType {
            case "audio":
                DeviceManager.requestAccess(for: .audio, callback: respondBool)
            case "video":
                DeviceManager.requestAccess(for: .video, callback: respondBool)
            default:
                respond(PagecallError.other(message: "Unknown mediaType: \(mediaType.mediaType)"), nil)
            }
        case .getAudioDevices:
            let deviceList: [MediaDeviceInfo] = {
                if let chimeController = mediaController as? ChimeController {
                    return chimeController.getAudioDevices()
                } else {
                    return [MediaDeviceInfo.audioDefault]
                }
            }()
            do {
                let data = try JSONEncoder().encode(deviceList)
                respond(nil, data)
            } catch {
                print("[NativeBridge] error encoding result of getAudioDevices", error)
                respond(PagecallError.other(message: error.localizedDescription), nil)
            }
        case .requestAudioVolume:
            let respondVolume: (Float) -> Void = { volume in
                if let volumeData = try? JSONEncoder().encode(volume) {
                    respond(nil, volumeData)
                } else {
                    respond(PagecallError.other(message: "Failed to encode volume"), nil)
                }
            }
            if let mediaController = mediaController {
                respondVolume(mediaController.getAudioVolume())
            } else {
                respondVolume(0)
            }
        case .pauseAudio:
            isAudioPaused = true
            respond(nil, nil)
        case .resumeAudio:
            isAudioPaused = false
            respond(nil, nil)
        case .response:
            struct ResponsePayload: Codable {
                let eventId: String
                let error: String?
                let result: String?
            }
            if let payloadData = payloadData, let responsePayload = try? JSONDecoder().decode(ResponsePayload.self, from: payloadData) {
                emitter.resolve(eventId: responsePayload.eventId, error: responsePayload.error, result: responsePayload.result)
            } else {
                print("[NativeBridge] Invalid response data")
            }
        case .start:
            guard let mediaController = mediaController else {
                respond(PagecallError.other(message: "Missing mediaController, initialize first"), nil)
                return
            }
            mediaController.start { (error: Error?) in
                self.synchronizePauseState()
                if let error = error {
                    print("[NativeBridge] Failed to start controller", error)
                    respond(PagecallError.other(message: error.localizedDescription), nil)
                } else {
                    respond(nil, nil)
                }
            }
        case .dispose:
            self.disconnect()
            respond(nil, nil)
        case .setAudioDevice:
            guard let mediaController = mediaController else {
                respond(PagecallError.other(message: "Missing mediaController, initialize first"), nil)
                return
            }
            struct DeviceId: Codable {
                var deviceId: String
            }
            guard let payloadData = payloadData, let deviceId = try? JSONDecoder().decode(DeviceId.self, from: payloadData) else {
                respond(PagecallError.other(message: "Invalid payload"), nil)
                return
            }

            guard let chimeController = mediaController as? ChimeController else {
                // No op for miController
                return
            }
            chimeController.setAudioDevice(deviceId: deviceId.deviceId) { (error: Error?) in
                if let error = error {
                    print("[NativeBridge] Failed to setAudioDevice", error)
                    respond(PagecallError.other(message: error.localizedDescription), nil)
                } else {
                    respond(nil, nil)
                }
            }
        case .consume:
            guard let mediaController = mediaController else {
                respond(PagecallError.other(message: "Missing mediaController, initialize first"), nil)
                return
            }
            if let miController = mediaController as? MiController {
                if let payloadData = payloadData {
                    miController.consume(data: payloadData) { error in
                        if let error = error {
                            print("[NativeBridge] Failed to consume", error)
                            respond(PagecallError.other(message: error.localizedDescription), nil)
                        } else {
                            respond(nil, nil)
                        }
                    }
                } else {
                    respond(PagecallError.other(message: "Invalid payload"), nil)
                }
            } else {
                respond(PagecallError.other(message: "consume is only effective for MI"), nil)
            }
        }
    }

    public func disconnect() {
        mediaController?.dispose()
        mediaController = nil
    }

    deinit {
        disconnect()
    }
}

struct MediaConstraints: Codable {
    var audio: Bool?
    var video: Bool?
}

struct MediaType: Codable {
    var mediaType: String
}
