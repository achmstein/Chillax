namespace Chillax.Notification.API.Model;

public class NotificationSubscription
{
    public int Id { get; set; }
    public required string UserId { get; set; }
    public required string FcmToken { get; set; }
    public SubscriptionType Type { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public enum SubscriptionType
{
    RoomAvailability = 1,
    AdminOrderNotification = 2,
    ServiceRequests = 3
}
