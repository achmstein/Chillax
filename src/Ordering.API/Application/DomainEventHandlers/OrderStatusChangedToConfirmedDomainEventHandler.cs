#nullable enable
namespace Chillax.Ordering.API.Application.DomainEventHandlers;

/// <summary>
/// Handler for OrderStatusChangedToConfirmedDomainEvent.
/// Publishes an integration event to notify other services that the order is confirmed.
/// </summary>
public class OrderStatusChangedToConfirmedDomainEventHandler
    : INotificationHandler<OrderStatusChangedToConfirmedDomainEvent>
{
    private readonly IOrderRepository _orderRepository;
    private readonly IBuyerRepository _buyerRepository;
    private readonly ILogger _logger;
    private readonly IOrderingIntegrationEventService _orderingIntegrationEventService;

    public OrderStatusChangedToConfirmedDomainEventHandler(
        IOrderRepository orderRepository,
        ILogger<OrderStatusChangedToConfirmedDomainEventHandler> logger,
        IBuyerRepository buyerRepository,
        IOrderingIntegrationEventService orderingIntegrationEventService)
    {
        _orderRepository = orderRepository ?? throw new ArgumentNullException(nameof(orderRepository));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        _buyerRepository = buyerRepository ?? throw new ArgumentNullException(nameof(buyerRepository));
        _orderingIntegrationEventService = orderingIntegrationEventService ?? throw new ArgumentNullException(nameof(orderingIntegrationEventService));
    }

    public async Task Handle(OrderStatusChangedToConfirmedDomainEvent domainEvent, CancellationToken cancellationToken)
    {
        OrderingApiTrace.LogOrderStatusUpdated(_logger, domainEvent.OrderId, OrderStatus.Confirmed);

        var order = await _orderRepository.GetAsync(domainEvent.OrderId);

        if (order?.BuyerId == null)
        {
            _logger.LogWarning("Order {OrderId} has no buyer", domainEvent.OrderId);
            return;
        }

        var buyer = await _buyerRepository.FindByIdAsync(order.BuyerId.Value);

        if (buyer == null)
        {
            _logger.LogWarning("Buyer {BuyerId} not found for order {OrderId}", order.BuyerId, domainEvent.OrderId);
            return;
        }

        var integrationEvent = new OrderStatusChangedToConfirmedIntegrationEvent(
            order.Id,
            order.OrderStatus,
            buyer.Name,
            buyer.IdentityGuid,
            order.RoomName,
            order.GetTotal(),
            order.PointsToRedeem);

        await _orderingIntegrationEventService.AddAndSaveEventAsync(integrationEvent);
    }
}
