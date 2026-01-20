using Chillax.EventBus.Abstractions;
using Chillax.Rooms.API.Application.IntegrationEvents.Events;
using Chillax.Rooms.Domain.AggregatesModel.ReservationAggregate;
using Chillax.Rooms.Domain.Events;
using MediatR;
using Microsoft.Extensions.Logging;

namespace Chillax.Rooms.API.Application.DomainEventHandlers;

public class ReservationCancelledDomainEventHandler : INotificationHandler<ReservationCancelledDomainEvent>
{
    private readonly IEventBus _eventBus;
    private readonly ILogger<ReservationCancelledDomainEventHandler> _logger;

    public ReservationCancelledDomainEventHandler(
        IEventBus eventBus,
        ILogger<ReservationCancelledDomainEventHandler> logger)
    {
        _eventBus = eventBus;
        _logger = logger;
    }

    public async Task Handle(ReservationCancelledDomainEvent notification, CancellationToken cancellationToken)
    {
        var reservation = notification.Reservation;

        _logger.LogInformation("Reservation cancelled: {ReservationId}, Previous status: {PreviousStatus}",
            reservation.Id, notification.PreviousStatus);

        // If was active, publish room available event
        if (notification.PreviousStatus == ReservationStatus.Active)
        {
            var roomAvailableEvent = new RoomBecameAvailableIntegrationEvent(
                reservation.RoomId,
                reservation.Room?.Name ?? $"Room {reservation.RoomId}");

            await _eventBus.PublishAsync(roomAvailableEvent);
        }
    }
}
