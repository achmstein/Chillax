using Chillax.EventBus.Abstractions;
using Chillax.Rooms.API.Application.IntegrationEvents.Events;
using Chillax.Rooms.Domain.Events;
using Chillax.Rooms.Domain.SeedWork;
using MediatR;
using Microsoft.Extensions.Logging;

namespace Chillax.Rooms.API.Application.DomainEventHandlers;

public class SessionMemberJoinedDomainEventHandler : INotificationHandler<SessionMemberJoinedDomainEvent>
{
    private readonly IEventBus _eventBus;
    private readonly ILogger<SessionMemberJoinedDomainEventHandler> _logger;

    public SessionMemberJoinedDomainEventHandler(
        IEventBus eventBus,
        ILogger<SessionMemberJoinedDomainEventHandler> logger)
    {
        _eventBus = eventBus;
        _logger = logger;
    }

    public async Task Handle(SessionMemberJoinedDomainEvent notification, CancellationToken cancellationToken)
    {
        var reservation = notification.Reservation;

        _logger.LogInformation("Session member joined: ReservationId={ReservationId}, RoomId={RoomId}, MemberId={MemberId}",
            reservation.Id, reservation.RoomId, notification.MemberUserId);

        var roomName = reservation.Room?.Name ?? new LocalizedText($"Room {reservation.RoomId}");
        var memberJoinedEvent = new SessionMemberJoinedIntegrationEvent(
            reservation.Id,
            reservation.RoomId,
            roomName,
            notification.MemberUserId,
            reservation.ActualStartTime);

        await _eventBus.PublishAsync(memberJoinedEvent);
    }
}
