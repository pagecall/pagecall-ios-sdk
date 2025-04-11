import WebKit
import AVFoundation

struct Stat: Encodable {
    var roundTripTime: Double
    var packetsLost: Int
}

enum BridgeEvent: String, Codable {
    case audioDevice, audioDevices, audioStatus, audioSessionRouteChanged, audioSessionInterrupted, mediaStat, audioEnded, videoEnded, screenshareEnded, connected, disconnected, log, error
    case connectTransport, penTouch
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

class NativeBridge: Equatable, ScriptDelegate {
    static func == (lhs: NativeBridge, rhs: NativeBridge) -> Bool {
        return lhs.id == rhs.id
    }

    private var mediaController: MediaController? {
        didSet {
            AudioSessionManager.shared.stopHandlingInterruption()

            if let _ = mediaController {
                synchronizePauseState()

                // MI에서는 default일 경우 에어팟 연결이 해제된다.
                AudioSessionManager.shared.desiredMode = .videoChat
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

    private let webview: PagecallWebView
    let frame: WKFrameInfo

    private let emitter = WebViewEmitter()

    init(webview: PagecallWebView, frame: WKFrameInfo) {
        NativeBridge.count += 1
        id = NativeBridge.count
        self.webview = webview
        self.frame = frame
        emitter.delegate = self
    }

    func emitPenTouch(points: [CGPoint], phase: TouchPhase) {
        let pointsData = points.map { point in
            ["x": point.x, "y": point.y]
        }
        emitter.emit(eventName: .penTouch, json: [
            "points": pointsData,
            "phase": phase.rawValue
        ])
    }

    func runScript(_ script: String) {
        runScript(script, completion: nil)
    }

    func runScript(_ script: String, completion: ((Result<Any, Error>) -> Void)?) {
        DispatchQueue.main.async {
            self.webview.evaluateJavaScript("""
(function userScript() {
\(script)
})()
""", in: self.frame, in: .page, completionHandler: { result in
                if let completion = completion {
                    completion(result)
                    return
                }
                switch result {
                case .success(let value as Any?):
                    if let value = value {
                        print("[PagecallWebView] Script result", value)
                    }
                case .failure(let error):
                    print("[PagecallWebView] runScript error", error.localizedDescription)
                    print("[PagecallWebView] original script", script)
                }
            })
        }
    }

    private var isCallStarted = false

    private var volumeRecorder: VolumeRecorder?

    func messageHandler(message: String) {
        let data = message.data(using: .utf8)!
        guard let jsonArray = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            print("[NativeBridge] Failed to JSONSerialization")
            return
        }
        guard let action = jsonArray["action"] as? String, let bridgeAction = BridgeAction(rawValue: action), let requestId = jsonArray["requestId"] as? String?, let payload = jsonArray["payload"] as? String? else {
            return
        }

        if bridgeAction != .requestAudioVolume { // requestAudioVolume gets called too frequently
            print("[NativeBridge] Bridge Action: \(bridgeAction)")
        }

        let respond: (Error?, Data?) -> Void = { error, data in
            if let error = error {
                let pagecallError = {
                    if let error = error as? PagecallError {
                        return error
                    } else {
                        return PagecallError.other(message: error.localizedDescription)
                    }
                }()
                if let requestId = requestId {
                    self.emitter.response(requestId: requestId, errorMessage: pagecallError.message)
                } else {
                    self.emitter.error(pagecallError)
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
            if let initialPayload = try? JSONDecoder().decode(MiInitialPayload.self, from: payloadData) {
                CallManager.shared.startCall(completion: { error in
                    if let error = error {
                        print("[NativeBridge] startCall failure")
                        self.emitter.error(name: "StartCallError", message: error.localizedDescription)
                        PagecallLogger.shared.capture(error: error)
                    } else {
                        print("[NativeBridge] startCall success")
                        self.isCallStarted = true
                    }
                    // Continue anyway
                    do {
                        let miController = try MiController(emitter: self.emitter, initialPayload: initialPayload)
                        self.mediaController = miController
                        respond(nil, nil)
                    } catch {
                        print("[NativeBridge] error creating miController", error)
                        respond(error, nil)
                    }
                })
            } else {
                respond(PagecallError.other(message: "Unexpected payload"), nil)
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
                        respond(error, nil)
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
                return [MediaDeviceInfo.audioDefault]
            }()
            do {
                let data = try JSONEncoder().encode(deviceList)
                respond(nil, data)
            } catch {
                print("[NativeBridge] error encoding result of getAudioDevices", error)
                respond(error, nil)
            }
        case .requestAudioVolume:
            let respondVolume: (Float) -> Void = { volume in
                if let volumeData = try? JSONEncoder().encode(volume) {
                    respond(nil, volumeData)
                } else {
                    respond(PagecallError.other(message: "Failed to encode volume"), nil)
                }
            }
            do {
                if let volumeRecorder = volumeRecorder {
                    respondVolume(try volumeRecorder.requestAudioVolume())
                } else {
                    let volumeRecorder = try VolumeRecorder()
                    self.volumeRecorder = volumeRecorder
                    respondVolume(try volumeRecorder.requestAudioVolume())
                }
            } catch {
                if let error = error as? PagecallError {
                    switch error {
                    case .audioRecorderBroken:
                        self.volumeRecorder?.stop()
                        self.volumeRecorder = nil
                        do {
                            let volumeRecorder = try VolumeRecorder()
                            self.volumeRecorder = volumeRecorder
                            respondVolume(try volumeRecorder.requestAudioVolume())
                        } catch {
                            respond(error, nil)
                            return
                        }
                    default:
                        break
                    }
                }
                respond(error, nil)
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
                    respond(error, nil)
                } else {
                    respond(nil, nil)
                }
            }
        case .dispose:
            self.disconnect()
            respond(nil, nil)
        case .setAudioDevice:
            // Deprecated
            respond(nil, nil)
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
                            respond(error, nil)
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
        volumeRecorder?.stop()
        volumeRecorder = nil

        mediaController?.dispose()
        mediaController = nil

        if isCallStarted {
            CallManager.shared.endCall { error in
                self.isCallStarted = false
                if let error = error {
                    print("[PagecallWebView] endCall failure")
                    self.emitter.error(name: "EndCallError", message: error.localizedDescription)
                    PagecallLogger.shared.capture(error: error)
                } else {
                    print("[PagecallWebView] endCall success")
                }
            }
        }
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
