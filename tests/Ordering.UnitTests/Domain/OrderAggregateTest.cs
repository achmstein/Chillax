namespace Chillax.Ordering.UnitTests.Domain;

using Chillax.Ordering.Domain.AggregatesModel.OrderAggregate;

/// <summary>
/// Unit tests for Order aggregate.
/// Simplified for cafe - no address or payment details.
/// </summary>
[TestClass]
public class OrderAggregateTest
{
    public OrderAggregateTest()
    { }

    [TestMethod]
    public void Create_order_item_success()
    {
        // Arrange
        var productId = 1;
        var productName = "FakeProductName";
        var unitPrice = 12;
        var discount = 15;
        var pictureUrl = "FakeUrl";
        var units = 5;

        // Act
        var fakeOrderItem = new OrderItem(productId, productName, unitPrice, discount, pictureUrl, units);

        // Assert
        Assert.IsNotNull(fakeOrderItem);
    }

    [TestMethod]
    public void Invalid_number_of_units()
    {
        // Arrange
        var productId = 1;
        var productName = "FakeProductName";
        var unitPrice = 12;
        var discount = 15;
        var pictureUrl = "FakeUrl";
        var units = -1;

        // Act - Assert
        Assert.ThrowsExactly<OrderingDomainException>(() => new OrderItem(productId, productName, unitPrice, discount, pictureUrl, units));
    }

    [TestMethod]
    public void Invalid_total_of_order_item_lower_than_discount_applied()
    {
        // Arrange
        var productId = 1;
        var productName = "FakeProductName";
        var unitPrice = 12;
        var discount = 15;
        var pictureUrl = "FakeUrl";
        var units = 1;

        // Act - Assert
        Assert.ThrowsExactly<OrderingDomainException>(() => new OrderItem(productId, productName, unitPrice, discount, pictureUrl, units));
    }

    [TestMethod]
    public void Invalid_discount_setting()
    {
        // Arrange
        var productId = 1;
        var productName = "FakeProductName";
        var unitPrice = 12;
        var discount = 15;
        var pictureUrl = "FakeUrl";
        var units = 5;

        // Act
        var fakeOrderItem = new OrderItem(productId, productName, unitPrice, discount, pictureUrl, units);

        // Assert
        Assert.ThrowsExactly<OrderingDomainException>(() => fakeOrderItem.SetNewDiscount(-1));
    }

    [TestMethod]
    public void Invalid_units_setting()
    {
        // Arrange
        var productId = 1;
        var productName = "FakeProductName";
        var unitPrice = 12;
        var discount = 15;
        var pictureUrl = "FakeUrl";
        var units = 5;

        // Act
        var fakeOrderItem = new OrderItem(productId, productName, unitPrice, discount, pictureUrl, units);

        // Assert
        Assert.ThrowsExactly<OrderingDomainException>(() => fakeOrderItem.AddUnits(-1));
    }

    [TestMethod]
    public void When_add_two_times_on_the_same_item_then_the_total_of_order_should_be_the_sum_of_the_two_items()
    {
        var order = new OrderBuilder()
            .AddOne(1, "cup", 10.0m, 0, string.Empty)
            .AddOne(1, "cup", 10.0m, 0, string.Empty)
            .Build();

        Assert.AreEqual(20.0m, order.GetTotal());
    }

    [TestMethod]
    public void Add_new_Order_raises_new_event()
    {
        // Arrange
        var userId = "1";
        var userName = "fakeName";
        var tableNumber = 5;
        var customerNote = "No sugar please";
        var expectedResult = 1;

        // Act
        var fakeOrder = new Order(userId, userName, tableNumber, customerNote);

        // Assert
        Assert.HasCount(expectedResult, fakeOrder.DomainEvents);
    }

    [TestMethod]
    public void Add_event_Order_explicitly_raises_new_event()
    {
        // Arrange
        var userId = "1";
        var userName = "fakeName";
        var tableNumber = 5;
        var expectedResult = 2;

        // Act
        var fakeOrder = new Order(userId, userName, tableNumber);
        fakeOrder.AddDomainEvent(new OrderStartedDomainEvent(fakeOrder, userId, userName));

        // Assert
        Assert.HasCount(expectedResult, fakeOrder.DomainEvents);
    }

    [TestMethod]
    public void Remove_event_Order_explicitly()
    {
        // Arrange
        var userId = "1";
        var userName = "fakeName";
        var fakeOrder = new Order(userId, userName);
        var @fakeEvent = new OrderStartedDomainEvent(fakeOrder, userId, userName);
        var expectedResult = 1;

        // Act
        fakeOrder.AddDomainEvent(@fakeEvent);
        fakeOrder.RemoveDomainEvent(@fakeEvent);

        // Assert
        Assert.HasCount(expectedResult, fakeOrder.DomainEvents);
    }

    [TestMethod]
    public void Order_status_transitions_correctly()
    {
        // Arrange
        var order = new Order("userId", "userName", tableNumber: 1);

        // Assert initial status
        Assert.AreEqual(OrderStatus.Submitted, order.OrderStatus);

        // Act - Confirm order
        order.SetConfirmedStatus();

        // Assert confirmed status
        Assert.AreEqual(OrderStatus.Confirmed, order.OrderStatus);
    }

    [TestMethod]
    public void Order_can_be_cancelled_when_submitted()
    {
        // Arrange
        var order = new Order("userId", "userName", tableNumber: 1);

        // Act
        order.SetCancelledStatus();

        // Assert
        Assert.AreEqual(OrderStatus.Cancelled, order.OrderStatus);
    }

    [TestMethod]
    public void Order_cannot_be_cancelled_when_confirmed()
    {
        // Arrange
        var order = new Order("userId", "userName", tableNumber: 1);
        order.SetConfirmedStatus();

        // Act - Assert
        Assert.ThrowsExactly<OrderingDomainException>(() => order.SetCancelledStatus());
    }

    [TestMethod]
    public void Order_cannot_be_confirmed_when_cancelled()
    {
        // Arrange
        var order = new Order("userId", "userName", tableNumber: 1);
        order.SetCancelledStatus();

        // Act - Assert
        Assert.ThrowsExactly<OrderingDomainException>(() => order.SetConfirmedStatus());
    }
}
