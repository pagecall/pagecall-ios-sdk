//
//  PagecallError.swift
//  
//
//  Created by Jaeseong Seo on 2023/03/16.
//

import Foundation

struct PagecallError: LocalizedError {
    let message: String

    var errorDescription: String { message }
    var failureReason: String { message }
    var recoverySuggestion: String? { "" }
    var helpAnchor: String? { "" }
}
