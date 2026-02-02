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

        // Get loyalty account for user (must already exist - user joins manually)
        var account = await context.Accounts
            .FirstOrDefaultAsync(a => a.UserId == @event.BuyerIdentityGuid);

        if (account == null)
        {
            // User hasn't joined loyalty program - skip awarding points
            logger.LogInformation(
                "User {UserId} has no loyalty account, skipping points for order {OrderId}",
                @event.BuyerIdentityGuid, @event.OrderId);
            return;
        }

        // Redeem points if any (do this first, before awarding new points)
        if (@event.PointsToRedeem > 0)
        {
            account.RedeemPoints(
                @event.PointsToRedeem,
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
                TransactionType.Purchase,
                @event.OrderId.ToString());

            logger.LogInformation(
                "Awarded {Points} points to user {UserId} for order {OrderId}. New balance: {Balance}, Tier: {Tier}",
                pointsToAward, @event.BuyerIdentityGuid, @event.OrderId, account.PointsBalance, account.CurrentTier);
        }

        await context.SaveChangesAsync();
    }
}
