import WebKit

public enum TerminationReason {
    case `internal`
    case other(String)
}

public protocol PagecallDelegate: AnyObject {
    func pagecallDidTerminate(_ view: PagecallWebView, reason: TerminationReason)
    func pagecallDidEncounter(_ view: PagecallWebView, error: Error)
    func pagecallDidLoad(_ view: PagecallWebView)
    /**
     Respond to a remote message
     The remote message could be sent from `PagecallWebView.sendMessage` or Pagecall API calls,
     and the same message is delivered to every client.
     */
    func pagecallDidReceive(_ view: PagecallWebView, message: String)
    /**
     Respond to a local event
     The possible events vary depending on the layout.
     */
    func pagecallDidReceive(_ view: PagecallWebView, event: [String: Any])
    func pagecall(_ view: PagecallWebView, requestDownloadFor url: URL)
}

// Optional delegates
public extension PagecallDelegate {
    func pagecallDidEncounter(_ view: PagecallWebView, error: Error) {}
    func pagecallDidLoad(_ view: PagecallWebView) {}
    func pagecallDidReceive(_ view: PagecallWebView, message: String) {}
    func pagecallDidReceive(_ view: PagecallWebView, event: [String: Any]) {}
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
    static let version = "0.0.20"

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
        customUserAgent = nil // Trigger setting default value
        scrollView.contentInsetAdjustmentBehavior = .never

        let interaction = UIPencilInteraction()
        interaction.delegate = self
        addInteraction(interaction)
    }

    public override var customUserAgent: String? {
        didSet {
            let pagecallUserAgent = "PagecalliOSSDK/\(PagecallWebView.version)"
            if let customUserAgent = customUserAgent, customUserAgent.count > 0 {
                if customUserAgent.contains(pagecallUserAgent) { return }
                self.customUserAgent = [customUserAgent, pagecallUserAgent].joined(separator: " ")
            } else {
                customUserAgent = [safariUserAgent, pagecallUserAgent].joined(separator: " ")
            }
        }
    }

    @available(*, deprecated, message: "Please use delegate, as uiDelegate is handled internally")
    public override var uiDelegate: WKUIDelegate? {
        didSet {
            if let uiDelegate = uiDelegate {
                if !uiDelegate.isEqual(self) {
                    fatalError("uiDelegate cannot be overridden")
                }
            } else {
                print("[PagecallWebView] uiDelegate cannot be unset")
                uiDelegate = self
            }
        }
    }

    @available(*, deprecated, message: "Please use delegate, as navigationDelegate is handled internally")
    public override var navigationDelegate: WKNavigationDelegate? {
        didSet {
            if let navigationDelegate = navigationDelegate {
                if !navigationDelegate.isEqual(self) {
                    fatalError("navigationDelegate cannot be overridden")
                }
            } else {
                print("[PagecallWebView] navigationDelegate cannot be unset")
                navigationDelegate = self
            }
        }
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
                completionHandler?(PagecallError.other(message: "Not initialized"))
            }
        }
    }

    private func listenMessage(subscriber: @escaping (String) -> Void) -> () -> Void {
        return subscribe(target: "PagecallUI.customMessage$") { payload in
            if let payload = payload as? String {
                subscriber(payload)
            } else {
                print("[PagecallWebView] Invalid or unsupported message")
            }
        }
    }

    // MARK: UIPencilInteractionDelegate
    private var downloadedPreviewItemUrl: URL?
}

// MARK: load methods
extension PagecallWebView {
    public func load(roomId: String, mode: PagecallMode) -> WKNavigation? {
        return load(roomId: roomId, mode: mode, queryItems: [])
    }

    public func load(roomId: String, accessToken: String, mode: PagecallMode) -> WKNavigation? {
        return self.load(roomId: roomId, accessToken: accessToken, mode: mode, queryItems: [])
    }

    public func load(roomId: String, accessToken: String, mode: PagecallMode, queryItems: [URLQueryItem]) -> WKNavigation? {
        return self.load(roomId: roomId, mode: mode, queryItems: [URLQueryItem(name: "access_token", value: accessToken)] + queryItems)
    }

    public func load(roomId: String, mode: PagecallMode, queryItems: [URLQueryItem]) -> WKNavigation? {
        var urlComps = URLComponents(string: mode.baseURLString())!
        urlComps.queryItems = [URLQueryItem(name: "room_id", value: roomId)] + queryItems
        PagecallLogger.shared.setRoomId(roomId)
        return super.load(URLRequest(url: urlComps.url!))
    }

