//
//  ChimeController.swift
//
//
//  Created by 록셉 on 2022/07/27.
//

import AmazonChimeSDK
import Foundation

class ChimeController {
    init() {}

    func connect(joinMeetingData: Data) {
        let logger = ConsoleLogger(name: "DefaultMeetingSession", level: LogLevel.INFO)

        let meetingSessionConfiguration = JoinRequestService.getMeetingSessionConfiguration(data: joinMeetingData)

        guard let meetingSessionConfiguration = meetingSessionConfiguration else {
            logger.error(msg: "Failed to parse meetingSessionConfiguration")
            return
        }

        let meetingSession = DefaultMeetingSession(configuration: meetingSessionConfiguration, logger: logger)
        print(meetingSession)
        do { try meetingSession.audioVideo.start()
            print("succeed")
        } catch { print(error) }
    }
}
