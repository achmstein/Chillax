using Chillax.EventBus.Abstractions;
using Chillax.Notification.API.Hubs;
using Chillax.Notification.API.IntegrationEvents.Events;
using Chillax.Notification.API.Localization;
using Chillax.Notification.API.Model;
using Chillax.Notification.API.Services;
using Microsoft.AspNetCore.SignalR;

namespace Chillax.Notification.API.IntegrationEvents.EventHandling;

public class ReservationCancelledIntegrationEventHandler(
    NotificationContext context,
    IFcmService fcmService,
    IHubContext<NotificationHub> hubContext,
    ILogger<ReservationCancelledIntegrationEventHandler> logger) : IIntegrationEventHandler<ReservationCancelledIntegrationEvent>
{
    public async Task Handle(ReservationCancelledIntegrationEvent @event)
    {
        logger.LogInformation("Handling ReservationCancelledIntegrationEvent: ReservationId={ReservationId}, Room={RoomName}, Customer={CustomerName}",
            @event.ReservationId, @event.RoomName.En, @event.CustomerName);

        // Get all admin reservation notification subscriptions
        var subscriptions = await context.Subscriptions
            .Where(s => s.Type == SubscriptionType.AdminReservationNotification)
            .ToListAsync();

        if (subscriptions.Count == 0)
        {
            logger.LogInformation("No admin subscriptions found for reservation cancellation notifications");
            return;
        }

        logger.LogInformation("Found {Count} admin subscriptions to notify about cancellation", subscriptions.Count);

        var customerDisplay = @event.CustomerName ?? "Customer";
        var totalSuccess = 0;

        // Group by language and send localized notifications
        foreach (var group in subscriptions.GroupBy(s => s.PreferredLanguage))
        {
            var lang = group.Key;
            var tokens = group.Select(s => s.FcmToken).ToList();
            var title = NotificationMessages.ReservationCancelledTitle.GetText(lang);
            var body = NotificationMessages.ReservationCancelledBody(customerDisplay, @event.RoomName, lang).GetText(lang);

            var successCount = await fcmService.SendBatchNotificationsAsync(
                tokens,
                title,
                body,
                new Dictionary<string, string>
                {
                    { "type", "reservation_cancelled" },
                    { "reservationId", @event.ReservationId.ToString() },
                    { "roomId", @event.RoomId.ToString() },
                    { "roomName", @event.RoomName.GetText(lang) },
                    { "customerName", @event.CustomerName ?? "" },
                    { "customerId", @event.CustomerId ?? "" }
                });

            totalSuccess += successCount;
            logger.LogInformation("Sent {SuccessCount}/{TotalCount} cancellation notifications in {Lang}",
                successCount, tokens.Count, lang);
        }

        logger.LogInformation("Sent {SuccessCount}/{TotalCount} admin cancellation notifications successfully",
            totalSuccess, subscriptions.Count);

        // Broadcast via SignalR to connected clients
        await hubContext.Clients.Group("rooms").SendAsync("RoomStatusChanged", new
        {
            type = "reservation_cancelled",
            roomId = @event.RoomId,
            reservationId = @event.ReservationId
        });
    }
}
