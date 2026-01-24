using Microsoft.EntityFrameworkCore.Design;

namespace Chillax.Rooms.Infrastructure;

/// <summary>
/// Design-time factory for creating RoomsContext for EF migrations
/// </summary>
public class RoomsContextDesignFactory : IDesignTimeDbContextFactory<RoomsContext>
{
    public RoomsContext CreateDbContext(string[] args)
    {
        var optionsBuilder = new DbContextOptionsBuilder<RoomsContext>();
        optionsBuilder.UseNpgsql("Host=localhost;Database=rooms;Username=postgres;Password=postgres");

        return new RoomsContext(optionsBuilder.Options);
    }
}
