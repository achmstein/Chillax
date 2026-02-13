using Chillax.EventBus.Abstractions;
using Chillax.Notification.API.Hubs;
using Chillax.Notification.API.IntegrationEvents.Events;
using Microsoft.AspNetCore.SignalR;

namespace Chillax.Notification.API.IntegrationEvents.EventHandling;

public class SessionStartedIntegrationEventHandler(
    IHubContext<NotificationHub> hubContext,
    ILogger<SessionStartedIntegrationEventHandler> logger) : IIntegrationEventHandler<SessionStartedIntegrationEvent>
{
    public async Task Handle(SessionStartedIntegrationEvent @event)
    {
        logger.LogInformation("Handling SessionStartedIntegrationEvent: ReservationId={ReservationId}, RoomId={RoomId}",
            @event.ReservationId, @event.RoomId);

        // Broadcast via SignalR to rooms group so client screens refresh
        await hubContext.Clients.Group("rooms").SendAsync("RoomStatusChanged", new
        {
            type = "session_started",
            roomId = @event.RoomId,
            reservationId = @event.ReservationId
        });

        // Also notify the specific customer if they're connected
        if (!string.IsNullOrEmpty(@event.CustomerId))
        {
            await hubContext.Clients.Group($"user:{@event.CustomerId}").SendAsync("RoomStatusChanged", new
            {
                type = "session_started",
                roomId = @event.RoomId,
                reservationId = @event.ReservationId
            });
        }
    }
}
