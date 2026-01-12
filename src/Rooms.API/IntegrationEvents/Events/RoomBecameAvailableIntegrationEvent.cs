using Chillax.EventBus.Events;

namespace Chillax.Rooms.API.IntegrationEvents.Events;

public record RoomBecameAvailableIntegrationEvent(int RoomId, string RoomName) : IntegrationEvent;
