//
//  File.swift
//  SwiftUI Example
//
//  Created by 최성혁 on 2023/08/11.
//

import Foundation
import SwiftUI
import PagecallCore

enum PagecallState {
    case loading
    case loaded
    case terminated
}

class PagecallWebViewModel: PagecallDelegate, ObservableObject {
    @Published public var state = PagecallState.loading
    @Published public var newMessage: String?

    public var view: UIView {
        get {
            pagecallWebView
        }
    }

    private let pagecallWebView = PagecallWebView()

    init(roomId: String, accessToken: String, mode: PagecallMode, queryItems: [URLQueryItem]?) {
        pagecallWebView.delegate = self
        _ = pagecallWebView.load(roomId: roomId, accessToken: accessToken, mode: mode, queryItems: queryItems ?? [])
    }

    func sendMessage(_ message: String) {
        pagecallWebView.sendMessage(message: message, completionHandler: nil)
    }

    public func pagecallDidCommit(_ view: PagecallWebView) {
        print("pagecallWebView did commit")
    }
    
    public func pagecallDidLoad(_ view: PagecallWebView) {
        state = .loaded
    }

    public func pagecallDidTerminate(_ view: PagecallCore.PagecallWebView, reason: PagecallCore.TerminationReason) {
        state = .terminated
    }

    public func pagecallDidReceive(_ view: PagecallWebView, message: String) {
        newMessage = message
    }
}
