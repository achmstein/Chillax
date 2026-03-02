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
    }
}
