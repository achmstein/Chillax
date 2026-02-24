using System.Text.Json.Serialization;
using Chillax.Rooms.API.Application.BackgroundServices;
using Chillax.Rooms.API.Application.IntegrationEvents.Events;
using Chillax.Rooms.API.Application.Queries;
using Chillax.Rooms.Domain.AggregatesModel.ReservationAggregate;
using Chillax.Rooms.Domain.AggregatesModel.RoomAggregate;
using Chillax.Rooms.API.Infrastructure;
using Chillax.Rooms.Infrastructure;
using Chillax.Rooms.Infrastructure.Idempotency;
using Chillax.Rooms.Infrastructure.Repositories;
using RoomsContext = Chillax.Rooms.Infrastructure.RoomsContext;

namespace Chillax.Rooms.API.Extensions;

public static class Extensions
{
    public static void AddApplicationServices(this IHostApplicationBuilder builder)
    {
        builder.AddDefaultAuthentication();

        // Avoid loading full database config and migrations if startup
        // is being invoked from build-time OpenAPI generation
        if (builder.Environment.IsBuild())
        {
            builder.Services.AddDbContext<RoomsContext>();
            return;
        }

        builder.AddNpgsqlDbContext<RoomsContext>("roomsdb", configureDbContextOptions: options =>
        {
            // Ensure the schema is created for the new DDD model
        });

        // REVIEW: This is done for development ease but shouldn't be here in production
        builder.Services.AddMigration<RoomsContext, RoomsContextSeed>();

        // Add MediatR for CQRS
        builder.Services.AddMediatR(cfg =>
        {
            cfg.RegisterServicesFromAssemblyContaining(typeof(Program));
        });

        // Register repositories
        builder.Services.AddScoped<IRoomRepository, RoomRepository>();
        builder.Services.AddScoped<IReservationRepository, ReservationRepository>();
        builder.Services.AddScoped<IRequestManager, RequestManager>();

        // Register queries
        builder.Services.AddScoped<IRoomQueries, RoomQueries>();

        // Register background services
        builder.Services.AddHostedService<ReservationExpirationService>();

        // Add RabbitMQ event bus for publishing room availability events
        builder.AddRabbitMqEventBus("eventbus")
            .ConfigureJsonOptions(options =>
                options.TypeInfoResolverChain.Add(RoomsIntegrationEventContext.Default));
    }
}

[JsonSerializable(typeof(RoomBecameAvailableIntegrationEvent))]
[JsonSerializable(typeof(SessionCompletedIntegrationEvent))]
[JsonSerializable(typeof(SessionStartedIntegrationEvent))]
public partial class RoomsIntegrationEventContext : JsonSerializerContext
{
}
