import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Set up notification delegate for interactive actions
    UNUserNotificationCenter.current().delegate = self

    // Register notification categories (action buttons)
    SessionNotificationHelper.shared.registerCategories()

    // Set up method channels
    if let controller = window?.rootViewController as? FlutterViewController {
      SessionNotificationHelper.shared.setupChannel(with: controller)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - Remote notifications (FCM data messages)

  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    let type = userInfo["type"] as? String

    if type == "session_ended" {
      SessionNotificationHelper.shared.dismiss()
    }

    // Let Flutter's firebase_messaging plugin handle everything else
    super.application(application, didReceiveRemoteNotification: userInfo,
                      fetchCompletionHandler: completionHandler)
  }

  // MARK: - UNUserNotificationCenterDelegate

  /// Show notifications even when app is in the foreground
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .sound, .badge])
  }

  /// Handle notification action button taps
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let actionIdentifier = response.actionIdentifier

    switch actionIdentifier {
    case UNNotificationDefaultActionIdentifier:
      // User tapped the notification itself — navigate to rooms
      SessionNotificationHelper.shared.navigateTo(route: "/rooms")

    case UNNotificationDismissActionIdentifier:
      // User dismissed the notification
      break

    default:
      // Custom action button tapped
      SessionNotificationHelper.shared.handleAction(identifier: actionIdentifier)
    }

    completionHandler()
  }
}
