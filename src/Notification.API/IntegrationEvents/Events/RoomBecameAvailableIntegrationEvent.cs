using Chillax.EventBus.Events;

namespace Chillax.Notification.API.IntegrationEvents.Events;

public record RoomBecameAvailableIntegrationEvent(int RoomId, string RoomName) : IntegrationEvent;
