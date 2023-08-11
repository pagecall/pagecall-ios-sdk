//
//  PagecallError.swift
//  
//
//  Created by Jaeseong Seo on 2023/03/16.
//

import Foundation

enum PagecallError: LocalizedError {
    case other(message: String)
    case audioRecorderBroken
    case audioRecorderPowerOutOfRange

    var message: String {
        switch self {
        case .other(let message):
            return message
        case .audioRecorderBroken:
            return "AVAudioRecorder seems to be broken"
        case .audioRecorderPowerOutOfRange:
            return "averagePower of AVAudioRecorder less than -120"
        }
    }
    var errorDescription: String { message }
    var failureReason: String { message }
    var recoverySuggestion: String? { "" }
    var helpAnchor: String? { "" }
}
