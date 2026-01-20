namespace Chillax.Rooms.Infrastructure.EntityConfigurations;

class RoomEntityTypeConfiguration : IEntityTypeConfiguration<Room>
{
    public void Configure(EntityTypeBuilder<Room> builder)
    {
        builder.ToTable("rooms");

        builder.HasKey(r => r.Id);

        builder.Property(r => r.Id)
            .UseHiLo("roomseq", "rooms");

        builder.Ignore(r => r.DomainEvents);

        builder.Property(r => r.Name)
            .IsRequired()
            .HasMaxLength(100);

        builder.Property(r => r.Description)
            .HasMaxLength(500);

        builder.Property(r => r.HourlyRate)
            .HasPrecision(18, 2)
            .IsRequired();

        builder.Property(r => r.PhysicalStatus)
            .HasConversion<string>()
            .HasMaxLength(20)
            .IsRequired();

        // Indexes
        builder.HasIndex(r => r.Name);
        builder.HasIndex(r => r.PhysicalStatus);
    }
}
