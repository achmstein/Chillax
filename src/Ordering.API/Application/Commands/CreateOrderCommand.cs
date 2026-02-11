#nullable enable
namespace Chillax.Ordering.API.Application.Commands;

using Chillax.Ordering.API.Application.Models;
using Chillax.Ordering.API.Extensions;
using Chillax.Ordering.Domain.Seedwork;

/// <summary>
/// Command to create a new cafe order.
/// Simplified for cafe - no address or payment details.
/// </summary>
[DataContract]
public class CreateOrderCommand : IRequest<bool>
{
    [DataMember]
    private readonly List<OrderItemDTO> _orderItems;

    [DataMember]
    public string UserId { get; private set; } = string.Empty;

    [DataMember]
    public string UserName { get; private set; } = string.Empty;

    /// <summary>
    /// Room name for the session (e.g., "VIP") - localized
    /// </summary>
    [DataMember]
    public LocalizedText? RoomName { get; private set; }

    /// <summary>
    /// Special instructions from customer (optional)
    /// </summary>
    [DataMember]
    public string? CustomerNote { get; private set; }

    /// <summary>
    /// Loyalty points to redeem for this order
    /// </summary>
    [DataMember]
    public int PointsToRedeem { get; private set; }

    /// <summary>
    /// Loyalty discount in currency, computed by the Loyalty API
    /// </summary>
    [DataMember]
    public double LoyaltyDiscount { get; private set; }

    [DataMember]
    public IEnumerable<OrderItemDTO> OrderItems => _orderItems;

    public CreateOrderCommand()
    {
        _orderItems = new List<OrderItemDTO>();
    }

    public CreateOrderCommand(
        List<BasketItem> basketItems,
        string userId,
        string userName,
        LocalizedText? roomName = null,
        string? customerNote = null,
        int pointsToRedeem = 0,
        double loyaltyDiscount = 0)
    {
        _orderItems = basketItems.ToOrderItemsDTO().ToList();
        UserId = userId;
        UserName = userName;
        RoomName = roomName;
        CustomerNote = customerNote;
        PointsToRedeem = pointsToRedeem;
        LoyaltyDiscount = loyaltyDiscount;
    }
}
