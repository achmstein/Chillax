#nullable enable
namespace Chillax.Ordering.API.Application.Queries;

using DomainOrder = Chillax.Ordering.Domain.AggregatesModel.OrderAggregate.Order;

/// <summary>
/// Simplified order queries for cafe ordering system.
/// </summary>
public class OrderQueries(OrderingContext context) : IOrderQueries
{
    public async Task<Order> GetOrderAsync(int id)
    {
        var order = await context.Orders
            .Include(o => o.OrderItems)
            .FirstOrDefaultAsync(o => o.Id == id);

        if (order is null)
            throw new KeyNotFoundException();

        return new Order
        {
            OrderNumber = order.Id,
            Date = order.OrderDate,
            Description = order.Description,
            TableNumber = order.TableNumber,
            CustomerNote = order.CustomerNote,
            Status = order.OrderStatus.ToString(),
            Total = order.GetTotal(),
            OrderItems = order.OrderItems.Select(oi => new Orderitem
            {
                ProductName = oi.ProductName,
                Units = oi.Units,
                UnitPrice = (double)oi.UnitPrice,
                PictureUrl = oi.PictureUrl
            }).ToList()
        };
    }

    public async Task<IEnumerable<OrderSummary>> GetOrdersFromUserAsync(string userId)
    {
        return await context.Orders
            .Where(o => o.Buyer != null && o.Buyer.IdentityGuid == userId)
            .Select(o => new OrderSummary
            {
                OrderNumber = o.Id,
                Date = o.OrderDate,
                Status = o.OrderStatus.ToString(),
                Total = (double)o.OrderItems.Sum(oi => oi.UnitPrice * oi.Units),
                TableNumber = o.TableNumber
            })
            .ToListAsync();
    }

    public async Task<IEnumerable<OrderSummary>> GetPendingOrdersAsync()
    {
        return await context.Orders
            .Where(o => o.OrderStatus == Ordering.Domain.AggregatesModel.OrderAggregate.OrderStatus.Submitted)
            .OrderByDescending(o => o.OrderDate)
            .Select(o => new OrderSummary
            {
                OrderNumber = o.Id,
                Date = o.OrderDate,
                Status = o.OrderStatus.ToString(),
                Total = (double)o.OrderItems.Sum(oi => oi.UnitPrice * oi.Units),
                TableNumber = o.TableNumber
            })
            .ToListAsync();
    }
}
