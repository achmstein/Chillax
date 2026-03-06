namespace Chillax.Notification.API.Services;

public interface IFcmService
{
    Task<bool> SendNotificationAsync(string fcmToken, string title, string body, Dictionary<string, string>? data = null);
    Task<int> SendBatchNotificationsAsync(IEnumerable<string> fcmTokens, string title, string body, Dictionary<string, string>? data = null);
    Task<int> SendBatchDataMessagesAsync(IEnumerable<string> fcmTokens, Dictionary<string, string> data);
}
