namespace Chillax.Notification.API.Services;

public interface IFcmService
{
    Task<bool> SendNotificationAsync(string fcmToken, string title, string body, Dictionary<string, string>? data = null);
    Task<int> SendBatchNotificationsAsync(IEnumerable<string> fcmTokens, string title, string body, Dictionary<string, string>? data = null);
    Task<int> SendBatchDataMessagesAsync(IEnumerable<string> fcmTokens, Dictionary<string, string> data);

    /// <summary>
    /// Send data-only messages to Android (native code handles notification display)
    /// but with APNs alert for iOS (since data-only is silent on iOS).
    /// Used for order reminders where Android needs full control over the notification.
    /// </summary>
    Task<int> SendBatchDataWithApnsAlertAsync(IEnumerable<string> fcmTokens, string title, string body, Dictionary<string, string> data);
}
