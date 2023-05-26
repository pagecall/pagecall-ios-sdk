import WebKit

public enum TerminationReason {
    case `internal`
    case other(String)
}

public protocol PagecallDelegate: AnyObject {
    func pagecallDidTerminate(_ view: PagecallWebView, reason: TerminationReason)
    func pagecallDidEncounter(_ view: PagecallWebView, error: Error)
    func pagecallDidLoad(_ view: PagecallWebView)
    func pagecallDidReceive(_ view: PagecallWebView, message: String)
    func pagecall(_ view: PagecallWebView, requestDownloadFor url: URL)
}

// Optional delegates
public extension PagecallDelegate {
    func pagecallDidEncounter(_ view: PagecallWebView, error: Error) {}
    func pagecallDidLoad(_ view: PagecallWebView) {}
    func pagecallDidReceive(_ view: PagecallWebView, message: String) {}
    func pagecall(_ view: PagecallWebView, requestDownloadFor url: URL) {}
}

public enum PagecallMode {
    case meet, replay

    func baseURLString() -> String {
        switch self {
        case .meet:
            return "https://app.pagecall.com/meet"
        case .replay:
            return "https://app.pagecall.com/replay"
        }
    }
}

extension WKWebView {
    func evaluateJavascriptWithLog(script: String) {
        evaluateJavascriptWithLog(script: script, completionHandler: nil)
    }

    func evaluateJavascriptWithLog(script: String, completionHandler: ((Any?, Error?) -> Void)?) {
        evaluateJavaScript("""
(function userScript() {
\(script)
})()
""") { result, error in
            if let error = error {
                print("[PagecallWebView] runScript error", error.localizedDescription)
                print("[PagecallWebView] original script", script)
            } else if let result = result {
                print("[PagecallWebView] Script result", result)
            }
            completionHandler?(result, error)
        }
    }
}

open class PagecallWebView: WKWebView {
    static let version = "0.0.12"

    var nativeBridge: NativeBridge?
    var controllerName = "pagecall"
    public weak var delegate: PagecallDelegate?

    public var isPenInteractionEnabled = false

    @available(*, unavailable)
    required public init?(coder: NSCoder) {
        fatalError("PagecallWebView cannot be instantiated from a storyboard")
    }

    convenience public init() {
        self.init(frame: .zero, configuration: .init())
    }

    var safariUserAgent: String = {
        let webkitVersion = "605.1.15"
        let systemVersion = UIDevice.current.systemVersion.replacingOccurrences(of: ".", with: "_")

        let systemFragment = UIDevice.current.userInterfaceIdiom == .phone ?
            "Mozilla/5.0 (iPhone; CPU iPhone OS \(systemVersion) like Mac OS X)"
            : "Mozilla/5.0 (Macintosh; Intel Mac OS X \(systemVersion))"
        let webkitFragment = "AppleWebKit/\(webkitVersion) (KHTML, like Gecko)"
        let versionFragment = "Version/\(systemVersion)"
        let browserFragment = "Safari/\(webkitVersion)"

        return [systemFragment, webkitFragment, versionFragment, browserFragment].joined(separator: " ")
    }()

    override public init(frame: CGRect, configuration: WKWebViewConfiguration) {
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.allowsInlineMediaPlayback = true
        configuration.suppressesIncrementalRendering = false
        configuration.applicationNameForUserAgent = "PagecallIos"
        configuration.allowsAirPlayForMediaPlayback = true
        configuration.defaultWebpagePreferences.preferredContentMode = .mobile

        let bundle = {
#if SWIFT_PACKAGE
            return Bundle.module
#else
            return Bundle.init(for: PagecallWebView.self)
#endif
        }()
        if let scriptPath = bundle.path(forResource: "PagecallNative", ofType: "js"), let bindingJS = try? String(contentsOfFile: scriptPath, encoding: .utf8) {
            let script = WKUserScript(source: bindingJS, injectionTime: .atDocumentStart, forMainFrameOnly: false)
            configuration.userContentController.addUserScript(script)
        } else {
            PagecallLogger.shared.capture(message: "Failed to add PagecallNative script")
        }

        super.init(frame: frame, configuration: configuration)
        uiDelegate = self
        navigationDelegate = self
        allowsBackForwardNavigationGestures = false
        customUserAgent = [safariUserAgent, "PagecalliOSSDK/\(PagecallWebView.version)"].compactMap { $0 }.joined(separator: " ")
        scrollView.contentInsetAdjustmentBehavior = .never

        let interaction = UIPencilInteraction()
        interaction.delegate = self
        addInteraction(interaction)
    }

