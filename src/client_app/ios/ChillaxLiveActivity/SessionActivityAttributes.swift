// Shared with main app target — must be identical to Runner/SessionActivityAttributes.swift
import ActivityKit
import Foundation

@available(iOS 16.1, *)
struct SessionActivityAttributes: ActivityAttributes {
    let roomName: String
    let locale: String

    public struct ContentState: Codable, Hashable {
        var startTime: Date
        var drink1Name: String?
        var drink2Name: String?
    }
}
