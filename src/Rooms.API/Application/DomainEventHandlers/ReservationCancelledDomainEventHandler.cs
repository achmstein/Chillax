using Chillax.EventBus.Abstractions;
using Chillax.Rooms.API.Application.IntegrationEvents.Events;
using Chillax.Rooms.Domain.AggregatesModel.ReservationAggregate;
using Chillax.Rooms.Domain.Events;
using Chillax.Rooms.Domain.SeedWork;
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
        var roomName = reservation.Room?.Name ?? new LocalizedText($"Room {reservation.RoomId}");

        _logger.LogInformation("Reservation cancelled: {ReservationId}, Previous status: {PreviousStatus}",
            reservation.Id, notification.PreviousStatus);

        // Notify admins about the cancellation
        var cancellationEvent = new ReservationCancelledIntegrationEvent(
            reservation.Id,
            reservation.RoomId,
            roomName,
            reservation.CustomerId,
            reservation.CustomerName);

        await _eventBus.PublishAsync(cancellationEvent);

        // If was active, also publish room available event
        if (notification.PreviousStatus == ReservationStatus.Active)
        {
            var roomAvailableEvent = new RoomBecameAvailableIntegrationEvent(
                reservation.RoomId,
                roomName);

            await _eventBus.PublishAsync(roomAvailableEvent);
        }
    }
}
