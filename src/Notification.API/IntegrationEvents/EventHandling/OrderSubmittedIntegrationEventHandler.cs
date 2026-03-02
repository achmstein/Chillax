using Chillax.EventBus.Abstractions;
using Chillax.Notification.API.Hubs;
using Chillax.Notification.API.IntegrationEvents.Events;
using Chillax.Notification.API.Localization;
using Chillax.Notification.API.Model;
using Chillax.Notification.API.Services;
using Microsoft.AspNetCore.SignalR;

namespace Chillax.Notification.API.IntegrationEvents.EventHandling;

public class OrderSubmittedIntegrationEventHandler(
    NotificationContext context,
    IFcmService fcmService,
    IHubContext<NotificationHub> hubContext,
    ILogger<OrderSubmittedIntegrationEventHandler> logger) : IIntegrationEventHandler<OrderStatusChangedToSubmittedIntegrationEvent>
{
    public async Task Handle(OrderStatusChangedToSubmittedIntegrationEvent @event)
    {
        logger.LogInformation("Handling OrderStatusChangedToSubmittedIntegrationEvent for order {OrderId} from {BuyerName}",
            @event.OrderId, @event.BuyerName);

        // Get admin order notification subscriptions for this branch
        var subscriptions = await context.Subscriptions
            .Where(s => s.Type == SubscriptionType.AdminOrderNotification
                && (s.BranchId == null || s.BranchId == @event.BranchId))
            .ToListAsync();

        if (subscriptions.Count == 0)
        {
            logger.LogInformation("No admin subscriptions found for order notifications");
            return;
        }

        logger.LogInformation("Found {Count} admin subscriptions to notify", subscriptions.Count);

        var buyerName = @event.BuyerName ?? "Customer";
        var totalSuccess = 0;

        // Group by language and send localized notifications
        foreach (var group in subscriptions.GroupBy(s => s.PreferredLanguage))
        {
            var lang = group.Key;
            var tokens = group.Select(s => s.FcmToken).ToList();
            var title = NotificationMessages.NewOrderTitle.GetText(lang);
            var body = NotificationMessages.NewOrderBody(@event.OrderId, buyerName).GetText(lang);

            var successCount = await fcmService.SendBatchNotificationsAsync(
                tokens,
                title,
                body,
                new Dictionary<string, string>
                {
                    { "type", "new_order" },
                    { "orderId", @event.OrderId.ToString() },
                    { "buyerName", @event.BuyerName ?? "" },
                    { "buyerId", @event.BuyerIdentityGuid ?? "" }
                });

            totalSuccess += successCount;
            logger.LogInformation("Sent {SuccessCount}/{TotalCount} notifications in {Lang}",
                successCount, tokens.Count, lang);
        }

        logger.LogInformation("Sent {SuccessCount}/{TotalCount} admin notifications successfully",
            totalSuccess, subscriptions.Count);

        // Note: Admin subscriptions are persistent - do NOT delete them

        // Broadcast via SignalR to admin group and the buyer's personal group
        await hubContext.Clients.Group("admin").SendAsync("OrderStatusChanged", new
        {
            type = "order_submitted",
            orderId = @event.OrderId,
            buyerName = @event.BuyerName
        });

        if (!string.IsNullOrEmpty(@event.BuyerIdentityGuid))
        {
            await hubContext.Clients.Group($"user:{@event.BuyerIdentityGuid}").SendAsync("OrderStatusChanged", new
            {
                type = "order_submitted",
                orderId = @event.OrderId
            });
        }
    }
}
