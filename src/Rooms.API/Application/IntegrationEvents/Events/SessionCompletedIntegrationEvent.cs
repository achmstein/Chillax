using Chillax.EventBus.Events;

namespace Chillax.Rooms.API.Application.IntegrationEvents.Events;

public record SessionCompletedIntegrationEvent(
    int ReservationId,
    string CustomerId,
    int RoomId,
    string RoomName,
    decimal TotalCost,
    DateTime StartTime,
    DateTime EndTime,
    TimeSpan Duration) : IntegrationEvent;
