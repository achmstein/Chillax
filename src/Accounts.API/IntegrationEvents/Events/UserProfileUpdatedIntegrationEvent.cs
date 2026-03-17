using Chillax.EventBus.Events;

namespace Chillax.Accounts.API.IntegrationEvents.Events;

public record UserProfileUpdatedIntegrationEvent(
    string UserId,
    string DisplayName) : IntegrationEvent;
