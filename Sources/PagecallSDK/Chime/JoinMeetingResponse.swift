//
//  JoinMeetingResponse.swift
//
//
//  Created by 록셉 on 2022/07/27.
//

import AmazonChimeSDK
import Foundation

struct CreateMediaPlacementInfo: Codable {
    var audioFallbackUrl: String?
    var audioHostUrl: String
    var signalingUrl: String
    var turnControlUrl: String?
    var eventIngestionUrl: String?

    enum CodingKeys: String, CodingKey {
        case audioFallbackUrl = "AudioFallbackUrl"
        case audioHostUrl = "AudioHostUrl"
        case signalingUrl = "SignalingUrl"
        case turnControlUrl = "TurnControlUrl"
        case eventIngestionUrl = "EventIngestionUrl"
    }
}

struct CreateMeetingInfo: Codable {
    var externalMeetingId: String?
    var mediaPlacement: CreateMediaPlacementInfo
    var mediaRegion: String
    var meetingId: String

    enum CodingKeys: String, CodingKey {
        case externalMeetingId = "ExternalMeetingId"
        case mediaPlacement = "MediaPlacement"
        case mediaRegion = "MediaRegion"
        case meetingId = "MeetingId"
    }
}

struct CreateAttendeeInfo: Codable {
    var attendeeId: String
    var externalUserId: String
    var joinToken: String

    enum CodingKeys: String, CodingKey {
        case attendeeId = "AttendeeId"
        case externalUserId = "ExternalUserId"
        case joinToken = "JoinToken"
    }
}

struct CreateMeeting: Codable {
    var meeting: CreateMeetingInfo

    enum CodingKeys: String, CodingKey {
        case meeting = "Meeting"
    }
}

struct CreateAttendee: Codable {
    var attendee: CreateAttendeeInfo

    enum CodingKeys: String, CodingKey {
        case attendee = "Attendee"
    }
}

struct JoinMeetingResponse: Codable {
    var meeting: CreateMeeting
    var attendee: CreateAttendee

    enum CodingKeys: String, CodingKey {
        case meeting = "meetingResponse"
        case attendee = "attendeeResponse"
    }
}

class JoinRequestService: NSObject {
    static let logger = ConsoleLogger(name: "JoiningRequestService")

    private static func processJson(data: Data) -> JoinMeetingResponse? {
        let jsonDecoder = JSONDecoder()
        do {
            let joinMeetingResponse = try jsonDecoder.decode(JoinMeetingResponse.self, from: data)
            return joinMeetingResponse
        } catch let DecodingError.dataCorrupted(context) {
            logger.error(msg: "Data corrupted: \(context)")
            return nil
        } catch let DecodingError.keyNotFound(key, context) {
            logger.error(msg: "Key '\(key)' not found: \(context.debugDescription), codingPath: \(context.codingPath)")
            return nil
        } catch let DecodingError.valueNotFound(value, context) {
            logger.error(msg: "Value '\(value)' not found: \(context.debugDescription), codingPath: \(context.codingPath)")
            return nil
        } catch let DecodingError.typeMismatch(type, context) {
            logger.error(msg: "Type '\(type)' mismatch: \(context.debugDescription), codingPath: \(context.codingPath)")
            return nil
        } catch {
            logger.error(msg: "Other decoding error: \(error)")
            return nil
        }
    }

    private static func getCreateMeetingResponse(joinMeetingResponse: JoinMeetingResponse) -> CreateMeetingResponse {
        let meeting = joinMeetingResponse.meeting.meeting
        let meetingResp = CreateMeetingResponse(meeting:
            Meeting(
                externalMeetingId: meeting.externalMeetingId,
                mediaPlacement: MediaPlacement(
                    audioFallbackUrl: meeting.mediaPlacement.audioFallbackUrl ?? "",
                    audioHostUrl: meeting.mediaPlacement.audioHostUrl,
                    signalingUrl: meeting.mediaPlacement.signalingUrl,
                    turnControlUrl: meeting.mediaPlacement.turnControlUrl ?? "",
                    eventIngestionUrl: meeting.mediaPlacement.eventIngestionUrl
                ),
                mediaRegion: meeting.mediaRegion,
                meetingId: meeting.meetingId
            )
        )
        return meetingResp
    }

    private static func getCreateAttendeeResponse(joinMeetingResponse: JoinMeetingResponse) -> CreateAttendeeResponse {
        let attendee = joinMeetingResponse.attendee.attendee
        let attendeeResp = CreateAttendeeResponse(attendee:
            Attendee(attendeeId: attendee.attendeeId,
                     externalUserId: attendee.externalUserId,
                     joinToken: attendee.joinToken)
        )
        return attendeeResp
    }

    static func getMeetingSessionConfiguration(data: Data) -> MeetingSessionConfiguration? {
        let joinMeetingResponse = JoinRequestService.processJson(data: data)
        guard let joinMeetingResponse = joinMeetingResponse else {
            return nil
        }

        return MeetingSessionConfiguration(createMeetingResponse: JoinRequestService.getCreateMeetingResponse(joinMeetingResponse: joinMeetingResponse), createAttendeeResponse: JoinRequestService.getCreateAttendeeResponse(joinMeetingResponse: joinMeetingResponse))
    }
}
