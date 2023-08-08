//
//  PagecallWebViewWrapper.swift
//  SwiftUI Example
//
//  Created by 최성혁 on 2023/08/08.
//

import Foundation
import PagecallCore
import UIKit

public class PagecallWebViewWrapper: UIView, PagecallDelegate, ObservableObject {
    private var onLoad: (() -> Void)?
    private var onTerminate: ((TerminationReason) -> Void)?
    private var onReceive: ((String) -> Void)?

    private let pagecallWebView = PagecallWebView()
    public lazy var sendMessage = pagecallWebView.sendMessage

    public func pagecallDidTerminate(_ view: PagecallWebView, reason: TerminationReason) {
        onTerminate?(reason)
    }

    public func pagecallDidLoad(_ view: PagecallWebView) {
        onLoad?()
    }

    public func pagecallDidReceive(_ view: PagecallWebView, message: String) {
        onReceive?(message)
    }

    public init() {
        super.init(frame: .zero)

        pagecallWebView.delegate = self

        self.addSubview(pagecallWebView)
        pagecallWebView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pagecallWebView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            pagecallWebView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            pagecallWebView.topAnchor.constraint(equalTo: self.topAnchor),
            pagecallWebView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])

        if #available(iOS 16.4, *) {
            pagecallWebView.isInspectable = true
        }
    }

    public func enter(roomId: String, accessToken: String, mode: PagecallMode, queryItems: [URLQueryItem]?) {
        if let queryItems = queryItems {
            _ = pagecallWebView.load(roomId: roomId, accessToken: accessToken, mode: mode, queryItems: queryItems)
        } else {
            _ = pagecallWebView.load(roomId: roomId, accessToken: accessToken, mode: mode)
        }
    }

    public func setHandlers(onLoad: (() -> Void)?, onTerminate: ((TerminationReason) -> Void)?, onReceive: ((String) -> Void)?) {
        self.onLoad = onLoad
        self.onTerminate = onTerminate
        self.onReceive = onReceive
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
