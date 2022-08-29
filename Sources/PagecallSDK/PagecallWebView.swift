import WebKit

public class PagecallWebView: WKWebView, WKScriptMessageHandler {
    var nativeBridge: NativeBridge?
    var controllerName = "pagecall"
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("PagecallSDK: PagecallWebView cannot be instantiated from a storyboard")
    }
    
    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        let contentController = WKUserContentController()
        
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.allowsInlineMediaPlayback = true
        configuration.suppressesIncrementalRendering = false
        configuration.applicationNameForUserAgent = "PagecallIos"
        configuration.allowsAirPlayForMediaPlayback = true
        configuration.userContentController = contentController
        
        if #available(iOS 13.0, *) {
            configuration.defaultWebpagePreferences.preferredContentMode = .mobile
        }
        if #available(iOS 14.0, *) {
            configuration.limitsNavigationsToAppBoundDomains = true
        }
        super.init(frame: frame, configuration: configuration)
        self.nativeBridge = .init(webview: self)
        
        self.allowsBackForwardNavigationGestures = false
        
        if #available(iOS 15.0, *) {
            let osVersion = UIDevice.current.systemVersion
            self.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/\(osVersion) Safari/605.1.15"
        }
        
        if let path = Bundle.module.path(forResource: "PagecallNative", ofType: "js") {
            if let bindingJS = try? String(contentsOfFile: path, encoding: .utf8) {
                let script = WKUserScript(source: bindingJS, injectionTime: .atDocumentStart, forMainFrameOnly: false)
                contentController.addUserScript(script)
            }
        } else {
            NSLog("Failed to add PagecallNative script")
            return
        }
        
        contentController.add(self, name: self.controllerName)
    }
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case self.controllerName:
            if let body = message.body as? String {
                self.nativeBridge?.messageHandler(message: body)
            }
        default:
            break
        }
    }
    
    public func dispose() {}
}
