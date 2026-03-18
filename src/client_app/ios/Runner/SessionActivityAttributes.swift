import ActivityKit
import Foundation

@available(iOS 16.2, *)
struct SessionActivityAttributes: ActivityAttributes {
    /// Static data — doesn't change during the activity
    let roomName: String
    let locale: String

    /// Dynamic data — updated while the activity is running
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

        // Cooldown timestamps — set after a button is tapped
        var waiterCooldownEnd: Date?
        var controllerCooldownEnd: Date?
    }
}
