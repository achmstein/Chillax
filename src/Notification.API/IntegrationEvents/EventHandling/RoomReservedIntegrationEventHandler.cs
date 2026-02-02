using Chillax.EventBus.Abstractions;
using Chillax.Notification.API.IntegrationEvents.Events;
using Chillax.Notification.API.Model;
using Chillax.Notification.API.Services;

namespace Chillax.Notification.API.IntegrationEvents.EventHandling;

public class RoomReservedIntegrationEventHandler(
    NotificationContext context,
    IFcmService fcmService,
    ILogger<RoomReservedIntegrationEventHandler> logger) : IIntegrationEventHandler<RoomReservedIntegrationEvent>
{
    public async Task Handle(RoomReservedIntegrationEvent @event)
    {
        logger.LogInformation("Handling RoomReservedIntegrationEvent: ReservationId={ReservationId}, Room={RoomName}, Customer={CustomerName}",
            @event.ReservationId, @event.RoomName, @event.CustomerName);

        // Get all admin reservation notification subscriptions
        var subscriptions = await context.Subscriptions
            .Where(s => s.Type == SubscriptionType.AdminReservationNotification)
            .ToListAsync();

        if (subscriptions.Count == 0)
        {
            logger.LogInformation("No admin subscriptions found for reservation notifications");
            return;
        }

        logger.LogInformation("Found {Count} admin subscriptions to notify about reservation", subscriptions.Count);

        // Send notifications to all admin subscribers
        var fcmTokens = subscriptions.Select(s => s.FcmToken).ToList();
        var customerDisplay = @event.CustomerName ?? "Customer";

        var successCount = await fcmService.SendBatchNotificationsAsync(
            fcmTokens,
            "New Reservation!",
            $"{customerDisplay} reserved {@event.RoomName}",
            new Dictionary<string, string>
            {
                { "type", "new_reservation" },
                { "reservationId", @event.ReservationId.ToString() },
                { "roomId", @event.RoomId.ToString() },
                { "roomName", @event.RoomName },
                { "customerName", @event.CustomerName ?? "" },
                { "customerId", @event.CustomerId ?? "" }
            });

        logger.LogInformation("Sent {SuccessCount}/{TotalCount} admin reservation notifications successfully",
            successCount, subscriptions.Count);

        // Note: Admin subscriptions are persistent - do NOT delete them
    }
}
