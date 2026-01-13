using Chillax.Notification.API.IntegrationEvents.Events;
using Chillax.Notification.API.Model;
using Chillax.Notification.API.Services;

namespace Chillax.Notification.API.IntegrationEvents.EventHandling;

public class ServiceRequestCreatedIntegrationEventHandler(
    NotificationContext context,
    IFcmService fcmService,
    ILogger<ServiceRequestCreatedIntegrationEventHandler> logger) :
    IIntegrationEventHandler<ServiceRequestCreatedIntegrationEvent>
{
    public async Task Handle(ServiceRequestCreatedIntegrationEvent @event)
    {
        logger.LogInformation(
            "Handling ServiceRequestCreatedIntegrationEvent: {RequestType} for room {RoomName}",
            @event.RequestType, @event.RoomName);

        // Get all staff subscribed to ServiceRequests
        var subscriptions = await context.Subscriptions
            .Where(s => s.Type == SubscriptionType.ServiceRequests)
            .ToListAsync();

        if (subscriptions.Count == 0)
        {
            logger.LogWarning("No staff subscribed to service requests");
            return;
        }

        // Build notification content based on request type
        var (title, body) = GetNotificationContent(@event);

        // Send FCM notifications to all subscribed staff
        var fcmTokens = subscriptions.Select(s => s.FcmToken).ToList();
        var successCount = await fcmService.SendBatchNotificationsAsync(
            fcmTokens,
            title,
            body,
            new Dictionary<string, string>
            {
                { "type", "service_request" },
                { "requestId", @event.RequestId.ToString() },
                { "requestType", @event.RequestType.ToString() },
                { "roomId", @event.RoomId.ToString() },
                { "roomName", @event.RoomName }
            });

        logger.LogInformation(
            "Sent {SuccessCount}/{TotalCount} service request notifications for {RequestType} in {RoomName}",
            successCount, subscriptions.Count, @event.RequestType, @event.RoomName);
    }

    private static (string title, string body) GetNotificationContent(ServiceRequestCreatedIntegrationEvent @event)
    {
        return @event.RequestType switch
        {
            ServiceRequestType.CallWaiter => (
                "Waiter Needed",
                $"{@event.RoomName} - {@event.UserName} is calling for a waiter"),
            ServiceRequestType.ControllerChange => (
                "Controller Request",
                $"{@event.RoomName} - {@event.UserName} needs a different controller"),
            ServiceRequestType.ReceiptToPay => (
                "Bill Requested",
                $"{@event.RoomName} - {@event.UserName} wants to pay"),
            _ => (
                "Service Request",
                $"{@event.RoomName} - {@event.UserName} needs assistance")
        };
    }
}
