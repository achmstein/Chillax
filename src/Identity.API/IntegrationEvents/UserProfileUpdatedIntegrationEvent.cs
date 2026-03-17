using Chillax.EventBus.Events;

namespace Chillax.Identity.API.IntegrationEvents;

public record UserProfileUpdatedIntegrationEvent(
    string UserId,
    string DisplayName) : IntegrationEvent;
