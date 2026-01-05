namespace Chillax.Ordering.API.Application.Queries;

public interface IOrderQueries
{
    Task<Order> GetOrderAsync(int id);

    Task<IEnumerable<OrderSummary>> GetOrdersFromUserAsync(string userId);

    /// <summary>
    /// Get all pending orders (Submitted status) for admin review
    /// </summary>
    Task<IEnumerable<OrderSummary>> GetPendingOrdersAsync();
}
