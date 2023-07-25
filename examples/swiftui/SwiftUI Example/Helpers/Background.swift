//
//  Background.swift
//  SwiftUI Example
//
//  Created by 최성혁 on 2023/07/25.
//

import Foundation
import SwiftUI

struct Background<Content: View>: View {
    private var content: Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content()
    }

    var body: some View {
        Color(red: 0.98, green: 0.98, blue: 0.98)
        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        .overlay(content)
    }
}
