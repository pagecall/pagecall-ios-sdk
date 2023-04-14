import UIKit
import WebKit

public protocol PagecallDelegate {
    func pagecallDidClose(_ controller: PagecallWebViewController)
    func pagecallDidLoad(_ controller: PagecallWebViewController)
    func pagecall(_ controller: PagecallWebViewController, requestDownloadFor url: URL)
}

public class PagecallWebViewController:
    UIViewController, WKUIDelegate, WKScriptMessageHandler, WKNavigationDelegate, UIPencilInteractionDelegate {
    private var webView: PagecallWebView!
    private let bridgeName = "pagecallController"

    public var delegate: PagecallDelegate?

    public var isPenInteractionEnabled = false

    private var userAgent: String {
        let webkitVersion = "605.1.15"
        let systemVersion = UIDevice.current.systemVersion.replacingOccurrences(of: ".", with: "_")

        let systemFragment = UIDevice.current.userInterfaceIdiom == .phone ?
            "Mozilla/5.0 (iPhone; CPU iPhone OS \(systemVersion) like Mac OS X)"
            : "Mozilla/5.0 (Macintosh; Intel Mac OS X \(systemVersion))"
        let webkitFragment = "AppleWebKit/\(webkitVersion) (KHTML, like Gecko)"
        let versionFragment = "Version/\(systemVersion)"
        let browserFragment = "Safari/\(webkitVersion)"

        return [systemFragment, webkitFragment, versionFragment, browserFragment].joined(separator: " ")
    }

    convenience public init() {
        self.init(customUserAgent: nil)
    }

    public init(customUserAgent: String?) {
        super.init(nibName: nil, bundle: nil)

        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(LeakAvoider(delegate: self), name: bridgeName)
        configuration.limitsNavigationsToAppBoundDomains = true
        configuration.allowsInlineMediaPlayback = true
        webView = PagecallWebView(frame: .zero, configuration: configuration)
        webView.scrollView.contentInsetAdjustmentBehavior = .never

        webView.uiDelegate = self
        webView.navigationDelegate = self

        webView.allowsBackForwardNavigationGestures = false
        webView.customUserAgent = [userAgent, "PagecallSDK", "PagecallWebViewController", customUserAgent].compactMap { $0 }.joined(separator: " ")

        let interaction = UIPencilInteraction()
        interaction.delegate = self
        webView.addInteraction(interaction)

        view.addSubview(webView)
    }

    public func load(_ url: URL) {
        self.webView.load(URLRequest(url: url))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        webView.loadHTMLString("", baseURL: nil)
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        webView.frame = view.bounds
    }

    private func toggleToolMode() {
        self.getReturnValue(script: """
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
                self.webView.evaluateJavascriptWithLog(script: "Pagecall.setMode('remove-line')")
            } else {
                self.webView.evaluateJavascriptWithLog(script: "Pagecall.setMode('draw')")
            }
        }
    }

    private func getReturnValue(script: String, completion: @escaping (Any?) -> Void) {
        let id = UUID().uuidString
        callbacks[id] = completion
        let returningScript =
            """
const callback = (value) => {
  window.webkit.messageHandlers.\(bridgeName).postMessage({
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
        webView.evaluateJavascriptWithLog(script: returningScript)
    }

    var callbacks = [String: (Any?) -> Void]()
    var subscribers = [String: (Any?) -> Void]()

    let subscriptionsStorageName = "__pagecallNativeSubscriptions"
    public func subscribe(target: String, subscriber: @escaping (Any?) -> Void) -> () -> Void {
        let id = UUID().uuidString
        subscribers[id] = subscriber
        let returningScript =
            """
const callback = (value) => {
  window.webkit.messageHandlers.\(bridgeName).postMessage({
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
        webView.evaluateJavascriptWithLog(script: returningScript)
        return {
            self.webView.evaluateJavascriptWithLog(script: """
window["\(self.subscriptionsStorageName)"][\(id)]?.unsubscribe();
""")
            self.subscribers.removeValue(forKey: id)
        }
    }

    // MARK: - WKUIDelegate
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

    // MARK: - WKScriptMessageHandler
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        webView.userContentController(userContentController, didReceive: message)
        guard message.name == bridgeName else { return }
        guard let body = message.body as? [String: Any] else { return }
        guard let type = body["type"] as? String, let payload = body["payload"] as? [String: Any] else { return }
        if type == "return" {
            if let id = payload["id"] as? String, let callback = callbacks[id] {
                callbacks.removeValue(forKey: id)
                callback(payload["value"])
            }
        }
        if type == "subscription" {
            if let id = payload["id"] as? String, let subscriber = subscribers[id] {
                subscriber(payload["value"])
            }
        }
    }

    // MARK: - WKNavigationDelegate
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

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.getReturnValue(script: """
function() {
    let trialCount = 0;
    function waitForLoad() {
        trialCount += 1;
        return new Promise((resolve) => {
            if (trialCount > 60) {
                console.error("PagecallUI not found");
                return resolve();
            }
            if (window.PagecallUI) {
                return resolve();
            }
            setTimeout(() => {
                waitForLoad().then(resolve);
            }, 1000);
        });
    };
    return waitForLoad();
}()
""") { _ in
            self.webView.evaluateJavascriptWithLog(script: """
window.PagecallUI.get$('terminationState').subscribe((state) => {
    if (!state) return;
    if (state.state === "error" || state.state === "emptyReplay") {
      window.addEventListener('pointerup', () => window.close())
    } else {
      window.close()
    }
});
""")
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
            }
        }
    }

    public func webViewDidClose(_ webView: WKWebView) {
        self.delegate?.pagecallDidClose(self)
    }

    deinit {
        self.webView.configuration.userContentController.removeScriptMessageHandler(forName: bridgeName)
    }

    // MARK: - UIPencilInteractionDelegate
    public func pencilInteractionDidTap(_ interaction: UIPencilInteraction) {
        if !isPenInteractionEnabled { return }
        toggleToolMode()
    }

    var downloadedPreviewItemUrl: URL?
}

@available(iOS 14.5, *)
extension PagecallWebViewController: WKDownloadDelegate {
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
        print("[PagecallWebViewController] Download failed", error)
    }

}
