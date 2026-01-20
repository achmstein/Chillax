using Chillax.EventBus.Events;

namespace Chillax.Rooms.API.Application.IntegrationEvents.Events;

public record RoomBecameAvailableIntegrationEvent(int RoomId, string RoomName) : IntegrationEvent;
