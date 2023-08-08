import SwiftUI
import PagecallCore

public struct PagecallBridge: UIViewRepresentable {
    public typealias UIViewType = PagecallWebViewWrapper
    private let pagecallWebViewWrapper: PagecallWebViewWrapper

    init(pagecallWebViewWrapper: PagecallWebViewWrapper) {
        self.pagecallWebViewWrapper = pagecallWebViewWrapper
    }

    public func makeUIView(context: Context) -> PagecallWebViewWrapper {
        return pagecallWebViewWrapper
    }

    public func updateUIView(_ uiView: PagecallWebViewWrapper, context: Context) {
    }
}
