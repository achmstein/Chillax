using Chillax.Ordering.Domain.AggregatesModel.OrderAggregate;

namespace Chillax.Ordering.UnitTests.Domain;

/// <summary>
/// Builder for creating Order instances in tests.
/// Simplified for cafe ordering - no address or payment details.
/// </summary>
public class OrderBuilder
{
    private readonly Order order;

    public OrderBuilder()
    {
        order = new Order(
            "userId",
            "fakeName",
            tableNumber: 1,
            customerNote: "Test note");
    }

    public OrderBuilder(int? tableNumber = null, string? customerNote = null)
    {
        order = new Order(
            "userId",
            "fakeName",
            tableNumber: tableNumber,
            customerNote: customerNote);
    }

    public OrderBuilder AddOne(
        int productId,
        string productName,
        decimal unitPrice,
        decimal discount,
        string pictureUrl,
        int units = 1)
    {
        order.AddOrderItem(productId, productName, unitPrice, discount, pictureUrl, units);
        return this;
    }

    public Order Build()
    {
        return order;
    }
}