    private var callbacks = [String: (Any?) -> Void]()
    public func getReturnValue(script: String, completion: @escaping (Any?) -> Void) {
        let id = UUID().uuidString
        callbacks[id] = completion
        let returningScript =
            """
const callback = (value) => {
  window.webkit.messageHandlers.\(controllerName).postMessage({
    type: "return",
    payload: {
      id: "\(id)",
      value
    }
  });
}
const result = \(script);

if (result.then) {
  result.then(callback);
} else {
  callback(result);
}
"""
        evaluateJavascriptWithLog(script: returningScript)
    }

    private var subscribers = [String: (Any?) -> Void]()
    private let subscriptionsStorageName = "__pagecallNativeSubscriptions"
    public func subscribe(target: String, subscriber: @escaping (Any?) -> Void) -> () -> Void {
        let id = UUID().uuidString
        subscribers[id] = subscriber
        let returningScript =
            """
const callback = (value) => {
  window.webkit.messageHandlers.\(controllerName).postMessage({
    type: "subscription",
    payload: {
      id: "\(id)",
      value
    }
  });
}
const subscription = \(target).subscribe(callback);
if (!window["\(subscriptionsStorageName)"]) window["\(subscriptionsStorageName)"] = {};
window["\(subscriptionsStorageName)"]["\(id)"] = subscription;
"""
        evaluateJavascriptWithLog(script: returningScript)

        let unsubscriber = {
            self.evaluateJavascriptWithLog(script: """
window["\(self.subscriptionsStorageName)"]["\(id)"]?.unsubscribe();
""")
            self.subscribers.removeValue(forKey: id)
        }
        cleanups.append(unsubscriber)
        return unsubscriber
    }

    private var cleanups: [() -> Void] = []
    private func cleanupPagecallContext() {
        cleanups.forEach { cleanup in
            cleanup()
        }
        cleanups = []
    }

    open override func didMoveToSuperview() {
        if superview == nil {
            cleanupPagecallContext()
        }
    }

    deinit {
        cleanupPagecallContext()
    }

    public func sendMessage(message: String, completionHandler: ((Error?) -> Void)?) {
        evaluateJavascriptWithLog(script:
"""
if (!window.Pagecall) return false;
window.Pagecall.sendMessage("\(message.javaScriptString)");
return true;
"""
        ) { result, error in
            if let error {
                completionHandler?(error)
            } else if let success = result as? Bool, success {
                completionHandler?(nil)
            } else {
                completionHandler?(PagecallError(message: "Not initialized"))
            }
        }
    }

    public func listenMessage(subscriber: @escaping (String) -> Void) -> () -> Void {
        return subscribe(target: "PagecallUI.customMessage$") { payload in
            if let payload = payload as? String {
                subscriber(payload)
            } else {
                print("[PagecallWebView] Invalid or unsupported message")
            }
        }
    }

    public func load(roomId: String, mode: PagecallMode) -> WKNavigation? {
        return load(roomId: roomId, mode: mode, queryItems: [])
    }

