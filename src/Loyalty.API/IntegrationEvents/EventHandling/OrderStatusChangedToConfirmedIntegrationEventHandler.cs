using Chillax.Loyalty.API.IntegrationEvents.Events;
using Chillax.Loyalty.API.Infrastructure;
using Chillax.Loyalty.API.Model;
using Microsoft.EntityFrameworkCore;

namespace Chillax.Loyalty.API.IntegrationEvents.EventHandling;

/// <summary>
/// Handles OrderStatusChangedToConfirmedIntegrationEvent to award and redeem loyalty points.
/// Points are calculated as: £1 = 10 points
/// </summary>
public class OrderStatusChangedToConfirmedIntegrationEventHandler(
    LoyaltyContext context,
    ILogger<OrderStatusChangedToConfirmedIntegrationEventHandler> logger)
    : IIntegrationEventHandler<OrderStatusChangedToConfirmedIntegrationEvent>
{
    private const int PointsPerPound = 10;

    public async Task Handle(OrderStatusChangedToConfirmedIntegrationEvent @event)
    {
        logger.LogInformation(
            "Handling OrderStatusChangedToConfirmedIntegrationEvent: OrderId={OrderId}, UserId={UserId}, Total={Total}, PointsToRedeem={PointsToRedeem}",
            @event.OrderId, @event.BuyerIdentityGuid, @event.OrderTotal, @event.PointsToRedeem);

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

        // Redeem points if any (do this first, before awarding new points)
        if (@event.PointsToRedeem > 0)
        {
            account.RedeemPoints(
                @event.PointsToRedeem,
                $"Discount on order #{@event.OrderId}",
                @event.OrderId.ToString());

            logger.LogInformation(
                "Redeemed {Points} points for user {UserId} on order {OrderId}",
                @event.PointsToRedeem, @event.BuyerIdentityGuid, @event.OrderId);
        }

        // Calculate points to award (round down to nearest integer)
        var pointsToAward = (int)Math.Floor(@event.OrderTotal * PointsPerPound);

        if (pointsToAward > 0)
        {
            // Award points
            account.AddPoints(
                pointsToAward,
                "purchase",
                $"Points earned from order #{@event.OrderId}",
                @event.OrderId.ToString());

            logger.LogInformation(
                "Awarded {Points} points to user {UserId} for order {OrderId}. New balance: {Balance}, Tier: {Tier}",
                pointsToAward, @event.BuyerIdentityGuid, @event.OrderId, account.PointsBalance, account.CurrentTier);
        }

        await context.SaveChangesAsync();
    }
}
