import WebKit

class PagecallWebView: WKWebView {
    required init?(coder: NSCoder) {
        super.init(coder: coder);
    }
    
    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        configuration.mediaTypesRequiringUserActionForPlayback = [];
        configuration.allowsInlineMediaPlayback = true;
        configuration.suppressesIncrementalRendering = false;
        configuration.allowsAirPlayForMediaPlayback = true;
        if #available(iOS 13.0, *) {
            configuration.defaultWebpagePreferences.preferredContentMode = .mobile;
        }
        super.init(frame: frame, configuration: configuration)
    }
}
