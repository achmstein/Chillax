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
            .Include(o => o.Rating)
            .FirstOrDefaultAsync(o => o.Id == id);

        if (order is null)
            throw new KeyNotFoundException();

        return new Order
        {
            OrderNumber = order.Id,
            Date = order.OrderDate,
            Description = order.Description,
            RoomName = order.RoomName,
            CustomerNote = order.CustomerNote,
            Status = order.OrderStatus.ToString(),
            Total = order.GetTotal(),
            PointsToRedeem = order.PointsToRedeem,
            OrderItems = order.OrderItems.Select(oi => new Orderitem
            {
                ProductName = oi.ProductName,
                Units = oi.Units,
                UnitPrice = (double)oi.UnitPrice,
                PictureUrl = oi.PictureUrl,
                CustomizationsDescription = oi.CustomizationsDescription,
                SpecialInstructions = oi.SpecialInstructions
            }).ToList(),
            Rating = order.Rating != null ? new OrderRatingDto
            {
                RatingValue = order.Rating.RatingValue,
                Comment = order.Rating.Comment,
                CreatedAt = order.Rating.CreatedAt
            } : null
        };
    }

    public async Task<PaginatedResult<OrderSummary>> GetOrdersFromUserAsync(string userId, int pageIndex, int pageSize)
    {
        var query = context.Orders
            .Where(o => o.Buyer != null && o.Buyer.IdentityGuid == userId);

        var totalCount = await query.CountAsync();

        var items = await query
            .OrderByDescending(o => o.OrderDate)
            .Skip(pageIndex * pageSize)
            .Take(pageSize)
            .Select(o => new OrderSummary
            {
                OrderNumber = o.Id,
                Date = o.OrderDate,
                Status = o.OrderStatus.ToString(),
                Total = (double)o.OrderItems.Sum(oi => oi.UnitPrice * oi.Units),
                PointsToRedeem = o.PointsToRedeem,
                RoomName = o.RoomName
            })
            .ToListAsync();

        return new PaginatedResult<OrderSummary>
        {
            Items = items,
            PageIndex = pageIndex,
            PageSize = pageSize,
            TotalCount = totalCount
        };
    }

    public async Task<IEnumerable<OrderSummary>> GetPendingOrdersAsync()
    {
        return await context.Orders
            .Include(o => o.Buyer)
            .Where(o => o.OrderStatus == Ordering.Domain.AggregatesModel.OrderAggregate.OrderStatus.Submitted)
            .OrderByDescending(o => o.OrderDate)
            .Select(o => new OrderSummary
            {
                OrderNumber = o.Id,
                Date = o.OrderDate,
                Status = o.OrderStatus.ToString(),
                Total = (double)o.OrderItems.Sum(oi => oi.UnitPrice * oi.Units),
                PointsToRedeem = o.PointsToRedeem,
                RoomName = o.RoomName,
                UserName = o.Buyer != null ? o.Buyer.Name : null
            })
            .ToListAsync();
    }

    public async Task<PaginatedResult<OrderSummary>> GetAllOrdersAsync(int pageIndex, int pageSize)
    {
        var query = context.Orders.Include(o => o.Buyer);

        var totalCount = await query.CountAsync();

        var items = await query
            .OrderByDescending(o => o.OrderDate)
            .Skip(pageIndex * pageSize)
            .Take(pageSize)
            .Select(o => new OrderSummary
            {
                OrderNumber = o.Id,
                Date = o.OrderDate,
                Status = o.OrderStatus.ToString(),
                Total = (double)o.OrderItems.Sum(oi => oi.UnitPrice * oi.Units),
                PointsToRedeem = o.PointsToRedeem,
                RoomName = o.RoomName,
                UserName = o.Buyer != null ? o.Buyer.Name : null
            })
            .ToListAsync();

        return new PaginatedResult<OrderSummary>
        {
            Items = items,
            PageIndex = pageIndex,
            PageSize = pageSize,
            TotalCount = totalCount
        };
    }
}
