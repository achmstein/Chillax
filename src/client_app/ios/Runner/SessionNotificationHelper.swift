import Foundation
import UserNotifications
import Flutter

class SessionNotificationHelper: NSObject {
    static let shared = SessionNotificationHelper()

    static let channelName = "com.chillax.client/session_notification"
    static let navigationChannelName = "com.chillax.client/navigation"
    static let notificationId = "session_notification"

    // Notification category & action identifiers
    static let categoryId = "SESSION_CONTROLS"
    static let actionCallWaiter = "ACTION_CALL_WAITER"
    static let actionController = "ACTION_CONTROLLER"
    static let actionOrderDrink1 = "ACTION_ORDER_DRINK_1"
    static let actionOrderDrink2 = "ACTION_ORDER_DRINK_2"

    static let cooldownSeconds: TimeInterval = 30

    private var sessionChannel: FlutterMethodChannel?
    private var navigationChannel: FlutterMethodChannel?

    private var lastRoomName = ""
    private var lastDuration = ""
    private var lastStartTimeMs: Int64?
    private var lastLocale = "en"
    private var lastDrink1Name: String?
    private var lastDrink2Name: String?

    // Cooldowns: action identifier -> expiry Date
    private var cooldowns: [String: Date] = [:]
    private var cooldownTimer: Timer?

    private override init() {
        super.init()
    }

    /// Register notification categories with interactive actions
    func registerCategories() {
        updateCategoryActions(locale: "en", drink1Name: nil, drink2Name: nil)
    }

