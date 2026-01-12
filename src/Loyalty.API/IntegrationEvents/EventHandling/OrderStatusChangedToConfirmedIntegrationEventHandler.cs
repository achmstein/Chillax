using Chillax.Loyalty.API.IntegrationEvents.Events;
using Chillax.Loyalty.API.Infrastructure;
using Chillax.Loyalty.API.Model;
using Microsoft.EntityFrameworkCore;

namespace Chillax.Loyalty.API.IntegrationEvents.EventHandling;

/// <summary>
/// Handles OrderStatusChangedToConfirmedIntegrationEvent to award loyalty points.
/// Points are calculated as: $1 = 10 points
/// </summary>
public class OrderStatusChangedToConfirmedIntegrationEventHandler(
    LoyaltyContext context,
    ILogger<OrderStatusChangedToConfirmedIntegrationEventHandler> logger)
    : IIntegrationEventHandler<OrderStatusChangedToConfirmedIntegrationEvent>
{
    private const int PointsPerDollar = 10;

    public async Task Handle(OrderStatusChangedToConfirmedIntegrationEvent @event)
    {
        logger.LogInformation(
            "Handling OrderStatusChangedToConfirmedIntegrationEvent: OrderId={OrderId}, UserId={UserId}, Total={Total}",
            @event.OrderId, @event.BuyerIdentityGuid, @event.OrderTotal);

        // Calculate points to award (round down to nearest integer)
        var pointsToAward = (int)Math.Floor(@event.OrderTotal * PointsPerDollar);

        if (pointsToAward <= 0)
        {
            logger.LogInformation("Order total too small to award points: {Total}", @event.OrderTotal);
            return;
        }

        // Get or create loyalty account for user
        var account = await context.Accounts
            .FirstOrDefaultAsync(a => a.UserId == @event.BuyerIdentityGuid);

        if (account == null)
        {
            // Create new account for this user
            account = new LoyaltyAccount
            {
                UserId = @event.BuyerIdentityGuid,
                PointsBalance = 0,
                LifetimePoints = 0,
                CurrentTier = LoyaltyTier.Bronze,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };
            context.Accounts.Add(account);
            await context.SaveChangesAsync();

            logger.LogInformation("Created new loyalty account for user {UserId}", @event.BuyerIdentityGuid);
        }

        // Award points
        account.AddPoints(
            pointsToAward,
            "purchase",
            $"Points earned from order #{@event.OrderId}",
            @event.OrderId.ToString());

        await context.SaveChangesAsync();

        logger.LogInformation(
            "Awarded {Points} points to user {UserId} for order {OrderId}. New balance: {Balance}, Tier: {Tier}",
            pointsToAward, @event.BuyerIdentityGuid, @event.OrderId, account.PointsBalance, account.CurrentTier);
    }
}
