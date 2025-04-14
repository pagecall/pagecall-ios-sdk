//
//  PagecallError.swift
//  
//
//  Created by Jaeseong Seo on 2023/03/16.
//

import Foundation

public enum PagecallError: LocalizedError {
    case other(message: String)
    case audioRecorderBroken

    var message: String {
        switch self {
        case .other(let message):
            return message
        case .audioRecorderBroken:
            return "AVAudioRecorder seems to be broken"
        }
    }
    var errorDescription: String { message }
    var failureReason: String { message }
    public var recoverySuggestion: String? { "" }
    public var helpAnchor: String? { "" }
}
