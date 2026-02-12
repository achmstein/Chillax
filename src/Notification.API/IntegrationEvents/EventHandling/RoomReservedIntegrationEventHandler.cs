using Chillax.EventBus.Abstractions;
using Chillax.Notification.API.Hubs;
using Chillax.Notification.API.IntegrationEvents.Events;
using Chillax.Notification.API.Localization;
using Chillax.Notification.API.Model;
using Chillax.Notification.API.Services;
using Microsoft.AspNetCore.SignalR;

namespace Chillax.Notification.API.IntegrationEvents.EventHandling;

public class RoomReservedIntegrationEventHandler(
    NotificationContext context,
    IFcmService fcmService,
    IHubContext<NotificationHub> hubContext,
    ILogger<RoomReservedIntegrationEventHandler> logger) : IIntegrationEventHandler<RoomReservedIntegrationEvent>
{
    public async Task Handle(RoomReservedIntegrationEvent @event)
    {
        logger.LogInformation("Handling RoomReservedIntegrationEvent: ReservationId={ReservationId}, Room={RoomName}, Customer={CustomerName}",
            @event.ReservationId, @event.RoomName.En, @event.CustomerName);

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

        var customerDisplay = @event.CustomerName ?? "Customer";
        var totalSuccess = 0;

        // Group by language and send localized notifications
        foreach (var group in subscriptions.GroupBy(s => s.PreferredLanguage))
        {
            var lang = group.Key;
            var tokens = group.Select(s => s.FcmToken).ToList();
            var title = NotificationMessages.NewReservationTitle.GetText(lang);
            var body = NotificationMessages.NewReservationBody(customerDisplay, @event.RoomName, lang).GetText(lang);

            var successCount = await fcmService.SendBatchNotificationsAsync(
                tokens,
                title,
                body,
                new Dictionary<string, string>
                {
                    { "type", "new_reservation" },
                    { "reservationId", @event.ReservationId.ToString() },
                    { "roomId", @event.RoomId.ToString() },
                    { "roomName", @event.RoomName.GetText(lang) },
                    { "customerName", @event.CustomerName ?? "" },
                    { "customerId", @event.CustomerId ?? "" }
                });

            totalSuccess += successCount;
            logger.LogInformation("Sent {SuccessCount}/{TotalCount} notifications in {Lang}",
                successCount, tokens.Count, lang);
        }

        logger.LogInformation("Sent {SuccessCount}/{TotalCount} admin reservation notifications successfully",
            totalSuccess, subscriptions.Count);

        // Note: Admin subscriptions are persistent - do NOT delete them

        // Broadcast via SignalR to connected clients
        await hubContext.Clients.Group("rooms").SendAsync("RoomStatusChanged", new
        {
            type = "room_reserved",
            roomId = @event.RoomId,
            reservationId = @event.ReservationId
        });
    }
}
