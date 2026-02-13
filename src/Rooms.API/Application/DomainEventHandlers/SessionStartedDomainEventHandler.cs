using Chillax.EventBus.Abstractions;
using Chillax.Rooms.API.Application.IntegrationEvents.Events;
using Chillax.Rooms.Domain.Events;
using Chillax.Rooms.Domain.SeedWork;
using MediatR;
using Microsoft.Extensions.Logging;

namespace Chillax.Rooms.API.Application.DomainEventHandlers;

public class SessionStartedDomainEventHandler : INotificationHandler<SessionStartedDomainEvent>
{
    private readonly IEventBus _eventBus;
    private readonly ILogger<SessionStartedDomainEventHandler> _logger;

    public SessionStartedDomainEventHandler(
        IEventBus eventBus,
        ILogger<SessionStartedDomainEventHandler> logger)
    {
        _eventBus = eventBus;
        _logger = logger;
    }

    public async Task Handle(SessionStartedDomainEvent notification, CancellationToken cancellationToken)
    {
        var reservation = notification.Reservation;

        _logger.LogInformation("Session started: ReservationId={ReservationId}, RoomId={RoomId}, Customer={CustomerName}",
            reservation.Id, reservation.RoomId, reservation.CustomerName ?? "Unknown");

        var roomName = reservation.Room?.Name ?? new LocalizedText($"Room {reservation.RoomId}");
        var sessionStartedEvent = new SessionStartedIntegrationEvent(
            reservation.Id,
            reservation.RoomId,
            roomName,
            reservation.CustomerId,
            reservation.CustomerName);

        await _eventBus.PublishAsync(sessionStartedEvent);
    }
}
