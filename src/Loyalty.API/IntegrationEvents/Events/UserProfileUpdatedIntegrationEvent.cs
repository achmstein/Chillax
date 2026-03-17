using Chillax.EventBus.Events;

namespace Chillax.Loyalty.API.IntegrationEvents.Events;

public record UserProfileUpdatedIntegrationEvent(
    string UserId,
    string DisplayName) : IntegrationEvent;
