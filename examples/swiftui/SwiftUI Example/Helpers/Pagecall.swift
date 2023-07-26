import SwiftUI
import PagecallCore

class PagecallManager: PagecallDelegate {
    let onLoad: (() -> Void)?
    let onTerminate: ((TerminationReason) -> Void)?
    let onReceive: ((String) -> Void)?

    init(onLoad: (() -> Void)?, onTerminate: ((TerminationReason) -> Void)?, onReceive: ((String) -> Void)?) {
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
    let pagecallWebView: PagecallWebView
    let roomId: String
    let accessToken: String
    let queryItems: [URLQueryItem]?

    let mode: PagecallMode
    let delegate: PagecallManager

    public init(pagecallWebView: PagecallWebView, roomId: String, accessToken: String, queryItems: [URLQueryItem]?, mode: PagecallMode, onLoad: (() -> Void)?, onTerminate: ((TerminationReason) -> Void)?, onReceive: ((String) -> Void)?) {
        self.roomId = roomId
        self.accessToken = accessToken
        self.queryItems = queryItems
        self.pagecallWebView = pagecallWebView

        self.mode = mode
        self.delegate = PagecallManager(onLoad: onLoad, onTerminate: onTerminate, onReceive: onReceive)
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
        pagecallWebView.delegate = self.delegate
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
