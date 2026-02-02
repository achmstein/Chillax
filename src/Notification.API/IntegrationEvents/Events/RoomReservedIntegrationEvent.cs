using Chillax.EventBus.Events;

namespace Chillax.Notification.API.IntegrationEvents.Events;

/// <summary>
/// Integration event published when a customer reserves a room
/// </summary>
public record RoomReservedIntegrationEvent(
    int ReservationId,
    int RoomId,
    string RoomName,
    string? CustomerId,
    string? CustomerName,
    DateTime ExpiresAt) : IntegrationEvent;
