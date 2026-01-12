using Chillax.EventBus.Abstractions;
using Chillax.Notification.API.IntegrationEvents.Events;
using Chillax.Notification.API.Model;
using Chillax.Notification.API.Services;

namespace Chillax.Notification.API.IntegrationEvents.EventHandling;

public class RoomBecameAvailableIntegrationEventHandler(
    NotificationContext context,
    IFcmService fcmService,
    ILogger<RoomBecameAvailableIntegrationEventHandler> logger) : IIntegrationEventHandler<RoomBecameAvailableIntegrationEvent>
{
    public async Task Handle(RoomBecameAvailableIntegrationEvent @event)
    {
        logger.LogInformation("Handling RoomBecameAvailableIntegrationEvent for room {RoomId}: {RoomName}",
            @event.RoomId, @event.RoomName);

        // Get all room availability subscriptions
        var subscriptions = await context.Subscriptions
            .Where(s => s.Type == SubscriptionType.RoomAvailability)
            .ToListAsync();

        if (subscriptions.Count == 0)
        {
            logger.LogInformation("No subscriptions found for room availability notifications");
            return;
        }

        logger.LogInformation("Found {Count} subscriptions to notify", subscriptions.Count);

        // Send notifications to all subscribers
        var fcmTokens = subscriptions.Select(s => s.FcmToken).ToList();
        var successCount = await fcmService.SendBatchNotificationsAsync(
            fcmTokens,
            "Room Available!",
            $"{@event.RoomName} is now available. Book now!",
            new Dictionary<string, string>
            {
                { "type", "room_available" },
                { "roomId", @event.RoomId.ToString() },
                { "roomName", @event.RoomName }
            });

        logger.LogInformation("Sent {SuccessCount}/{TotalCount} notifications successfully",
            successCount, subscriptions.Count);

        // Delete all subscriptions (one-time notification)
        context.Subscriptions.RemoveRange(subscriptions);
        await context.SaveChangesAsync();

        logger.LogInformation("Deleted {Count} subscriptions after notification", subscriptions.Count);
    }
}
