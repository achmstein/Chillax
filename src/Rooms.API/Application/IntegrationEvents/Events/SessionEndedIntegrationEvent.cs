using Chillax.EventBus.Events;
using Chillax.Rooms.Domain.SeedWork;

namespace Chillax.Rooms.API.Application.IntegrationEvents.Events;

/// <summary>
/// Integration event published when admin ends a session
/// Used to dismiss session notifications on customer devices
/// </summary>
public record SessionEndedIntegrationEvent(
    int ReservationId,
    int RoomId,
    LocalizedText RoomName,
    List<string> MemberUserIds) : IntegrationEvent;
