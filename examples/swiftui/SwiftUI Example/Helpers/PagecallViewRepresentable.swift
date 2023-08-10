import SwiftUI
import PagecallCore

public struct PagecallViewRepresentable: UIViewRepresentable {
    public typealias UIViewType = PagecallWebViewDelegate
    private let pagecallWebViewDelegate: PagecallWebViewDelegate

    init(pagecallWebViewDelegate: PagecallWebViewDelegate) {
        self.pagecallWebViewDelegate = pagecallWebViewDelegate
    }

    public func makeUIView(context: Context) -> PagecallWebViewDelegate {
        return pagecallWebViewDelegate
    }

    public func updateUIView(_ uiView: PagecallWebViewDelegate, context: Context) {
    }
}
