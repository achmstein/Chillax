using Chillax.Accounts.API.Application.Queries;
using Chillax.Accounts.Domain.AggregatesModel.CustomerAccountAggregate;
using Chillax.Accounts.Infrastructure;
using Chillax.Accounts.Infrastructure.Repositories;
using Chillax.ServiceDefaults;

namespace Chillax.Accounts.API.Extensions;

public static class Extensions
{
    public static void AddApplicationServices(this IHostApplicationBuilder builder)
    {
        builder.AddDefaultAuthentication();

        if (builder.Environment.IsBuild())
        {
            builder.Services.AddDbContext<AccountsContext>();
            builder.Services.AddAuthentication();
            builder.Services.AddAuthorization();
            return;
        }

        builder.AddNpgsqlDbContext<AccountsContext>("accountsdb", configureDbContextOptions: options =>
        {
        });

        builder.Services.AddMigration<AccountsContext>();

        builder.Services.AddMediatR(cfg =>
        {
            cfg.RegisterServicesFromAssemblyContaining(typeof(Program));
        });

        builder.Services.AddScoped<ICustomerAccountRepository, CustomerAccountRepository>();
        builder.Services.AddScoped<IAccountQueries, AccountQueries>();
    }
}