    /// Update category actions based on current locale and drink names
    private func updateCategoryActions(locale: String, drink1Name: String?, drink2Name: String?) {
        let isArabic = locale == "ar"

        var actions: [UNNotificationAction] = []

        let waiterAction = UNNotificationAction(
            identifier: SessionNotificationHelper.actionCallWaiter,
            title: getActionTitle(
                action: SessionNotificationHelper.actionCallWaiter,
                defaultLabel: isArabic ? "الويتر" : "Waiter"
            ),
            options: []
        )
        actions.append(waiterAction)

        let controllerAction = UNNotificationAction(
            identifier: SessionNotificationHelper.actionController,
            title: getActionTitle(
                action: SessionNotificationHelper.actionController,
                defaultLabel: isArabic ? "دراع" : "Controller"
            ),
            options: []
        )
        actions.append(controllerAction)

        if let name = drink1Name {
            let drink1Action = UNNotificationAction(
                identifier: SessionNotificationHelper.actionOrderDrink1,
                title: getActionTitle(
                    action: SessionNotificationHelper.actionOrderDrink1,
                    defaultLabel: name
                ),
                options: []
            )
            actions.append(drink1Action)
        }

        if let name = drink2Name {
            let drink2Action = UNNotificationAction(
                identifier: SessionNotificationHelper.actionOrderDrink2,
                title: getActionTitle(
                    action: SessionNotificationHelper.actionOrderDrink2,
                    defaultLabel: name
                ),
                options: []
            )
            actions.append(drink2Action)
        }

        let category = UNNotificationCategory(
            identifier: SessionNotificationHelper.categoryId,
            actions: actions,
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    /// Set up the method channel for Flutter communication
    func setupChannel(with controller: FlutterViewController) {
        sessionChannel = FlutterMethodChannel(
            name: SessionNotificationHelper.channelName,
            binaryMessenger: controller.binaryMessenger
        )

        navigationChannel = FlutterMethodChannel(
            name: SessionNotificationHelper.navigationChannelName,
            binaryMessenger: controller.binaryMessenger
        )

        sessionChannel?.setMethodCallHandler { [weak self] call, result in
            guard let self = self else {
                result(FlutterMethodNotImplemented)
                return
            }

            switch call.method {
            case "show":
                guard let args = call.arguments as? [String: Any] else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                    return
                }
                let roomName = args["roomName"] as? String ?? ""
                let duration = args["duration"] as? String ?? ""
                let startTimeMs = args["startTimeMs"] as? Int64
                let locale = args["locale"] as? String ?? "en"
                let drink1Name = args["drink1Name"] as? String
                let drink2Name = args["drink2Name"] as? String
                self.show(roomName: roomName, duration: duration, startTimeMs: startTimeMs, locale: locale,
                          drink1Name: drink1Name, drink2Name: drink2Name)
                result(nil)

            case "dismiss":
                self.dismiss()
                result(nil)

            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    /// Show or update the session notification
    func show(roomName: String, duration: String, startTimeMs: Int64?, locale: String,
              drink1Name: String? = nil, drink2Name: String? = nil) {
        lastRoomName = roomName
        lastDuration = duration
        lastStartTimeMs = startTimeMs
        lastLocale = locale
        lastDrink1Name = drink1Name
        lastDrink2Name = drink2Name

        // Update category actions to reflect current drinks and locale
        updateCategoryActions(locale: locale, drink1Name: drink1Name, drink2Name: drink2Name)

        let content = UNMutableNotificationContent()
        content.title = "Chillax"
        content.categoryIdentifier = SessionNotificationHelper.categoryId
        content.sound = nil // Silent — ongoing session notification

        // Show room name with elapsed time
        if let startMs = startTimeMs {
            let startDate = Date(timeIntervalSince1970: Double(startMs) / 1000.0)
            let elapsed = Date().timeIntervalSince(startDate)
            let hours = Int(elapsed) / 3600
            let minutes = (Int(elapsed) % 3600) / 60
            let seconds = Int(elapsed) % 60
            let timer = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
            content.body = "\(roomName) · \(timer)"
        } else {
            content.body = roomName
        }

        let request = UNNotificationRequest(
            identifier: SessionNotificationHelper.notificationId,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to show session notification: \(error)")
            }
        }

        startPeriodicUpdate()
    }

    /// Dismiss the session notification
    func dismiss() {
        stopPeriodicUpdate()
        cooldowns.removeAll()

        UNUserNotificationCenter.current().removeDeliveredNotifications(
            withIdentifiers: [SessionNotificationHelper.notificationId]
        )
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [SessionNotificationHelper.notificationId]
        )
    }

    /// Handle a notification action response
    func handleAction(identifier: String) {
        let now = Date()

        // Check cooldown
        if let expiry = cooldowns[identifier], now < expiry {
            return
        }

        // Start cooldown
        cooldowns[identifier] = now.addingTimeInterval(SessionNotificationHelper.cooldownSeconds)

        // Map to Dart action ID
        let actionId: String
        switch identifier {
        case SessionNotificationHelper.actionCallWaiter:
            actionId = "call_waiter"
        case SessionNotificationHelper.actionController:
            actionId = "controller"
        case SessionNotificationHelper.actionOrderDrink1:
            actionId = "order_drink_1"
        case SessionNotificationHelper.actionOrderDrink2:
            actionId = "order_drink_2"
        default:
            return
        }

        // Forward to Flutter — Dart handles all actions (service requests via Dio, drinks via order API)
        // Falls back to native HTTP only when Flutter engine is dead (see sendDirectRequest)
        if sessionChannel != nil {
            DispatchQueue.main.async { [weak self] in
                self?.sessionChannel?.invokeMethod("onAction", arguments: actionId)
            }
        } else if actionId == "call_waiter" || actionId == "controller" {
            sendDirectRequest(actionId: actionId)
        }

        // Refresh notification to show cooldown feedback
        refresh()
        scheduleCooldownUpdates()
    }

    /// Send a service request directly via HTTP when Flutter engine isn't available
    private func sendDirectRequest(actionId: String) {
        let defaults = UserDefaults.standard
        guard let accessToken = defaults.string(forKey: "flutter.active_session_access_token"),
              defaults.object(forKey: "flutter.active_session_id") != nil else {
            return
        }

        let sessionId = defaults.integer(forKey: "flutter.active_session_id")
        let roomId = defaults.integer(forKey: "flutter.active_session_room_id")
        let branchId = defaults.integer(forKey: "flutter.active_session_branch_id")
        let roomNameEn = defaults.string(forKey: "flutter.active_session_room_name_en") ?? ""
        let roomNameAr = defaults.string(forKey: "flutter.active_session_room_name_ar")

        let requestType: Int
        switch actionId {
        case "call_waiter": requestType = 1
        case "controller": requestType = 2
        default: return
        }

        var roomNameJson: [String: Any] = ["en": roomNameEn]
        if let ar = roomNameAr { roomNameJson["ar"] = ar }

        let body: [String: Any] = [
            "sessionId": sessionId,
            "roomId": roomId,
            "roomName": roomNameJson,
            "requestType": requestType
        ]

        let baseUrl = defaults.string(forKey: "flutter.notifications_api_url")
            ?? "https://chillax.site/notifications-api/"
        guard let url = URL(string: "\(baseUrl)service-requests?api-version=1.0"),
              let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        if branchId != 0 {
            request.setValue("\(branchId)", forHTTPHeaderField: "X-Branch-Id")
        }
        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { _, _, _ in }.resume()
    }

    /// Navigate to a route via Flutter
    func navigateTo(route: String) {
        DispatchQueue.main.async { [weak self] in
            self?.navigationChannel?.invokeMethod("navigateTo", arguments: route)
        }
    }

    // MARK: - Private

    private func refresh() {
        show(roomName: lastRoomName, duration: lastDuration, startTimeMs: lastStartTimeMs, locale: lastLocale,
             drink1Name: lastDrink1Name, drink2Name: lastDrink2Name)
    }

    private func startPeriodicUpdate() {
        stopPeriodicUpdate()
        cooldownTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    private func stopPeriodicUpdate() {
        cooldownTimer?.invalidate()
        cooldownTimer = nil
    }

    private func scheduleCooldownUpdates() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            let now = Date()
            let hasActiveCooldown = self.cooldowns.values.contains { now < $0 }
            if hasActiveCooldown {
                self.refresh()
            } else {
                timer.invalidate()
                self.refresh()
            }
        }
    }

    private func getActionTitle(action: String, defaultLabel: String) -> String {
        let now = Date()
        guard let expiry = cooldowns[action], now < expiry else {
            return defaultLabel
        }
        let remaining = Int(expiry.timeIntervalSince(now))
        return "✓ \(remaining)s"
    }
}
