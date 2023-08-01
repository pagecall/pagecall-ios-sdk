import SwiftUI
import PagecallCore

extension PagecallWebView: ObservableObject {

}

class PagecallManager: PagecallDelegate, ObservableObject {
    private var onLoad: (() -> Void)?
    private var onTerminate: ((TerminationReason) -> Void)?
    private var onReceive: ((String) -> Void)?

    public func setHandlers(onLoad: (() -> Void)?, onTerminate: ((TerminationReason) -> Void)?, onReceive: ((String) -> Void)?) {
        self.onLoad = onLoad
        self.onTerminate = onTerminate
        self.onReceive = onReceive
    }

    public func pagecallDidTerminate(_ view: PagecallWebView, reason: TerminationReason) {
        onTerminate?(reason)
    }

    public func pagecallDidLoad(_ view: PagecallWebView) {
        onLoad?()
    }

    public func pagecallDidReceive(_ view: PagecallWebView, message: String) {
        onReceive?(message)
    }
}

public struct Pagecall: UIViewControllerRepresentable {
    private let pagecallWebView: PagecallWebView

    private let roomId: String
    private let accessToken: String
    private let queryItems: [URLQueryItem]?

    private let mode: PagecallMode

    public init(pagecallWebView: PagecallWebView, roomId: String, accessToken: String, queryItems: [URLQueryItem]?, mode: PagecallMode) {
        self.pagecallWebView = pagecallWebView
        self.roomId = roomId
        self.accessToken = accessToken
        self.queryItems = queryItems
        self.mode = mode
    }

    public func makeUIViewController(context: Context) -> some UIViewController {
        let controller = UIViewController()
        controller.view.addSubview(pagecallWebView)

        pagecallWebView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pagecallWebView.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor),
            pagecallWebView.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor),
            pagecallWebView.topAnchor.constraint(equalTo: controller.view.safeAreaLayoutGuide.topAnchor),
            pagecallWebView.bottomAnchor.constraint(equalTo: controller.view.safeAreaLayoutGuide.bottomAnchor)
        ])

        if let queryItems = queryItems {
            _ = pagecallWebView.load(roomId: roomId, accessToken: accessToken, mode: mode, queryItems: queryItems)
        } else {
            _ = pagecallWebView.load(roomId: roomId, accessToken: accessToken, mode: mode)
        }
        return controller
    }

    public func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
    }
}
