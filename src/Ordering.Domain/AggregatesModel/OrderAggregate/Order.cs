#nullable enable
using System.ComponentModel.DataAnnotations;

namespace Chillax.Ordering.Domain.AggregatesModel.OrderAggregate;

/// <summary>
/// Order aggregate root for cafe orders.
/// Simple flow: Submitted -> Confirmed (goes to POS) or Cancelled
/// </summary>
public class Order
    : Entity, IAggregateRoot
{
    public DateTime OrderDate { get; private set; }

    public int? BuyerId { get; private set; }

    public Buyer? Buyer { get; }

    public OrderStatus OrderStatus { get; private set; }

    public string? Description { get; private set; }

    /// <summary>
    /// Table number for cafe delivery (optional)
    /// </summary>
    public int? TableNumber { get; private set; }

    /// <summary>
    /// Special instructions or notes from the customer
    /// </summary>
    public string? CustomerNote { get; private set; }

    // Draft orders have this set to true
#pragma warning disable CS0414
    private bool _isDraft;
#pragma warning restore CS0414

    // Using a private collection field for DDD Aggregate's encapsulation
    private readonly List<OrderItem> _orderItems;

    public IReadOnlyCollection<OrderItem> OrderItems => _orderItems.AsReadOnly();

    public static Order NewDraft()
    {
        var order = new Order
        {
            _isDraft = true
        };
        return order;
    }

    protected Order()
    {
        _orderItems = new List<OrderItem>();
        _isDraft = false;
    }

    public Order(string userId, string userName, int? tableNumber = null, string? customerNote = null, int? buyerId = null) : this()
    {
        BuyerId = buyerId;
        OrderStatus = OrderStatus.Submitted;
        OrderDate = DateTime.UtcNow;
        TableNumber = tableNumber;
        CustomerNote = customerNote;

        // Add the OrderStartedDomainEvent to the domain events collection
        AddOrderStartedDomainEvent(userId, userName);
    }

    /// <summary>
    /// Add item to the order
    /// </summary>
    public void AddOrderItem(int productId, string productName, decimal unitPrice, decimal discount, string pictureUrl, int units = 1)
    {
        var existingOrderForProduct = _orderItems.SingleOrDefault(o => o.ProductId == productId);

        if (existingOrderForProduct != null)
        {
            // If previous line exists, modify it with higher discount and units
            if (discount > existingOrderForProduct.Discount)
            {
                existingOrderForProduct.SetNewDiscount(discount);
            }

            existingOrderForProduct.AddUnits(units);
        }
        else
        {
            // Add validated new order item
            var orderItem = new OrderItem(productId, productName, unitPrice, discount, pictureUrl, units);
            _orderItems.Add(orderItem);
        }
    }

    /// <summary>
    /// Set the buyer after validation
    /// </summary>
    public void SetBuyerId(int buyerId)
    {
        BuyerId = buyerId;
    }

    /// <summary>
    /// Confirm the order (admin action) - moves to POS
    /// </summary>
    public void SetConfirmedStatus()
    {
        if (OrderStatus != OrderStatus.Submitted)
        {
            throw new OrderingDomainException($"Cannot confirm order from status {OrderStatus}. Order must be in Submitted status.");
        }

        AddDomainEvent(new OrderStatusChangedToConfirmedDomainEvent(Id, _orderItems));
        OrderStatus = OrderStatus.Confirmed;
        Description = "Order confirmed and sent to POS.";
    }

    /// <summary>
    /// Cancel the order (can only cancel submitted orders)
    /// </summary>
    public void SetCancelledStatus()
    {
        if (OrderStatus != OrderStatus.Submitted)
        {
            throw new OrderingDomainException($"Cannot cancel order from status {OrderStatus}. Only submitted orders can be cancelled.");
        }

        OrderStatus = OrderStatus.Cancelled;
        Description = "The order was cancelled.";
        AddDomainEvent(new OrderCancelledDomainEvent(this));
    }

    private void AddOrderStartedDomainEvent(string userId, string userName)
    {
        var orderStartedDomainEvent = new OrderStartedDomainEvent(this, userId, userName);
        this.AddDomainEvent(orderStartedDomainEvent);
    }

    public decimal GetTotal() => _orderItems.Sum(o => o.Units * o.UnitPrice);
}
