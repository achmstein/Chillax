namespace Chillax.Ordering.API.Application.IntegrationEvents.EventHandling;

public class OrderStockConfirmedIntegrationEventHandler(
    IOrderRepository orderRepository,
    ILogger<OrderStockConfirmedIntegrationEventHandler> logger)
    : IIntegrationEventHandler<OrderStockConfirmedIntegrationEvent>
{
    public async Task Handle(OrderStockConfirmedIntegrationEvent @event)
    {
        logger.LogInformation("Handling integration event: {IntegrationEventId} - ({@IntegrationEvent})", @event.Id, @event);

        var order = await orderRepository.GetAsync(@event.OrderId);

        if (order is null)
        {
            logger.LogWarning("Order {OrderId} not found for stock confirmation", @event.OrderId);
            return;
        }

        order.SetStockConfirmedStatus();
        await orderRepository.UnitOfWork.SaveEntitiesAsync();

        logger.LogInformation("Order {OrderId} stock confirmed - status changed to Submitted", @event.OrderId);
    }
}
