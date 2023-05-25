import UIKit
import WebKit

public protocol PagecallDelegate {
    func pagecallDidClose(_ controller: PagecallWebViewController)
    func pagecallDidLoad(_ controller: PagecallWebViewController)
    func pagecallDidReceive(_ controller: PagecallWebViewController, message: String)
    func pagecall(_ controller: PagecallWebViewController, requestDownloadFor url: URL)
}

// Optional delegates
public extension PagecallDelegate {
    func pagecallDidLoad(_ controller: PagecallWebViewController) {}
    func pagecallDidReceive(_ controller: PagecallWebViewController, message: String) {}
    func pagecall(_ controller: PagecallWebViewController, requestDownloadFor url: URL) {}
}

public class PagecallWebViewController: UIViewController, WKUIDelegate, WKNavigationDelegate, UIPencilInteractionDelegate, PagecallWebViewDelegate {

    private let webView = PagecallWebView()

    public var delegate: PagecallDelegate?

    public var isPenInteractionEnabled = false

    convenience public init() {
        self.init(customUserAgent: nil)
    }

    public init(customUserAgent: String?) {
        super.init(nibName: nil, bundle: nil)

        webView.scrollView.contentInsetAdjustmentBehavior = .never

        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.delegate = self

        webView.customUserAgent = [webView.customUserAgent, "PagecallWebViewController", customUserAgent].compactMap { $0 }.joined(separator: " ")

        let interaction = UIPencilInteraction()
        interaction.delegate = self
        webView.addInteraction(interaction)

        view.addSubview(webView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.messageUnsubscriber?()
        webView.loadHTMLString("", baseURL: nil)
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        webView.frame = view.bounds
    }

    private func toggleToolMode() {
        webView.getReturnValue(script: """
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

    var messageUnsubscriber: (() -> Void)?

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let isPagecallMeeting = webView.url?.absoluteString.contains(PagecallMode.meet.baseURLString()), isPagecallMeeting {
            CallManager.shared.startCall { error in
                if let error = error {
                    print("[PagecallViewController] Failed to start call")
                    PagecallLogger.shared.capture(error: error)
                } else {
                    PagecallLogger.shared.capture(message: "Call started")
                }
            }
        }
    }

    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        CallManager.shared.endCall { error in
            if let error = error {
                print("[PagecallViewController] Failed to end call")
                PagecallLogger.shared.capture(error: error)
            } else {
                PagecallLogger.shared.capture(message: "Call ended")
            }
        }
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        PagecallLogger.shared.capture(error: error)
    }

    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        PagecallLogger.shared.capture(error: error)
    }

    public func webViewDidClose(_ webView: WKWebView) {
        self.delegate?.pagecallDidClose(self)
    }

    // MARK: - PagecallWebViewDelegate
    public func pagecallDidLoad(_ webView: PagecallWebView) {
        webView.evaluateJavascriptWithLog(script: """
window.PagecallUI.get$('terminationState').subscribe((state) => {
    if (!state) return;
    if (state.state === "error" || state.state === "emptyReplay") {
      window.addEventListener('pointerup', () => window.close())
    } else {
      window.close()
    }
});
""")
        webView.getReturnValue(script: """
new Promise((resolve) => {
    const subscription = window.PagecallUI.controller$.subscribe((controller) => {
        if (!controller) return;
        resolve();
        subscription.unsubscribe();
    });
})
""") { _ in
            self.delegate?.pagecallDidLoad(self)
            self.messageUnsubscriber?()
            self.messageUnsubscriber = webView.listenMessage(subscriber: { message in
                self.delegate?.pagecallDidReceive(self, message: message)
            })
        }
    }

    // MARK: - UIPencilInteractionDelegate
    public func pencilInteractionDidTap(_ interaction: UIPencilInteraction) {
        if !isPenInteractionEnabled { return }
        toggleToolMode()
    }

    var downloadedPreviewItemUrl: URL?

    // MARK: Public methods
    public func load(roomId: String, mode: PagecallMode) -> WKNavigation? {
        return self.webView.load(roomId: roomId, mode: mode)
    }

    public func sendMessage(_ message: String) {
        sendMessage(message, completionHandler: nil)
    }

    public func sendMessage(_ message: String, completionHandler: ((Error?) -> Void)?) {
        webView.sendMessage(message: message, completionHandler: completionHandler)
    }

    deinit {
        CallManager.shared.endCall { error in
            if let error = error {
                print("[PagecallViewController] Failed to end call in deinit", error)
            } else {
                print("[PagecallViewController] Call ended in deinit")
            }
        }
    }
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
        PagecallLogger.shared.capture(error: error)
    }

}
