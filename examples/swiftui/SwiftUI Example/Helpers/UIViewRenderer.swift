//
//  UIViewRenderer.swift
//  SwiftUI Example
//
//  Created by 최성혁 on 2023/08/11.
//

import Foundation
import SwiftUI

public struct UIViewRenderer: UIViewRepresentable {
    public typealias UIViewType = UIView
    private let view: UIViewType

    init(view: UIViewType) {
        self.view = view
    }

    public func makeUIView(context: Context) -> UIViewType {
        return view
    }
    public func updateUIView(_ uiView: UIViewType, context: Context) {
    }
}
