//
//  NativeBridge.swift
//
//
//  Created by 록셉 on 2022/07/26.
//

import Foundation
import WebKit

class NativeBridge {
    init() {}

    func messageHandler(message: String, evaluateJavaScript: (String) -> Void) {
        print(message)
    }
}
