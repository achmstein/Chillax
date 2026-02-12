using Chillax.EventBus.Abstractions;
using Chillax.Notification.API.Hubs;
using Chillax.Notification.API.IntegrationEvents.Events;
using Chillax.Notification.API.Localization;
using Chillax.Notification.API.Model;
using Chillax.Notification.API.Services;
using Microsoft.AspNetCore.SignalR;

namespace Chillax.Notification.API.IntegrationEvents.EventHandling;

public class RoomBecameAvailableIntegrationEventHandler(
    NotificationContext context,
    IFcmService fcmService,
    IHubContext<NotificationHub> hubContext,
    ILogger<RoomBecameAvailableIntegrationEventHandler> logger) : IIntegrationEventHandler<RoomBecameAvailableIntegrationEvent>
{
    public async Task Handle(RoomBecameAvailableIntegrationEvent @event)
    {
        logger.LogInformation("Handling RoomBecameAvailableIntegrationEvent for room {RoomId}: {RoomName}",
            @event.RoomId, @event.RoomName.En);

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

        // Group by language and send localized notifications
        var totalSuccess = 0;
        foreach (var group in subscriptions.GroupBy(s => s.PreferredLanguage))
        {
            var lang = group.Key;
            var tokens = group.Select(s => s.FcmToken).ToList();
            var title = NotificationMessages.RoomAvailableTitle.GetText(lang);
            var body = NotificationMessages.RoomAvailableBody(@event.RoomName, lang).GetText(lang);

            var successCount = await fcmService.SendBatchNotificationsAsync(
                tokens,
                title,
                body,
                new Dictionary<string, string>
                {
                    { "type", "room_available" },
                    { "roomId", @event.RoomId.ToString() },
                    { "roomName", @event.RoomName.GetText(lang) }
                });

            totalSuccess += successCount;
            logger.LogInformation("Sent {SuccessCount}/{TotalCount} notifications in {Lang}",
                successCount, tokens.Count, lang);
        }

        logger.LogInformation("Sent {SuccessCount}/{TotalCount} total notifications successfully",
            totalSuccess, subscriptions.Count);

        // Delete all subscriptions (one-time notification)
        context.Subscriptions.RemoveRange(subscriptions);
        await context.SaveChangesAsync();

        logger.LogInformation("Deleted {Count} subscriptions after notification", subscriptions.Count);

        // Broadcast via SignalR to connected clients
        await hubContext.Clients.Group("rooms").SendAsync("RoomStatusChanged", new
        {
            type = "room_available",
            roomId = @event.RoomId
        });
    }
}
