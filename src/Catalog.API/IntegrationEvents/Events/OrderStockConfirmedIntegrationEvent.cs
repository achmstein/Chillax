namespace Chillax.Catalog.API.IntegrationEvents.Events;

public record OrderStockConfirmedIntegrationEvent(int OrderId) : IntegrationEvent;
