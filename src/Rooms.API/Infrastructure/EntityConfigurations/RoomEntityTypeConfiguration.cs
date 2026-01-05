using Chillax.Rooms.API.Model;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Chillax.Rooms.API.Infrastructure.EntityConfigurations;

class RoomEntityTypeConfiguration : IEntityTypeConfiguration<Room>
{
    public void Configure(EntityTypeBuilder<Room> builder)
    {
        builder.ToTable("Rooms");

        builder.Property(r => r.Name)
            .HasMaxLength(100)
            .IsRequired();

        builder.Property(r => r.Description)
            .HasMaxLength(500);

        builder.Property(r => r.HourlyRate)
            .HasPrecision(18, 2);

        builder.HasMany(r => r.Sessions)
            .WithOne(s => s.Room)
            .HasForeignKey(s => s.RoomId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(r => r.Name);
        builder.HasIndex(r => r.Status);
    }
}
