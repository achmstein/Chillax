using Chillax.EventBus.Events;
using Chillax.Rooms.Domain.SeedWork;

namespace Chillax.Rooms.API.Application.IntegrationEvents.Events;

public record SessionCompletedIntegrationEvent(
    int ReservationId,
    string CustomerId,
    int RoomId,
    LocalizedText RoomName,
    decimal TotalCost,
    DateTime StartTime,
    DateTime EndTime,
    TimeSpan Duration) : IntegrationEvent;
