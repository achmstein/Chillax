namespace Chillax.Catalog.API.IntegrationEvents.EventHandling;

public class OrderStatusChangedToAwaitingValidationIntegrationEventHandler(
    CatalogContext catalogContext,
    ICatalogIntegrationEventService catalogIntegrationEventService,
    ILogger<OrderStatusChangedToAwaitingValidationIntegrationEventHandler> logger) :
    IIntegrationEventHandler<OrderStatusChangedToAwaitingValidationIntegrationEvent>
{
    public async Task Handle(OrderStatusChangedToAwaitingValidationIntegrationEvent @event)
    {
        logger.LogInformation("Handling integration event: {IntegrationEventId} - ({@IntegrationEvent})", @event.Id, @event);

        var confirmedOrderStockItems = new List<ConfirmedOrderStockItem>();

        foreach (var orderStockItem in @event.OrderStockItems)
        {
            var catalogItem = await catalogContext.CatalogItems.FindAsync(orderStockItem.ProductId);
            if (catalogItem is not null)
            {
                // For cafe menu items, we check if the item is available (not stock-based)
                var isAvailable = catalogItem.IsAvailable;
                var confirmedOrderStockItem = new ConfirmedOrderStockItem(catalogItem.Id, isAvailable);

                confirmedOrderStockItems.Add(confirmedOrderStockItem);
            }
        }

        var confirmedIntegrationEvent = confirmedOrderStockItems.Any(c => !c.HasStock)
            ? (IntegrationEvent)new OrderStockRejectedIntegrationEvent(@event.OrderId, confirmedOrderStockItems)
            : new OrderStockConfirmedIntegrationEvent(@event.OrderId);

        await catalogIntegrationEventService.SaveEventAndCatalogContextChangesAsync(confirmedIntegrationEvent);
        await catalogIntegrationEventService.PublishThroughEventBusAsync(confirmedIntegrationEvent);
    }
}
