import SwiftUI

public struct PagecallView: UIViewControllerRepresentable, PagecallDelegate {
    public func pagecallDidLoad(_ controller: PagecallWebViewController) {
        onLoad?()
    }

    public func pagecallDidClose(_ controller: PagecallWebViewController) {
        onClose?()
    }

    public func pagecall(_ controller: PagecallWebViewController, requestDownloadFor url: URL) {
        onDownloadRequest?(url)
    }

    let url: URL
    let onLoad: (() -> Void)?
    let onClose: (() -> Void)?
    let onDownloadRequest: ((URL) -> Void)?

    public init(url: URL) {
        self.init(url: url, onLoad: nil, onClose: nil, onDownloadRequest: nil)
    }

    public init(url: URL, onLoad: (() -> Void)?, onClose: (() -> Void)?, onDownloadRequest: ((URL) -> Void)?) {
        self.url = url
        self.onLoad = onLoad
        self.onClose = onClose
        self.onDownloadRequest = onDownloadRequest
    }

    public func makeUIViewController(context: Context) -> some UIViewController {
        let controller = PagecallWebViewController()
        controller.delegate = self
        controller.load(url)
        return controller
    }

    public func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
    }
}