import CallKit
import AVFoundation
import Combine

public class CallManager: NSObject, CXProviderDelegate {
    static public let shared = CallManager()
    static var disabled = false

    let provider: CXProvider
    let callController: CXCallController
    public var delegate: CXProviderDelegate?

    private let callState = CurrentValueSubject<CallState, Never>(
        CallState(shouldBeInCall: false, isInCall: false, error: nil)
    )

    private var cancellables = Set<AnyCancellable>()

    private var callId: UUID?

    private override init() {
        print("[CallManager] init")
        let configuration = CXProviderConfiguration()
        configuration.supportedHandleTypes = [.generic]
        provider = CXProvider(configuration: configuration)
        callController = CXCallController()
        super.init()
        provider.setDelegate(self, queue: nil)

        callState
            .filter({ callState in callState.shouldBeInCall != callState.isInCall })
            .flatMap(maxPublishers: .max(1)) { callState -> AnyPublisher<CallState, Never> in
                let shouldBeInCall = callState.shouldBeInCall
            return Future<CallState, Never> { [weak self] promise in
                if let callId = self?.callId {
                    if shouldBeInCall {
                        promise(
                            .success(.init(shouldBeInCall: true, isInCall: true, error: nil))
                        )
                    } else {
                        // end the call
                        self?.callController.requestTransaction(with: [CXEndCallAction(call: callId)]) { error in
                            if let error = error {
                                self?.provider.reportCall(with: callId, endedAt: Date(), reason: .failed)
                                promise(
                                    .success(.init(shouldBeInCall: false, isInCall: false, error: error))
                                )
                            } else {
                                self?.provider.reportCall(with: callId, endedAt: Date(), reason: .remoteEnded)
                                promise(
                                    .success(.init(shouldBeInCall: false, isInCall: false, error: nil))
                                )
                            }
                        }
                    }
                } else {
                    if shouldBeInCall {
                        // start a new call
                        let newCallId = UUID()
                        self?.provider.reportOutgoingCall(with: newCallId, startedConnectingAt: Date())
                        self?.callController.requestTransaction(with: [CXStartCallAction(call: newCallId, handle: CXHandle(type: .generic, value: "Pagecall"))]) { error in
                            if let error = error {
                                self?.provider.reportCall(with: newCallId, endedAt: Date(), reason: .failed)
                                promise(
                                    .success(.init(shouldBeInCall: true, isInCall: false, error: error))
                                )
                                return
                            }
                            self?.provider.reportOutgoingCall(with: newCallId, connectedAt: Date())
                            promise(
                                .success(.init(shouldBeInCall: true, isInCall: true, error: nil))
                            )
                        }
                    } else {
                        promise(
                            .success(.init(shouldBeInCall: false, isInCall: false, error: nil))
                        )
                    }
                }
            }
            .eraseToAnyPublisher()
          }
          .sink { [weak self] value in
            self?.callState.send(value)
          }
          .store(in: &cancellables)
    }

    static weak var emitter: WebViewEmitter?

    func startCall(completion: @escaping (Error?) -> Void) {
        if CallManager.disabled {
            PagecallLogger.shared.addBreadcrumb(message: "startCall skipped")
            completion(nil)
            return
        }

        PagecallLogger.shared.addBreadcrumb(message: "startCall")

        let current = callState.value
        callState.send(.init(shouldBeInCall: true, isInCall: current.isInCall, error: nil))
        callState
            .filter { $0.shouldBeInCall && ($0.isInCall || $0.error != nil) }
            .first()
            .sink { state in completion(state.error) }
            .store(in: &cancellables)
    }

    func endCall(completion: @escaping (Error?) -> Void) {
        PagecallLogger.shared.addBreadcrumb(message: "endCall")

        let current = callState.value
        callState.send(.init(shouldBeInCall: false, isInCall: current.isInCall, error: nil))
        callState
            .filter { !$0.shouldBeInCall && (!$0.isInCall || $0.error != nil) }
            .first()
            .sink { state in completion(state.error) }
            .store(in: &cancellables)
    }

    // MARK: CXProviderDelegate
    public func providerDidReset(_ provider: CXProvider) {
        print("[CallManager] providerDidReset")
        self.delegate?.providerDidReset(provider)
    }

    public func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        print("[CallManager] providerPerformStartCall", action)

        if let _ = self.callId {
            print("[CallManager] providerPerformStartCall: unexpected callId")
        }
        self.callId = action.callUUID

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

        if self.callId != action.callUUID {
            print("[CallManager] providerPerformStartCall: unexpected callId")
        }
        self.callId = nil

        AudioSessionManager.clear()

        action.fulfill()
        self.delegate?.provider?(provider, perform: action)

        let current = callState.value
        callState.send(
            .init(shouldBeInCall: current.shouldBeInCall, isInCall: false, error: nil)
        )
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

struct CallState {
    let shouldBeInCall: Bool
    let isInCall: Bool
    let error: Error?
}
