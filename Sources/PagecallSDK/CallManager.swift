import CallKit
import AVFoundation
import Combine

public class CallManager: NSObject, CXProviderDelegate {
    static public let shared = CallManager()
    static var disabled = false

    private let provider: CXProvider
    private let callController: CXCallController
    public var delegate: CXProviderDelegate?
    public var callDelegate: PagecallCallDelegate?

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
            .filter({ callState in callState.shouldBeInCall != callState.isInCall && callState.error == nil })
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

        NotificationCenter.default.addObserver(self, selector: #selector(handleBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    func averagePower() -> Float? {
        return self.audioSessionManager?.averagePower()
    }

    @objc private func handleBecomeActive(notification: Notification) {
        print("[CallManager] becomeActive")
        let current = callState.value
        if current.shouldBeInCall == current.isInCall || current.error == nil { return }
        // Trigger retry
        callState.send(.init(shouldBeInCall: current.shouldBeInCall, isInCall: current.isInCall, error: nil))
    }

    static weak var emitter: WebViewEmitter?

    func getEmitter() -> WebViewEmitter? {
        return CallManager.emitter
    }

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

    private var audioSessionManager: AudioSessionManager?

    public func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        print("[CallManager] providerPerformStartCall", action)
        CallManager.emitter?.log(name: "CallManager", message: "performStartCall")

        if let _ = self.callId {
            print("[CallManager] providerPerformStartCall: unexpected callId")
        }
        self.callId = action.callUUID

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
        CallManager.emitter?.log(name: "CallManager", message: "performEndCall")

        if self.callId != action.callUUID {
            print("[CallManager] providerPerformStartCall: unexpected callId")
        }
        self.callId = nil

        action.fulfill()
        self.delegate?.provider?(provider, perform: action)

        let current = callState.value
        callState.send(
            .init(shouldBeInCall: current.shouldBeInCall, isInCall: false, error: nil)
        )
    }

    public func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        print("[CallManager] providerPerformSetHeldCall", action)
        CallManager.emitter?.log(name: "CallManager", message: "performSetHeldCall")
        action.fulfill()
        self.delegate?.provider?(provider, perform: action)
    }

    public func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        print("[CallManager] providerPerformSetMutedCall", action)
        CallManager.emitter?.log(name: "CallManager", message: "performSetMutedCall")
        action.fulfill()
        self.delegate?.provider?(provider, perform: action)
    }

    public func provider(_ provider: CXProvider, perform action: CXSetGroupCallAction) {
        print("[CallManager] providerPerformSetGroupCall", action)
        CallManager.emitter?.log(name: "CallManager", message: "performSetGroupCall")
        action.fulfill()
        self.delegate?.provider?(provider, perform: action)
    }

    public func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        print("[CallManager] providerTimedOutPerforming", action)
        CallManager.emitter?.log(name: "CallManager", message: "timedOutPerforming: \(action.description)")
        self.delegate?.provider?(provider, timedOutPerforming: action)
    }

    public func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        print("[CallManager] providerDidActivate")
        CallManager.emitter?.log(name: "CallManager", message: "didActivateAudioSession")

        if audioSessionManager == nil {
            audioSessionManager = .init(self)
        }

        self.delegate?.provider?(provider, didActivate: audioSession)
    }

    public func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        print("[CallManager] providerDidDeactivate")
        CallManager.emitter?.log(name: "CallManager", message: "didDeactivateAudioSession")
        CallManager.emitter?.error(name: "CallError", message: "audioSession deactivated")

        audioSessionManager?.dispose()
        audioSessionManager = nil

        self.delegate?.provider?(provider, didDeactivate: audioSession)
        self.callDelegate?.didDeactivate()
    }
}

struct CallState {
    let shouldBeInCall: Bool
    let isInCall: Bool
    let error: Error?
}

public protocol PagecallCallDelegate: AnyObject {
    func didDeactivate()
}
