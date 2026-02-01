using Chillax.EventBus.Events;
using Chillax.Rooms.Domain.SeedWork;

namespace Chillax.Rooms.API.Application.IntegrationEvents.Events;

public record RoomBecameAvailableIntegrationEvent(int RoomId, LocalizedText RoomName) : IntegrationEvent;
