namespace Chillax.Rooms.Infrastructure.EntityConfigurations;

class ReservationEntityTypeConfiguration : IEntityTypeConfiguration<Reservation>
{
    public void Configure(EntityTypeBuilder<Reservation> builder)
    {
        builder.ToTable("reservations");

        builder.HasKey(r => r.Id);

        builder.Property(r => r.Id)
            .UseHiLo("reservationseq", "rooms");

        builder.Ignore(r => r.DomainEvents);

        builder.Property(r => r.CustomerId)
            .HasMaxLength(100);

        builder.Property(r => r.AccessCode)
            .HasMaxLength(6);

        builder.Property(r => r.AccessCodeGeneratedAt);

        builder.Property(r => r.CustomerName)
            .HasMaxLength(200);

        builder.Property(r => r.CreatedAt)
            .IsRequired();

        builder.Property(r => r.ExpiresAt);

        builder.Property(r => r.ActualStartTime);

        builder.Property(r => r.EndTime);

        builder.Property(r => r.HourlyRate)
            .HasPrecision(18, 2)
            .IsRequired();

        builder.Property(r => r.TotalCost)
            .HasPrecision(18, 2);

        builder.Property(r => r.Status)
            .HasConversion<string>()
            .HasMaxLength(20)
            .IsRequired();

        builder.Property(r => r.Notes)
            .HasMaxLength(500);

        // Relationships
        builder.HasOne(r => r.Room)
            .WithMany()
            .HasForeignKey(r => r.RoomId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasMany(r => r.SessionMembers)
            .WithOne()
            .HasForeignKey(sm => sm.ReservationId)
            .OnDelete(DeleteBehavior.Cascade);

        // Configure access to the backing field for SessionMembers
        builder.Navigation(r => r.SessionMembers)
            .UsePropertyAccessMode(PropertyAccessMode.Field);

        // Indexes
        builder.HasIndex(r => r.CustomerId);
        builder.HasIndex(r => r.Status);
        builder.HasIndex(r => r.CreatedAt);
        builder.HasIndex(r => new { r.RoomId, r.Status });
        builder.HasIndex(r => new { r.CustomerId, r.Status });
        builder.HasIndex(r => r.AccessCode);
        builder.HasIndex(r => new { r.Status, r.ExpiresAt });
    }
}

