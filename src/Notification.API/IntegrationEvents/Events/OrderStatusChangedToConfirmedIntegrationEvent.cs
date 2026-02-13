using Chillax.EventBus.Events;
using Chillax.Notification.API.Model;

namespace Chillax.Notification.API.IntegrationEvents.Events;

public record OrderStatusChangedToConfirmedIntegrationEvent : IntegrationEvent
{
    public int OrderId { get; }
    public OrderStatus OrderStatus { get; }
    public string BuyerName { get; }
    public string BuyerIdentityGuid { get; }
    public LocalizedText? RoomName { get; }
    public decimal OrderTotal { get; }
    public int PointsToRedeem { get; }

    public OrderStatusChangedToConfirmedIntegrationEvent(
        int orderId, OrderStatus orderStatus, string buyerName, string buyerIdentityGuid, LocalizedText? roomName, decimal orderTotal, int pointsToRedeem = 0)
    {
        OrderId = orderId;
        OrderStatus = orderStatus;
        BuyerName = buyerName;
        BuyerIdentityGuid = buyerIdentityGuid;
        RoomName = roomName;
        OrderTotal = orderTotal;
        PointsToRedeem = pointsToRedeem;
    }
}