    @available(*, deprecated, message: "Please use load(roomId) instead")
    override open func load(_ request: URLRequest) -> WKNavigation? {
        if let url = request.url, let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            PagecallLogger.shared.addBreadcrumb(message: "Load \(url)")
            if let roomId = components.queryItems?.first(where: { item in item.name == "room_id" })?.value {
                PagecallLogger.shared.setRoomId(roomId)
            } else {
                print("[PagecallWebView] a non-pagecall url is loaded")
            }
        }
        return super.load(request)
    }

    @available(*, deprecated, message: "Please use load(roomId) instead")
    override open func loadHTMLString(_ string: String, baseURL: URL?) -> WKNavigation? {
        return super.loadHTMLString(string, baseURL: baseURL)
    }

    @available(*, deprecated, message: "Please use load(roomId) instead")
    override open func load(_ data: Data, mimeType MIMEType: String, characterEncodingName: String, baseURL: URL) -> WKNavigation? {
        return super.load(data, mimeType: MIMEType, characterEncodingName: characterEncodingName, baseURL: baseURL)
    }
}

extension PagecallWebView: WKScriptMessageHandler {
    open func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == self.controllerName else { return }
        if let body = message.body as? [String: Any] {
            guard let type = body["type"] as? String else { return }
            switch type {
            case "PagecallEvent":
                guard let action = body["action"] as? String else { return }
                if action == "loaded" {
                    delegate?.pagecallDidLoad(self)
                } else if action == "terminated" {
                    if let payload = body["payload"] as? [String: String], let reason = payload["reason"] {
                        if reason == "internal" {
                            delegate?.pagecallDidTerminate(self, reason: .internal)
                        } else {
                            delegate?.pagecallDidTerminate(self, reason: .other(reason))
                        }
                    } else {
                        delegate?.pagecallDidTerminate(self, reason: .other("unknown"))
                    }
                } else if action == "message" {
                    guard let payload = body["payload"] as? [String: String], let message = payload["message"] else { return }
                    delegate?.pagecallDidReceive(self, message: message)
                } else if action == "event" {
                    guard let payload = body["payload"] as? [String: Any] else { return }
                    delegate?.pagecallDidReceive(self, event: payload)
                }
            case "return":
                guard let payload = body["payload"] as? [String: Any], let id = payload["id"] as? String, let callback = callbacks[id] else { return }
                callbacks.removeValue(forKey: id)
                callback(payload["value"])
            case "subscription":
                guard let payload = body["payload"] as? [String: Any], let id = payload["id"] as? String, let subscriber = subscribers[id] else { return }
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
    open func webView(
        _ webView: WKWebView,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        if let serverTrust = challenge.protectionSpace.serverTrust {
            let cred = URLCredential(trust: serverTrust)
            DispatchQueue.global(qos: .userInitiated).async {
                completionHandler(.useCredential, cred)
            }
        } else {
            PagecallLogger.shared.capture(message: "Missing serverTrust")
            DispatchQueue.global(qos: .userInitiated).async {
                completionHandler(.performDefaultHandling, nil)
            }
        }
    }

    open func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
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

    open func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if #available(iOS 15.0, *) {
            if !navigationResponse.canShowMIMEType {
                decisionHandler(.download)
                return
            }
        }
        decisionHandler(.allow)
    }

    private func listenJavascriptMessages() {
        configuration.userContentController.add(LeakAvoider(delegate: self), name: self.controllerName)
        cleanups.append({
            self.configuration.userContentController.removeScriptMessageHandler(forName: self.controllerName)
        })
    }

    private func initializePageContext() {
        listenJavascriptMessages()

        // Enable call
        CallManager.shared.startCall { error in
            if let error = error {
                print("[PagecallWebView] Failed to start call")
                PagecallLogger.shared.capture(error: error)
            } else {
                PagecallLogger.shared.addBreadcrumb(message: "Call started")
            }
        }
        cleanups.append({
            CallManager.shared.endCall { error in
                if let error = error {
                    print("[PagecallWebView] Failed to end call")
                    PagecallLogger.shared.capture(error: error)
                } else {
                    PagecallLogger.shared.addBreadcrumb(message: "Call ended")
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
    }

    open func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        PagecallLogger.shared.addBreadcrumb(message: "Navigated to \(webView.url?.absoluteString ?? "(blank)")")

        if let isPagecallMeeting = webView.url?.absoluteString.contains(PagecallMode.meet.baseURLString()), isPagecallMeeting {
            cleanupPagecallContext()
            initializePageContext()
        } else if let isPagecallReplay = webView.url?.absoluteString.contains(PagecallMode.replay.baseURLString()), isPagecallReplay {
            cleanupPagecallContext()
            listenJavascriptMessages()
        }
    }

    open func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        cleanupPagecallContext()
    }

    private func handleFatalError(_ error: Error) {
        PagecallLogger.shared.capture(error: error)
        self.delegate?.pagecallDidEncounter(self, error: error)
    }

    open func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        PagecallLogger.shared.addBreadcrumb(message: "webViewDidFailNavigation")
        handleFatalError(error)
    }

    open func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        PagecallLogger.shared.addBreadcrumb(message: "webViewDidFailProvisionalNavigation")
        handleFatalError(error)
    }

    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        PagecallLogger.shared.addBreadcrumb(message: "webContentProcessDidTerminate")
        handleFatalError(PagecallError.other(message: "webContentProcessDidTerminate"))
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
