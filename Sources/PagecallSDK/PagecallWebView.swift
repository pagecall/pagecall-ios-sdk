import WebKit

public class PagecallWebView: WKWebView {
    var webViewRTC: WKWebViewRTC?;
    
    required init?(coder: NSCoder) {
        super.init(coder: coder);
    }
    
    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        configuration.mediaTypesRequiringUserActionForPlayback = [];
        configuration.allowsInlineMediaPlayback = true;
        configuration.suppressesIncrementalRendering = false;
        configuration.applicationNameForUserAgent = "PagecallIos"
        
        configuration.allowsAirPlayForMediaPlayback = true;
        configuration.allowsInlineMediaPlayback = true
        
        if #available(iOS 13.0, *) {
            configuration.defaultWebpagePreferences.preferredContentMode = .mobile;
        }
        if #available(iOS 14.0, *) {
            configuration.limitsNavigationsToAppBoundDomains = true
        }
        super.init(frame: frame, configuration: configuration);
        
        self.allowsBackForwardNavigationGestures = false;
        
        if #available(iOS 15.0, *) {
            self.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0 Safari/605.1.15 iOS15OrAbove"
        } else {
            self.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0 Safari/605.1.15 iOS15Below"
            self.webViewRTC = WKWebViewRTC(wkwebview: self, contentController: self.configuration.userContentController);
        }
    }
    
    func dispose() {
        self.webViewRTC?.dispose()
    }
}
