//
//  PagecallWebViewWrapper.swift
//  SwiftUI Example
//
//  Created by 최성혁 on 2023/08/08.
//

import Foundation
import PagecallCore
import UIKit

public class PagecallWebViewDelegate: PagecallDelegate {
    private var onLoad: (() -> Void)?
    private var onTerminate: ((TerminationReason) -> Void)?
    private var onReceive: ((String) -> Void)?

    init(onLoad: (() -> Void)?, onTerminate: ((TerminationReason) -> Void)?, onReceive: ((String) -> Void)?) {
        self.onLoad = onLoad
        self.onTerminate = onTerminate
        self.onReceive = onReceive
    }

    public func pagecallDidLoad(_ view: PagecallWebView) {
        onLoad?()
    }

    public func pagecallDidTerminate(_ view: PagecallCore.PagecallWebView, reason: PagecallCore.TerminationReason) {
        onTerminate?(reason)
    }

    public func pagecallDidReceive(_ view: PagecallWebView, message: String) {
        onReceive?(message)
    }
}
