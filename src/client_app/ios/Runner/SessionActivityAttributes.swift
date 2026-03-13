import ActivityKit
import Foundation

@available(iOS 16.1, *)
struct SessionActivityAttributes: ActivityAttributes {
    /// Static data — doesn't change during the activity
    let roomName: String
    let locale: String

    /// Dynamic data — updated while the activity is running
    public struct ContentState: Codable, Hashable {
        var startTime: Date
        var drink1Name: String?
        var drink2Name: String?
    }
}
