//
//  String+asQueryItems.swift
//  SwiftUI Example
//
//  Created by 최성혁 on 2023/08/16.
//

import Foundation

extension String {
    func asQueryItems() -> [URLQueryItem]? {
        if !self.isEmpty {
            return self.components(separatedBy: "&")
                .map {
                    $0.components(separatedBy: "=")
                }
                .map {
                    URLQueryItem(name: $0[0], value: $0[1])
                }
        }
        return nil
    }
}
