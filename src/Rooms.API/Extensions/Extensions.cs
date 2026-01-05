using Chillax.Rooms.API.Infrastructure;

namespace Chillax.Rooms.API.Extensions;

public static class Extensions
{
    public static void AddApplicationServices(this IHostApplicationBuilder builder)
    {
        // Avoid loading full database config and migrations if startup
        // is being invoked from build-time OpenAPI generation
        if (builder.Environment.IsBuild())
        {
            builder.Services.AddDbContext<RoomsContext>();
            return;
        }

        builder.AddNpgsqlDbContext<RoomsContext>("roomsdb");

        // REVIEW: This is done for development ease but shouldn't be here in production
        builder.Services.AddMigration<RoomsContext, RoomsContextSeed>();
    }
}
