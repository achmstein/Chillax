using Chillax.EventBus.Events;
using Chillax.Rooms.Domain.SeedWork;

namespace Chillax.Rooms.API.Application.IntegrationEvents.Events;

/// <summary>
/// Integration event published when a customer joins an active session
/// Used to send session notification to the joining member
/// </summary>
public record SessionMemberJoinedIntegrationEvent(
    int ReservationId,
    int RoomId,
    LocalizedText RoomName,
    string MemberUserId,
    DateTime? ActualStartTime) : IntegrationEvent;