    public func load(roomId: String, mode: PagecallMode, queryItems: [URLQueryItem]) -> WKNavigation? {
        var urlComps = URLComponents(string: mode.baseURLString())!
        urlComps.queryItems = [URLQueryItem(name: "room_id", value: roomId)] + queryItems
        PagecallLogger.shared.setRoomId(roomId)
        return super.load(URLRequest(url: urlComps.url!))
    }

    override open func load(_ request: URLRequest) -> WKNavigation? {
        if let url = request.url, let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            if let roomId = components.queryItems?.first(where: { item in item.name == "room_id" })?.value {
                PagecallLogger.shared.setRoomId(roomId)
            } else {
                print("[PagecallWebView] a non-pagecall url is loaded")
            }
        }
        return super.load(request)
    }

    // MARK: - UIPencilInteractionDelegate
    private var downloadedPreviewItemUrl: URL?
}

extension PagecallWebView: WKScriptMessageHandler {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == self.controllerName else { return }
        if let body = message.body as? [String: Any] {
            guard let type = body["type"] as? String, let payload = body["payload"] as? [String: Any], let id = payload["id"] as? String else { return }
            switch type {
            case "return":
                guard let callback = callbacks[id] else { return }
                callbacks.removeValue(forKey: id)
                callback(payload["value"])
            case "subscription":
                guard let subscriber = subscribers[id] else { return }
                subscriber(payload["value"])
            default:
                print("[PagecallWebView] Unknown message type: \(type)")
            }
            return
        } else if let body = message.body as? String {
            self.nativeBridge?.messageHandler(message: body)
        }
    }
}

extension PagecallWebView: WKUIDelegate {
    @available(iOS 15.0, *)
    public func webView(
        _ webView: WKWebView,
        requestMediaCapturePermissionFor origin: WKSecurityOrigin,
        initiatedByFrame frame: WKFrameInfo,
        type: WKMediaCaptureType,
        decisionHandler: @escaping (WKPermissionDecision) -> Void
    ) {
        decisionHandler(.grant)
    }
}

