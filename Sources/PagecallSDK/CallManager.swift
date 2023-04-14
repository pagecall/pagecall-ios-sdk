import CallKit

class CallManager: NSObject, CXProviderDelegate {
    func providerDidReset(_ provider: CXProvider) {
        print("[CallManager] providerDidReset")
    }

    static let shared = CallManager()

    let provider: CXProvider
    let callController: CXCallController

    private override init() {
        let configuration = CXProviderConfiguration()
        configuration.supportedHandleTypes = [.generic]
        provider = CXProvider(configuration: configuration)
        callController = CXCallController()
        super.init()
        provider.setDelegate(self, queue: nil)
    }

    private var callId: UUID?

    func startCall(completion: @escaping (Error?) -> Void) {
        if let _ = callId {
            completion(PagecallError(message: "Call not ended"))
            return
        }
        let callId = UUID()
        self.callId = callId
        provider.reportOutgoingCall(with: callId, startedConnectingAt: Date())
        callController.requestTransaction(with: [CXStartCallAction(call: callId, handle: CXHandle(type: .generic, value: "Pagecall"))]) { error in
            if self.callId != callId {
                self.provider.reportCall(with: callId, endedAt: Date(), reason: .failed)
                completion(error ?? PagecallError(message: "startCall interrupted"))
                return
            }
            if let error = error {
                self.provider.reportCall(with: callId, endedAt: Date(), reason: .failed)
                completion(error)
                return
            }
            self.provider.reportOutgoingCall(with: callId, connectedAt: Date())
            completion(nil)
        }
    }

    func endCall(completion: @escaping (Error?) -> Void) {
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
}
