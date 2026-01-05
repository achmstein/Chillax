using Chillax.Rooms.API.Infrastructure.EntityConfigurations;
using Chillax.Rooms.API.Model;
using Microsoft.EntityFrameworkCore;

namespace Chillax.Rooms.API.Infrastructure;

/// <remarks>
/// Add migrations using the following command inside the 'Rooms.API' project directory:
///
/// dotnet ef migrations add --context RoomsContext [migration-name]
/// </remarks>
public class RoomsContext : DbContext
{
    public RoomsContext(DbContextOptions<RoomsContext> options) : base(options)
    {
    }

    public required DbSet<Room> Rooms { get; set; }
    public required DbSet<RoomSession> RoomSessions { get; set; }

    protected override void OnModelCreating(ModelBuilder builder)
    {
        builder.ApplyConfiguration(new RoomEntityTypeConfiguration());
        builder.ApplyConfiguration(new RoomSessionEntityTypeConfiguration());
    }
}
