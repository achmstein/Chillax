using Chillax.EventBus.Abstractions;
using Chillax.Notification.API.IntegrationEvents.Events;
using Chillax.Notification.API.Model;
using Chillax.Notification.API.Services;

namespace Chillax.Notification.API.IntegrationEvents.EventHandling;

public class OrderSubmittedIntegrationEventHandler(
    NotificationContext context,
    IFcmService fcmService,
    ILogger<OrderSubmittedIntegrationEventHandler> logger) : IIntegrationEventHandler<OrderStatusChangedToSubmittedIntegrationEvent>
{
    public async Task Handle(OrderStatusChangedToSubmittedIntegrationEvent @event)
    {
        logger.LogInformation("Handling OrderStatusChangedToSubmittedIntegrationEvent for order {OrderId} from {BuyerName}",
            @event.OrderId, @event.BuyerName);

        // Get all admin order notification subscriptions
        var subscriptions = await context.Subscriptions
            .Where(s => s.Type == SubscriptionType.AdminOrderNotification)
            .ToListAsync();

        if (subscriptions.Count == 0)
        {
            logger.LogInformation("No admin subscriptions found for order notifications");
            return;
        }

        logger.LogInformation("Found {Count} admin subscriptions to notify", subscriptions.Count);

        // Send notifications to all admin subscribers
        var fcmTokens = subscriptions.Select(s => s.FcmToken).ToList();
        var successCount = await fcmService.SendBatchNotificationsAsync(
            fcmTokens,
            "New Order!",
            $"Order #{@event.OrderId} from {(@event.BuyerName ?? "Customer")}",
            new Dictionary<string, string>
            {
                { "type", "new_order" },
                { "orderId", @event.OrderId.ToString() },
                { "buyerName", @event.BuyerName ?? "" },
                { "buyerId", @event.BuyerIdentityGuid ?? "" }
            });

        logger.LogInformation("Sent {SuccessCount}/{TotalCount} admin notifications successfully",
            successCount, subscriptions.Count);

        // Note: Admin subscriptions are persistent - do NOT delete them
    }
}
