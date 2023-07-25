import SwiftUI
import PagecallCore

class PagecallManager: PagecallDelegate {
    let onLoad: (() -> Void)?
    let onTerminate: ((TerminationReason) -> Void)?

    init(onLoad: (() -> Void)?, onTerminate: ((TerminationReason) -> Void)?) {
        self.onLoad = onLoad
        self.onTerminate = onTerminate
    }

    public func pagecallDidTerminate(_ view: PagecallWebView, reason: TerminationReason) {
        onTerminate?(reason)
    }

    public func pagecallDidLoad(_ view: PagecallWebView) {
        onLoad?()
    }
}

public struct Pagecall: UIViewControllerRepresentable {
    let roomId: String
    let accessToken: String
    let queryItems: [URLQueryItem]?
    let view = PagecallWebView()

    let mode: PagecallMode
    let delegate: PagecallManager

    public init(roomId: String, accessToken: String, queryItems: [URLQueryItem]?, mode: PagecallMode, onLoad: (() -> Void)?, onTerminate: ((TerminationReason) -> Void)?) {
        self.roomId = roomId
        self.accessToken = accessToken
        self.queryItems = queryItems

        self.mode = mode
        self.delegate = PagecallManager(onLoad: onLoad, onTerminate: onTerminate)
    }

    public func makeUIViewController(context: Context) -> some UIViewController {
        let controller = UIViewController()
        controller.view.addSubview(view)

        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor),
            view.topAnchor.constraint(equalTo: controller.view.safeAreaLayoutGuide.topAnchor),
            view.bottomAnchor.constraint(equalTo: controller.view.safeAreaLayoutGuide.bottomAnchor)
        ])
        view.delegate = self.delegate
        if let queryItems = queryItems {
            _ = view.load(roomId: roomId, accessToken: accessToken, mode: mode, queryItems: queryItems)
        } else {
            _ = view.load(roomId: roomId, accessToken: accessToken, mode: mode)
        }
        return controller
    }

    public func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
    }
}
