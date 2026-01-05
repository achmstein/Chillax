namespace Chillax.Ordering.API.Application.IntegrationEvents.Events;

/// <summary>
/// Integration event sent when an order is confirmed by admin.
/// This event notifies other services (e.g., POS) that the order is ready.
/// </summary>
public record OrderStatusChangedToConfirmedIntegrationEvent : IntegrationEvent
{
    public int OrderId { get; }
    public OrderStatus OrderStatus { get; }
    public string BuyerName { get; }
    public string BuyerIdentityGuid { get; }
    public int? TableNumber { get; }

    public OrderStatusChangedToConfirmedIntegrationEvent(
        int orderId, OrderStatus orderStatus, string buyerName, string buyerIdentityGuid, int? tableNumber)
    {
        OrderId = orderId;
        OrderStatus = orderStatus;
        BuyerName = buyerName;
        BuyerIdentityGuid = buyerIdentityGuid;
        TableNumber = tableNumber;
    }
}
