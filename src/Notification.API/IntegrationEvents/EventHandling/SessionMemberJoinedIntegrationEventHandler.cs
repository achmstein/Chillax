using Chillax.EventBus.Abstractions;
using Chillax.Notification.API.IntegrationEvents.Events;
using Chillax.Notification.API.Model;
using Chillax.Notification.API.Services;

namespace Chillax.Notification.API.IntegrationEvents.EventHandling;

public class SessionMemberJoinedIntegrationEventHandler(
    NotificationContext context,
    IFcmService fcmService,
    ILogger<SessionMemberJoinedIntegrationEventHandler> logger) : IIntegrationEventHandler<SessionMemberJoinedIntegrationEvent>
{
    public async Task Handle(SessionMemberJoinedIntegrationEvent @event)
    {
        logger.LogInformation("Handling SessionMemberJoinedIntegrationEvent: ReservationId={ReservationId}, MemberId={MemberId}",
            @event.ReservationId, @event.MemberUserId);

        // Get session notification subscription for the joining member
        var subscriptions = await context.Subscriptions
            .Where(s => s.UserId == @event.MemberUserId
                && s.Type == SubscriptionType.UserSessionNotification)
            .ToListAsync();

        if (subscriptions.Count == 0)
        {
            logger.LogInformation("No session notification subscription found for member {MemberId}", @event.MemberUserId);
            return;
        }

        var startTimeMs = @event.ActualStartTime?.ToUniversalTime()
            .Subtract(DateTime.UnixEpoch).TotalMilliseconds.ToString("0") ?? "";

        foreach (var group in subscriptions.GroupBy(s => s.PreferredLanguage))
        {
            var lang = group.Key;
            var tokens = group.Select(s => s.FcmToken).ToList();
            var roomName = @event.RoomName.GetText(lang);

            var data = new Dictionary<string, string>
            {
                { "type", "session_started" },
                { "sessionId", @event.ReservationId.ToString() },
                { "roomId", @event.RoomId.ToString() },
                { "roomName", roomName },
                { "roomNameEn", @event.RoomName.GetText("en") },
                { "roomNameAr", @event.RoomName.GetText("ar") ?? @event.RoomName.GetText("en") },
                { "startTimeMs", startTimeMs },
                { "locale", lang }
            };

            var successCount = await fcmService.SendBatchDataMessagesAsync(tokens, data);
            logger.LogInformation("Sent {SuccessCount}/{TotalCount} session started FCM to joining member {MemberId} in {Lang}",
                successCount, tokens.Count, @event.MemberUserId, lang);
        }
    }
}
