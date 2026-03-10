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
    static let actionSwitchMode = "ACTION_SWITCH_MODE"

    static let cooldownSeconds: TimeInterval = 30

    private var sessionChannel: FlutterMethodChannel?
    private var navigationChannel: FlutterMethodChannel?

    private var lastRoomName = ""
    private var lastDuration = ""
    private var lastStartTimeMs: Int64?
    private var lastLocale = "en"
    private var lastPlayerMode = "Single"

    // Cooldowns: action identifier -> expiry Date
    private var cooldowns: [String: Date] = [:]
    private var cooldownTimer: Timer?

    private override init() {
        super.init()
    }

    /// Register notification categories with interactive actions
    func registerCategories() {
        updateCategoryActions(playerMode: "Single", locale: "en")
    }

    /// Update category actions based on current player mode and locale
    private func updateCategoryActions(playerMode: String, locale: String) {
        let isArabic = locale == "ar"

        let waiterAction = UNNotificationAction(
            identifier: SessionNotificationHelper.actionCallWaiter,
            title: getActionTitle(
                action: SessionNotificationHelper.actionCallWaiter,
                defaultLabel: isArabic ? "الويتر" : "Waiter"
            ),
            options: []
        )

        let controllerAction = UNNotificationAction(
            identifier: SessionNotificationHelper.actionController,
            title: getActionTitle(
                action: SessionNotificationHelper.actionController,
                defaultLabel: isArabic ? "دراع" : "Controller"
            ),
            options: []
        )

        let switchModeLabel: String
        if playerMode == "Multi" {
            switchModeLabel = isArabic ? "سنجل" : "Single"
        } else {
            switchModeLabel = isArabic ? "مالتي" : "Multi"
        }

        let switchModeAction = UNNotificationAction(
            identifier: SessionNotificationHelper.actionSwitchMode,
            title: getActionTitle(
                action: SessionNotificationHelper.actionSwitchMode,
                defaultLabel: switchModeLabel
            ),
            options: []
        )

        let category = UNNotificationCategory(
            identifier: SessionNotificationHelper.categoryId,
            actions: [waiterAction, controllerAction, switchModeAction],
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
                let playerMode = args["playerMode"] as? String ?? "Single"
                self.show(roomName: roomName, duration: duration, startTimeMs: startTimeMs, locale: locale, playerMode: playerMode)
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
    func show(roomName: String, duration: String, startTimeMs: Int64?, locale: String, playerMode: String) {
        lastRoomName = roomName
        lastDuration = duration
        lastStartTimeMs = startTimeMs
        lastLocale = locale
        lastPlayerMode = playerMode

        // Update category actions to reflect current player mode and locale
        updateCategoryActions(playerMode: playerMode, locale: locale)

        let content = UNMutableNotificationContent()
        content.title = roomName
        content.categoryIdentifier = SessionNotificationHelper.categoryId
        content.sound = nil // Silent — ongoing session notification

        // Show elapsed time in the body
        if let startMs = startTimeMs {
            let startDate = Date(timeIntervalSince1970: Double(startMs) / 1000.0)
            let elapsed = Date().timeIntervalSince(startDate)
            let hours = Int(elapsed) / 3600
            let minutes = (Int(elapsed) % 3600) / 60
            let seconds = Int(elapsed) % 60
            content.body = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            content.body = duration
        }

        // Use a fixed identifier so it replaces the previous notification
        let request = UNNotificationRequest(
            identifier: SessionNotificationHelper.notificationId,
            content: content,
            trigger: nil // Deliver immediately
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to show session notification: \(error)")
            }
        }

        // Start periodic updates to keep the elapsed time current
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
            return // Still in cooldown
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
        case SessionNotificationHelper.actionSwitchMode:
            actionId = lastPlayerMode == "Multi" ? "switch_to_single" : "switch_to_multi"
        default:
            return
        }

        // Forward to Flutter
        DispatchQueue.main.async { [weak self] in
            self?.sessionChannel?.invokeMethod("onAction", arguments: actionId)
        }

        // Refresh notification to show cooldown feedback
        refresh()
        scheduleCooldownUpdates()
    }

    /// Navigate to a route via Flutter
    func navigateTo(route: String) {
        DispatchQueue.main.async { [weak self] in
            self?.navigationChannel?.invokeMethod("navigateTo", arguments: route)
        }
    }

    // MARK: - Private

    private func refresh() {
        show(roomName: lastRoomName, duration: lastDuration, startTimeMs: lastStartTimeMs, locale: lastLocale, playerMode: lastPlayerMode)
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
        // Use a 1-second timer to update action labels during cooldown
        // (iOS doesn't support dynamic action labels on delivered notifications,
        // so we refresh the notification to show updated body text instead)
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
