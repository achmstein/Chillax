using Chillax.Rooms.API.Model;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Chillax.Rooms.API.Infrastructure.EntityConfigurations;

class RoomEntityTypeConfiguration : IEntityTypeConfiguration<Room>
{
    public void Configure(EntityTypeBuilder<Room> builder)
    {
        builder.ToTable("Rooms");

        // Configure Name as JSON column
        builder.OwnsOne(r => r.Name, b => b.ToJson());

        // Configure Description as JSON column
        builder.OwnsOne(r => r.Description, b => b.ToJson());

        builder.Property(r => r.HourlyRate)
            .HasPrecision(18, 2);

        builder.HasMany(r => r.Sessions)
            .WithOne(s => s.Room)
            .HasForeignKey(s => s.RoomId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(r => r.Status);
    }
}
