using Chillax.Rooms.API.Model;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Chillax.Rooms.API.Infrastructure.EntityConfigurations;

class RoomSessionEntityTypeConfiguration : IEntityTypeConfiguration<RoomSession>
{
    public void Configure(EntityTypeBuilder<RoomSession> builder)
    {
        builder.ToTable("RoomSessions");

        builder.Property(s => s.CustomerId)
            .HasMaxLength(100)
            .IsRequired();

        builder.Property(s => s.CustomerName)
            .HasMaxLength(200);

        builder.Property(s => s.TotalCost)
            .HasPrecision(18, 2);

        builder.Property(s => s.Notes)
            .HasMaxLength(500);

        builder.HasIndex(s => s.CustomerId);
        builder.HasIndex(s => s.Status);
        builder.HasIndex(s => new { s.RoomId, s.Status });
    }
}
