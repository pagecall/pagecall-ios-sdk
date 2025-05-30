import CallKit
import AVFoundation

public class CallManager: NSObject, CXProviderDelegate {
    static public let shared = CallManager()
    static var disabled = false

    let provider: CXProvider
    let callController: CXCallController
    public var delegate: CXProviderDelegate?

    private override init() {
        print("[CallManager] init")
        let configuration = CXProviderConfiguration()
        configuration.supportedHandleTypes = [.generic]
        provider = CXProvider(configuration: configuration)
        callController = CXCallController()
        super.init()
        provider.setDelegate(self, queue: nil)
    }

    private var callId: UUID?

    static weak var emitter: WebViewEmitter?

    func startCall(completion: @escaping (Error?) -> Void) {
        PagecallLogger.shared.addBreadcrumb(message: "startCall")

        if let _ = callId {
            completion(PagecallError.other(message: "Call not ended"))
            return
        }

        if CallManager.disabled {
            PagecallLogger.shared.addBreadcrumb(message: "startCall skipped")
            completion(nil)
            return
        }

        let callId = UUID()
        self.callId = callId
        provider.reportOutgoingCall(with: callId, startedConnectingAt: Date())
        callController.requestTransaction(with: [CXStartCallAction(call: callId, handle: CXHandle(type: .generic, value: "Pagecall"))]) { error in
            if self.callId != callId {
                self.provider.reportCall(with: callId, endedAt: Date(), reason: .failed)
                completion(error ?? PagecallError.other(message: "startCall interrupted"))
                return
            }
            if let error = error {
                self.provider.reportCall(with: callId, endedAt: Date(), reason: .failed)
                self.callId = nil
                completion(error)
                return
            }
            self.provider.reportOutgoingCall(with: callId, connectedAt: Date())

            completion(nil)
        }
    }

    func endCall(completion: @escaping (Error?) -> Void) {
        PagecallLogger.shared.addBreadcrumb(message: "endCall")

        guard let callId = callId else {
            completion(nil)
            return
        }
        self.callId = nil
        callController.requestTransaction(with: [CXEndCallAction(call: callId)]) { error in
            if let error = error {
                self.provider.reportCall(with: callId, endedAt: Date(), reason: .failed)
                completion(error)
            } else {
                self.provider.reportCall(with: callId, endedAt: Date(), reason: .remoteEnded)
                completion(nil)
            }
        }
    }

    // MARK: CXProviderDelegate
    public func providerDidReset(_ provider: CXProvider) {
        print("[CallManager] providerDidReset")
        self.delegate?.providerDidReset(provider)
    }

    public func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        print("[CallManager] providerPerformStartCall", action)

        // MI에서는 default일 경우 에어팟 연결이 해제된다.
        AudioSessionManager.shared().emitter = CallManager.emitter
        AudioSessionManager.shared().desiredMode = .videoChat

        action.fulfill()
        self.delegate?.provider?(provider, perform: action)
    }

    public func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        print("[CallManager] providerPerformAnswerCall", action)
        action.fulfill()
        self.delegate?.provider?(provider, perform: action)
    }

    public func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        print("[CallManager] providerPerformEndCall", action)

        AudioSessionManager.clear()

        action.fulfill()
        self.delegate?.provider?(provider, perform: action)
    }

    public func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        print("[CallManager] providerPerformSetHeldCall", action)
        action.fulfill()
        self.delegate?.provider?(provider, perform: action)
    }

    public func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        print("[CallManager] providerPerformSetMutedCall", action)
        action.fulfill()
        self.delegate?.provider?(provider, perform: action)
    }

    public func provider(_ provider: CXProvider, perform action: CXSetGroupCallAction) {
        print("[CallManager] providerPerformSetGroupCall", action)
        action.fulfill()
        self.delegate?.provider?(provider, perform: action)
    }

    public func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        print("[CallManager] providerTimedOutPerforming", action)
        self.delegate?.provider?(provider, timedOutPerforming: action)
    }

    public func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        print("[CallManager] providerDidActivate")
        /**
         If there is an existing `VolumeRecorder` at this point, it may be stuck in a broken state and keep reporting a power of -120.
         Destroy the instance to allow creating a new one.
         */
        VolumeRecorder.clear()
        self.delegate?.provider?(provider, didActivate: audioSession)
    }

    public func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        print("[CallManager] providerDidDeactivate")
        self.delegate?.provider?(provider, didDeactivate: audioSession)
    }
}
