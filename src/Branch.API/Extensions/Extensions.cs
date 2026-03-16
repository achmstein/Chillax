using System.Text.Json.Serialization;
using Chillax.Branch.API.IntegrationEvents;

namespace Chillax.Branch.API.Extensions;

public static class Extensions
{
    public static void AddApplicationServices(this IHostApplicationBuilder builder)
    {
        builder.AddNpgsqlDbContext<BranchContext>("branchdb", configureDbContextOptions: options =>
        {
            options.UseNpgsql(builder => builder.MigrationsAssembly(typeof(BranchContext).Assembly.FullName));
        });

        builder.Services.AddMigration<BranchContext, BranchContextSeed>();

        builder.AddRabbitMqEventBus("eventbus")
            .ConfigureJsonOptions(options =>
                options.TypeInfoResolverChain.Add(BranchIntegrationEventContext.Default));
    }
}

[JsonSerializable(typeof(BranchSettingsChangedIntegrationEvent))]
public partial class BranchIntegrationEventContext : JsonSerializerContext
{
}
