namespace Chillax.Ordering.API.Application.IntegrationEvents.EventHandling;

public class OrderStockRejectedIntegrationEventHandler(
    IOrderRepository orderRepository,
    ILogger<OrderStockRejectedIntegrationEventHandler> logger)
    : IIntegrationEventHandler<OrderStockRejectedIntegrationEvent>
{
    public async Task Handle(OrderStockRejectedIntegrationEvent @event)
    {
        logger.LogInformation("Handling integration event: {IntegrationEventId} - ({@IntegrationEvent})", @event.Id, @event);

        var order = await orderRepository.GetAsync(@event.OrderId);

        if (order is null)
        {
            logger.LogWarning("Order {OrderId} not found for stock rejection", @event.OrderId);
            return;
        }

        var unavailableProductIds = @event.OrderStockItems
            .Where(x => !x.HasStock)
            .Select(x => x.ProductId);

        order.SetStockRejectedStatus(unavailableProductIds);
        await orderRepository.UnitOfWork.SaveEntitiesAsync();

        logger.LogWarning("Order {OrderId} cancelled due to unavailable items: {UnavailableItems}",
            @event.OrderId, string.Join(", ", unavailableProductIds));
    }
}
