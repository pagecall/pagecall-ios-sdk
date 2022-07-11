import WebKit

public class PagecallWebView: WKWebView {
    var webViewRTC: WKWebViewRTC?
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("PagecallSDK: PagecallWebView cannot be instantiated from a storyboard")
    }
    
    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.allowsInlineMediaPlayback = true
        configuration.suppressesIncrementalRendering = false
        configuration.applicationNameForUserAgent = "PagecallIos"
        
        configuration.allowsAirPlayForMediaPlayback = true
        
        if #available(iOS 13.0, *) {
            configuration.defaultWebpagePreferences.preferredContentMode = .mobile
        }
        if #available(iOS 14.0, *) {
            configuration.limitsNavigationsToAppBoundDomains = true
        }
        super.init(frame: frame, configuration: configuration)
        
        self.allowsBackForwardNavigationGestures = false
        
        if #available(iOS 15.0, *) {
            let osVersion = UIDevice.current.systemVersion
            self.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/\(osVersion) Safari/605.1.15"
        } else {
            self.webViewRTC = WKWebViewRTC(wkwebview: self, contentController: self.configuration.userContentController)
        }
    }
    
    public func dispose() {
        self.webViewRTC?.dispose()
    }
}
