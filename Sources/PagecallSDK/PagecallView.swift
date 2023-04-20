import SwiftUI

public struct PagecallView: UIViewControllerRepresentable, PagecallDelegate {
    public func pagecallDidReceive(_ controller: PagecallWebViewController, message: String) {
        onMessage?(message)
    }

    public func pagecallDidLoad(_ controller: PagecallWebViewController) {
        onLoad?()
    }

    public func pagecallDidClose(_ controller: PagecallWebViewController) {
        onClose?()
    }

    public func pagecall(_ controller: PagecallWebViewController, requestDownloadFor url: URL) {
        onDownloadRequest?(url)
    }

    let roomId: String
    let mode: PagecallMode
    let onLoad: (() -> Void)?
    let onClose: (() -> Void)?
    let onDownloadRequest: ((URL) -> Void)?
    let onMessage: ((String) -> Void)?

    public init(roomId: String) {
        self.init(roomId: roomId, mode: .meet)
    }

    public init(roomId: String, mode: PagecallMode) {
        self.init(roomId: roomId, mode: mode, onLoad: nil, onClose: nil, onDownloadRequest: nil, onMessage: nil)
    }

    public init(roomId: String, mode: PagecallMode, onLoad: (() -> Void)?, onClose: (() -> Void)?, onDownloadRequest: ((URL) -> Void)?, onMessage: ((String) -> Void)?) {
        self.roomId = roomId
        self.mode = mode
        self.onLoad = onLoad
        self.onClose = onClose
        self.onDownloadRequest = onDownloadRequest
        self.onMessage = onMessage
    }

    public func makeUIViewController(context: Context) -> some UIViewController {
        let controller = PagecallWebViewController()
        controller.delegate = self
        _ = controller.load(roomId: roomId, mode: mode)
        return controller
    }

    public func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
    }
}
