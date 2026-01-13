using System.Text.Json.Serialization;
using Chillax.Notification.API.IntegrationEvents.EventHandling;
using Chillax.Notification.API.IntegrationEvents.Events;
using Chillax.Notification.API.Services;

namespace Chillax.Notification.API.Extensions;

public static class Extensions
{
    public static void AddApplicationServices(this IHostApplicationBuilder builder)
    {
        // Add database context
        builder.AddNpgsqlDbContext<NotificationContext>("notificationdb", configureDbContextOptions: options =>
        {
            options.UseNpgsql(builder => builder.MigrationsAssembly(typeof(NotificationContext).Assembly.FullName));
        });

        // Add database seeder
        builder.Services.AddMigration<NotificationContext, NotificationContextSeed>();

        // Add FCM service
        builder.Services.AddSingleton<IFcmService, FcmService>();

        // Add RabbitMQ event bus with subscriptions
        builder.AddRabbitMqEventBus("eventbus")
            .ConfigureJsonOptions(options =>
                options.TypeInfoResolverChain.Add(NotificationIntegrationEventContext.Default))
            .AddSubscription<RoomBecameAvailableIntegrationEvent, RoomBecameAvailableIntegrationEventHandler>()
            .AddSubscription<OrderStatusChangedToSubmittedIntegrationEvent, OrderSubmittedIntegrationEventHandler>()
            .AddSubscription<ServiceRequestCreatedIntegrationEvent, ServiceRequestCreatedIntegrationEventHandler>();
    }
}

[JsonSerializable(typeof(RoomBecameAvailableIntegrationEvent))]
[JsonSerializable(typeof(OrderStatusChangedToSubmittedIntegrationEvent))]
[JsonSerializable(typeof(ServiceRequestCreatedIntegrationEvent))]
public partial class NotificationIntegrationEventContext : JsonSerializerContext
{
}
