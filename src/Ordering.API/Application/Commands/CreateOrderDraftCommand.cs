namespace Chillax.Ordering.API.Application.Commands;
using Chillax.Ordering.API.Application.Models;

public record CreateOrderDraftCommand(string BuyerId, IEnumerable<BasketItem> Items) : IRequest<OrderDraftDTO>;