extension PagecallWebView: WKNavigationDelegate {
    public func webView(
        _ webView: WKWebView,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        let cred = URLCredential(trust: challenge.protectionSpace.serverTrust!)
        DispatchQueue.global(qos: .userInitiated).async {
             completionHandler(.useCredential, cred)
         }
    }

    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if #available(iOS 15.0, *) {
            if navigationAction.shouldPerformDownload {
                decisionHandler(.download)
                return
            }
        }
        if let url = navigationAction.request.url, url.absoluteString.starts(with: "http") {
            decisionHandler(.allow)
            return
        }
        // 사진촬영 시 about:blank 로 이동해버리는 문제가 있음
        decisionHandler(.cancel)
    }

    public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if #available(iOS 15.0, *) {
            if !navigationResponse.canShowMIMEType {
                decisionHandler(.download)
                return
            }
        }
        decisionHandler(.allow)
    }

    private func initializePageContext() {
        configuration.userContentController.add(LeakAvoider(delegate: self), name: self.controllerName)
        cleanups.append({
            self.configuration.userContentController.removeScriptMessageHandler(forName: self.controllerName)
        })

        // Enable call
        CallManager.shared.startCall { error in
            if let error = error {
                print("[PagecallWebView] Failed to start call")
                PagecallLogger.shared.capture(error: error)
                self.delegate?.pagecallDidEncounter(self, error: error)
            } else {
                PagecallLogger.shared.capture(message: "Call started")
            }
        }
        cleanups.append({
            CallManager.shared.endCall { error in
                if let error = error {
                    print("[PagecallWebView] Failed to end call")
                    PagecallLogger.shared.capture(error: error)
                    self.delegate?.pagecallDidEncounter(self, error: error)
                } else {
                    PagecallLogger.shared.capture(message: "Call ended")
                }
            }
        })

        // Build native bridge
        let nativeBridge = NativeBridge(webview: self)
        self.nativeBridge = nativeBridge
        cleanups.append({
            nativeBridge.disconnect()
            if self.nativeBridge == nativeBridge {
                self.nativeBridge = nil
            }
        })

        getReturnValue(script: """
new Promise((resolve) => {
  function detectPagecallUI(trialCount) {
    if (window.PagecallUI) {
        resolve(true);
        return;
    }
    if (trialCount >= 60) {
        resolve(false);
        return;
    }
    setTimeout(() => detectPagecallUI(trialCount + 1), 1000);
  }
  detectPagecallUI(0);
})
""") { success in
            guard let success = success as? Bool, success else {
                let error = PagecallError(message: "Failed to detect PagecallUI")
                PagecallLogger.shared.capture(error: error)
                self.delegate?.pagecallDidEncounter(self, error: error)
                return
            }

            _ = self.subscribe(target: "window.PagecallUI.get$('terminationState')") { state in
                guard let state = state as? [String: String] else { return }
                self.cleanupPagecallContext()
                if let reason = state["state"] {
                    if reason == "internal" {
                        self.delegate?.pagecallDidTerminate(self, reason: .internal)
                    } else {
                        self.delegate?.pagecallDidTerminate(self, reason: .other(reason))
                    }
                } else {
                    self.delegate?.pagecallDidTerminate(self, reason: .other("unknown"))
                }
            }
            self.getReturnValue(script: """
    new Promise((resolve) => {
        const subscription = window.PagecallUI.controller$.subscribe((controller) => {
            if (!controller) return;
            resolve();
            subscription.unsubscribe();
        });
    })
    """) { _ in
                self.delegate?.pagecallDidLoad(self)
                let messageUnsubscriber = self.listenMessage(subscriber: { message in
                    self.delegate?.pagecallDidReceive(self, message: message)
                })
                self.cleanups.append(messageUnsubscriber)
            }
        }
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let isPagecallMeeting = webView.url?.absoluteString.contains(PagecallMode.meet.baseURLString()), isPagecallMeeting {
            cleanupPagecallContext()
            initializePageContext()
        }
    }

    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        cleanupPagecallContext()
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        PagecallLogger.shared.capture(error: error)
        self.delegate?.pagecallDidEncounter(self, error: error)
    }

    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        PagecallLogger.shared.capture(error: error)
    }
}

@available(iOS 14.5, *)
extension PagecallWebView: WKDownloadDelegate {
    public func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        download.delegate = self
    }

    public func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        download.delegate = self
    }

    public func download(
        _ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String
    ) async -> URL? {
        let fileManager = FileManager.default
        let tempPath = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? fileManager.createDirectory(at: tempPath, withIntermediateDirectories: false)
        let url = tempPath.appendingPathComponent(suggestedFilename)

        self.downloadedPreviewItemUrl = url
        return url
    }

    public func downloadDidFinish(_ download: WKDownload) {
        guard let downloadedPreviewItemUrl = downloadedPreviewItemUrl else {
            print("[PagecallWebViewController] Missing downloadedPreviewItemUrl")
            return
        }

        self.delegate?.pagecall(self, requestDownloadFor: downloadedPreviewItemUrl)
    }

    public func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        PagecallLogger.shared.capture(error: error)
    }

}

extension PagecallWebView: UIPencilInteractionDelegate {
    private func toggleToolMode() {
        getReturnValue(script: """
    (function() {
      let toolMode
      const subscription = Pagecall.canvas.toolMode$.subscribe((mode) => {
        toolMode = mode
      })
      subscription.unsubscribe()
      return toolMode
    })()
    """) { mode in
            guard let mode = mode as? String else { return }
            if mode == "draw" {
                self.evaluateJavascriptWithLog(script: "Pagecall.setMode('remove-line')")
            } else {
                self.evaluateJavascriptWithLog(script: "Pagecall.setMode('draw')")
            }
        }
    }

    public func pencilInteractionDidTap(_ interaction: UIPencilInteraction) {
        if !isPenInteractionEnabled { return }
        toggleToolMode()
    }
}
