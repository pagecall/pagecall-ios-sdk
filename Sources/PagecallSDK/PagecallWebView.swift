import WebKit

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

public protocol PagecallWebViewDelegate: AnyObject {
    func pagecallDidLoad(_ webView: PagecallWebView)
}

open class PagecallWebView: WKWebView, WKScriptMessageHandler {
    var nativeBridge: NativeBridge?
    var controllerName = "pagecall"
    public weak var delegate: PagecallWebViewDelegate?

    @available(*, unavailable)
    required public init?(coder: NSCoder) {
        fatalError("PagecallSDK: PagecallWebView cannot be instantiated from a storyboard")
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
        configuration.limitsNavigationsToAppBoundDomains = true

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
        self.allowsBackForwardNavigationGestures = false
        self.customUserAgent = safariUserAgent
        // Some environments, such as flutter_inappwebview, reuse the configuration and it is not allowed to add a handler with the same name
        configuration.userContentController.removeScriptMessageHandler(forName: self.controllerName)
        configuration.userContentController.add(LeakAvoider(delegate: self), name: self.controllerName)
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
        return {
            self.evaluateJavascriptWithLog(script: """
window["\(self.subscriptionsStorageName)"][\(id)]?.unsubscribe();
""")
            self.subscribers.removeValue(forKey: id)
        }
    }

    open func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
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

    public override func didMoveToSuperview() {
        if self.superview == nil {
            self.disposeInner()
            return
        }

        if self.nativeBridge == nil {
            self.nativeBridge = .init(webview: self)
        }
    }

    private func disposeInner() {
        self.nativeBridge?.disconnect(completion: { error in
            self.nativeBridge = nil
            if let error = error {
                PagecallLogger.shared.capture(error: error)
            }
        })
        self.configuration.userContentController.removeScriptMessageHandler(forName: self.controllerName)
    }

    deinit {
        disposeInner()
    }

    // MARK: - Public methods
    open func dispose() {
        disposeInner()
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
}
