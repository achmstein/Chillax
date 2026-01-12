using System.ComponentModel;
using System.Security.Claims;
using Chillax.Notification.API.Model;
using Chillax.ServiceDefaults;
using Microsoft.AspNetCore.Http.HttpResults;

namespace Chillax.Notification.API.Apis;

public static class NotificationApi
{
    public static IEndpointRouteBuilder MapNotificationApi(this IEndpointRouteBuilder app)
    {
        var api = app.MapGroup("api/notifications").RequireAuthorization();

        // Subscription endpoints
        api.MapPost("/subscriptions/room-availability", SubscribeToRoomAvailability)
            .WithName("SubscribeToRoomAvailability")
            .WithSummary("Subscribe to room availability notifications")
            .WithDescription("Register to receive a one-time FCM notification when any room becomes available")
            .WithTags("Subscriptions");

        api.MapDelete("/subscriptions/room-availability", UnsubscribeFromRoomAvailability)
            .WithName("UnsubscribeFromRoomAvailability")
            .WithSummary("Unsubscribe from room availability notifications")
            .WithDescription("Remove your room availability notification subscription")
            .WithTags("Subscriptions");

        api.MapGet("/subscriptions/room-availability", GetRoomAvailabilitySubscription)
            .WithName("GetRoomAvailabilitySubscription")
            .WithSummary("Check subscription status")
            .WithDescription("Check if you are subscribed to room availability notifications")
            .WithTags("Subscriptions");

        // Admin order notification endpoints
        api.MapPost("/subscriptions/admin-orders", SubscribeToAdminOrderNotifications)
            .WithName("SubscribeToAdminOrderNotifications")
            .WithSummary("Subscribe to admin order notifications")
            .WithDescription("Register admin device to receive FCM notifications when new orders are placed")
            .WithTags("Admin Subscriptions");

        api.MapDelete("/subscriptions/admin-orders", UnsubscribeFromAdminOrderNotifications)
            .WithName("UnsubscribeFromAdminOrderNotifications")
            .WithSummary("Unsubscribe from admin order notifications")
            .WithDescription("Unregister admin device from order notifications (typically on logout)")
            .WithTags("Admin Subscriptions");

        return app;
    }

    public static async Task<Results<Created<SubscriptionResponse>, Conflict<string>>> SubscribeToRoomAvailability(
        NotificationContext context,
        ClaimsPrincipal user,
        SubscribeRequest request)
    {
        var userId = user.GetUserId()!;

        // Check if already subscribed
        var existing = await context.Subscriptions
            .FirstOrDefaultAsync(s => s.UserId == userId && s.Type == SubscriptionType.RoomAvailability);

        if (existing != null)
        {
            // Update FCM token if it changed
            if (existing.FcmToken != request.FcmToken)
            {
                existing.FcmToken = request.FcmToken;
                await context.SaveChangesAsync();
            }
            return TypedResults.Conflict("Already subscribed to room availability notifications");
        }

        var subscription = new NotificationSubscription
        {
            UserId = userId,
            FcmToken = request.FcmToken,
            Type = SubscriptionType.RoomAvailability,
            CreatedAt = DateTime.UtcNow
        };

        context.Subscriptions.Add(subscription);
        await context.SaveChangesAsync();

        return TypedResults.Created(
            $"/api/notifications/subscriptions/room-availability",
            new SubscriptionResponse(subscription.Id, subscription.Type, subscription.CreatedAt));
    }

    public static async Task<Results<NoContent, NotFound>> UnsubscribeFromRoomAvailability(
        NotificationContext context,
        ClaimsPrincipal user)
    {
        var userId = user.GetUserId()!;

        var subscription = await context.Subscriptions
            .FirstOrDefaultAsync(s => s.UserId == userId && s.Type == SubscriptionType.RoomAvailability);

        if (subscription == null)
        {
            return TypedResults.NotFound();
        }

        context.Subscriptions.Remove(subscription);
        await context.SaveChangesAsync();

        return TypedResults.NoContent();
    }

    public static async Task<Results<Ok<SubscriptionResponse>, NotFound>> GetRoomAvailabilitySubscription(
        NotificationContext context,
        ClaimsPrincipal user)
    {
        var userId = user.GetUserId()!;

        var subscription = await context.Subscriptions
            .FirstOrDefaultAsync(s => s.UserId == userId && s.Type == SubscriptionType.RoomAvailability);

        if (subscription == null)
        {
            return TypedResults.NotFound();
        }

        return TypedResults.Ok(new SubscriptionResponse(subscription.Id, subscription.Type, subscription.CreatedAt));
    }

    // Admin order notification handlers
    public static async Task<Results<Ok<SubscriptionResponse>, Created<SubscriptionResponse>>> SubscribeToAdminOrderNotifications(
        NotificationContext context,
        ClaimsPrincipal user,
        SubscribeRequest request)
    {
        var userId = user.GetUserId()!;

        // Check if already subscribed (update token if so)
        var existing = await context.Subscriptions
            .FirstOrDefaultAsync(s => s.UserId == userId && s.Type == SubscriptionType.AdminOrderNotification);

        if (existing != null)
        {
            // Update FCM token if it changed
            if (existing.FcmToken != request.FcmToken)
            {
                existing.FcmToken = request.FcmToken;
                await context.SaveChangesAsync();
            }
            return TypedResults.Ok(new SubscriptionResponse(existing.Id, existing.Type, existing.CreatedAt));
        }

        var subscription = new NotificationSubscription
        {
            UserId = userId,
            FcmToken = request.FcmToken,
            Type = SubscriptionType.AdminOrderNotification,
            CreatedAt = DateTime.UtcNow
        };

        context.Subscriptions.Add(subscription);
        await context.SaveChangesAsync();

        return TypedResults.Created(
            $"/api/notifications/subscriptions/admin-orders",
            new SubscriptionResponse(subscription.Id, subscription.Type, subscription.CreatedAt));
    }

    public static async Task<Results<NoContent, NotFound>> UnsubscribeFromAdminOrderNotifications(
        NotificationContext context,
        ClaimsPrincipal user)
    {
        var userId = user.GetUserId()!;

        var subscription = await context.Subscriptions
            .FirstOrDefaultAsync(s => s.UserId == userId && s.Type == SubscriptionType.AdminOrderNotification);

        if (subscription == null)
        {
            return TypedResults.NotFound();
        }

        context.Subscriptions.Remove(subscription);
        await context.SaveChangesAsync();

        return TypedResults.NoContent();
    }
}

public record SubscribeRequest(
    [property: Description("The FCM token from the mobile device")] string FcmToken
);

public record SubscriptionResponse(
    int Id,
    SubscriptionType Type,
    DateTime CreatedAt
);
