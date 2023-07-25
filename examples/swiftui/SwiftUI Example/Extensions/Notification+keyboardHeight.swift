//
//  Notification + keyboardHeight.swift
//  SwiftUI Example
//
//  Created by 최성혁 on 2023/07/24.
//

import Foundation
import UIKit
import Combine

extension Notification {
    var keyboardHeight: CGFloat {
        return (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0
    }
}
