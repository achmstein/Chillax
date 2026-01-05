namespace Chillax.Ordering.API.Application.Validations;

/// <summary>
/// Simplified validator for cafe orders.
/// No address or payment validation needed.
/// </summary>
public class CreateOrderCommandValidator : AbstractValidator<CreateOrderCommand>
{
    public CreateOrderCommandValidator(ILogger<CreateOrderCommandValidator> logger)
    {
        RuleFor(command => command.UserId).NotEmpty();
        RuleFor(command => command.UserName).NotEmpty();
        RuleFor(command => command.OrderItems).Must(ContainOrderItems).WithMessage("No order items found");

        if (logger.IsEnabled(LogLevel.Trace))
        {
            logger.LogTrace("INSTANCE CREATED - {ClassName}", GetType().Name);
        }
    }

    private bool ContainOrderItems(IEnumerable<OrderItemDTO> orderItems)
    {
        return orderItems.Any();
    }
}
