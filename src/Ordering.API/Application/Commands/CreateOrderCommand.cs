#nullable enable
namespace Chillax.Ordering.API.Application.Commands;

using Chillax.Ordering.API.Application.Models;
using Chillax.Ordering.API.Extensions;

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
    /// Room name for the session (e.g., "VIP")
    /// </summary>
    [DataMember]
    public string? RoomName { get; private set; }

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
        string? roomName = null,
        string? customerNote = null,
        int pointsToRedeem = 0)
    {
        _orderItems = basketItems.ToOrderItemsDTO().ToList();
        UserId = userId;
        UserName = userName;
        RoomName = roomName;
        CustomerNote = customerNote;
        PointsToRedeem = pointsToRedeem;
    }
}
