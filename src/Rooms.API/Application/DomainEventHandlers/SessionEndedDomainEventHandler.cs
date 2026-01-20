using Chillax.EventBus.Abstractions;
using Chillax.Rooms.API.Application.IntegrationEvents.Events;
using Chillax.Rooms.Domain.Events;
using MediatR;
using Microsoft.Extensions.Logging;

namespace Chillax.Rooms.API.Application.DomainEventHandlers;

public class SessionEndedDomainEventHandler : INotificationHandler<SessionEndedDomainEvent>
{
    private readonly IEventBus _eventBus;
    private readonly ILogger<SessionEndedDomainEventHandler> _logger;

    public SessionEndedDomainEventHandler(
        IEventBus eventBus,
        ILogger<SessionEndedDomainEventHandler> logger)
    {
        _eventBus = eventBus;
        _logger = logger;
    }

    public async Task Handle(SessionEndedDomainEvent notification, CancellationToken cancellationToken)
    {
        var reservation = notification.Reservation;

        _logger.LogInformation("Session ended: {ReservationId}, Room: {RoomId}, Cost: {Cost}",
            reservation.Id, reservation.RoomId, reservation.TotalCost);

        // Publish room available event for notifications
        var roomAvailableEvent = new RoomBecameAvailableIntegrationEvent(
            reservation.RoomId,
            reservation.Room?.Name ?? $"Room {reservation.RoomId}");

        await _eventBus.PublishAsync(roomAvailableEvent);

        // Publish session completed event (for billing/loyalty)
        if (reservation.ActualStartTime.HasValue && reservation.EndTime.HasValue)
        {
            var duration = reservation.EndTime.Value - reservation.ActualStartTime.Value;
            var sessionCompletedEvent = new SessionCompletedIntegrationEvent(
                reservation.Id,
                reservation.CustomerId,
                reservation.RoomId,
                reservation.Room?.Name ?? $"Room {reservation.RoomId}",
                reservation.TotalCost ?? 0,
                reservation.ActualStartTime.Value,
                reservation.EndTime.Value,
                duration);

            await _eventBus.PublishAsync(sessionCompletedEvent);
        }
    }
}
