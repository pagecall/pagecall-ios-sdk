//
//  UIApplication+endEditing.swift
//  SwiftUI Example
//
//  Created by 최성혁 on 2023/07/24.
//

import Foundation
import UIKit

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
