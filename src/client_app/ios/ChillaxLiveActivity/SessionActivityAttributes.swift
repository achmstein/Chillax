// Shared with main app target — must be identical to Runner/SessionActivityAttributes.swift
import ActivityKit
import Foundation

@available(iOS 16.2, *)
struct SessionActivityAttributes: ActivityAttributes {
    let roomName: String
    let locale: String

    public struct ContentState: Codable, Hashable {
        var startTime: Date
        var drink1Name: String?
        var drink2Name: String?

        // Session context for background action intents (iOS 17+)
        var accessToken: String?
        var apiBaseUrl: String?
        var sessionId: Int?
        var roomId: Int?
        var branchId: Int?
        var roomNameEn: String?
        var roomNameAr: String?
        var ordersApiUrl: String?
        var drink1OrderPayload: String?
        var drink2OrderPayload: String?
    }
}
