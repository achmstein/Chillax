using Chillax.EventBus.Events;

namespace Chillax.Notification.API.IntegrationEvents.Events;

public record BranchSettingsChangedIntegrationEvent(
    int BranchId,
    bool IsOrderingEnabled,
    bool IsReservationsEnabled) : IntegrationEvent;
