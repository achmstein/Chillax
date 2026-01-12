namespace Chillax.Ordering.API.Application.IntegrationEvents.Events;

public record OrderStockItem(int ProductId, int Units);

public record OrderStatusChangedToAwaitingValidationIntegrationEvent(int OrderId, IEnumerable<OrderStockItem> OrderStockItems) : IntegrationEvent;
