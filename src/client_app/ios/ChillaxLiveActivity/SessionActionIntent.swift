import AppIntents
import Foundation

/// Background action intent for Live Activity buttons (iOS 17+).
/// Sends service requests or drink orders directly via HTTP without opening the app.
@available(iOS 17, *)
struct SessionActionIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Session Action"

    @Parameter(title: "Action")
    var actionId: String

    @Parameter(title: "Access Token")
    var accessToken: String

    @Parameter(title: "API Base URL")
    var apiBaseUrl: String

    @Parameter(title: "Session ID")
    var sessionId: Int

    @Parameter(title: "Room ID")
    var roomId: Int

    @Parameter(title: "Branch ID")
    var branchId: Int

    @Parameter(title: "Room Name EN")
    var roomNameEn: String

    @Parameter(title: "Room Name AR")
    var roomNameAr: String?

    init() {}

    init(actionId: String, accessToken: String, apiBaseUrl: String,
         sessionId: Int, roomId: Int, branchId: Int,
         roomNameEn: String, roomNameAr: String?) {
        self.actionId = actionId
        self.accessToken = accessToken
        self.apiBaseUrl = apiBaseUrl
        self.sessionId = sessionId
        self.roomId = roomId
        self.branchId = branchId
        self.roomNameEn = roomNameEn
        self.roomNameAr = roomNameAr
    }

    func perform() async throws -> some IntentResult {
        let requestType: Int
        switch actionId {
        case "call_waiter": requestType = 1
        case "controller": requestType = 2
        default: return .result()
        }

        var roomNameJson: [String: Any] = ["en": roomNameEn]
        if let ar = roomNameAr { roomNameJson["ar"] = ar }

        let body: [String: Any] = [
            "sessionId": sessionId,
            "roomId": roomId,
            "roomName": roomNameJson,
            "requestType": requestType
        ]

        guard let url = URL(string: "\(apiBaseUrl)service-requests?api-version=1.0"),
              let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            return .result()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        if branchId != 0 {
            request.setValue("\(branchId)", forHTTPHeaderField: "X-Branch-Id")
        }
        request.httpBody = jsonData

        _ = try? await URLSession.shared.data(for: request)

        return .result()
    }
}

/// Background intent for ordering drinks from Live Activity (iOS 17+).
/// Sends a pre-computed order payload directly via HTTP without opening the app.
@available(iOS 17, *)
struct SessionDrinkOrderIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Order Drink"

    @Parameter(title: "Access Token")
    var accessToken: String

    @Parameter(title: "Orders API URL")
    var ordersApiUrl: String

    @Parameter(title: "Order Payload JSON")
    var orderPayload: String

    @Parameter(title: "Branch ID")
    var branchId: Int

    init() {}

    init(accessToken: String, ordersApiUrl: String, orderPayload: String, branchId: Int) {
        self.accessToken = accessToken
        self.ordersApiUrl = ordersApiUrl
        self.orderPayload = orderPayload
        self.branchId = branchId
    }

    func perform() async throws -> some IntentResult {
        guard let url = URL(string: ordersApiUrl),
              let jsonData = orderPayload.data(using: .utf8) else {
            return .result()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(UUID().uuidString, forHTTPHeaderField: "x-requestid")
        if branchId != 0 {
            request.setValue("\(branchId)", forHTTPHeaderField: "X-Branch-Id")
        }
        request.httpBody = jsonData

        _ = try? await URLSession.shared.data(for: request)

        return .result()
    }
}
