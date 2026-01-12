using Chillax.Notification.API.Model;

namespace Chillax.Notification.API.Infrastructure;

public class NotificationContext(DbContextOptions<NotificationContext> options) : DbContext(options)
{
    public DbSet<NotificationSubscription> Subscriptions => Set<NotificationSubscription>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<NotificationSubscription>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.UserId).IsRequired();
            entity.Property(e => e.FcmToken).IsRequired();
            entity.Property(e => e.Type).IsRequired();
            entity.Property(e => e.CreatedAt).IsRequired();

            // Index for efficient lookups by user
            entity.HasIndex(e => e.UserId);

            // Index for efficient lookups by type
            entity.HasIndex(e => e.Type);

            // Unique constraint: one subscription per user per type
            entity.HasIndex(e => new { e.UserId, e.Type }).IsUnique();
        });
    }
}

public class NotificationContextSeed(ILogger<NotificationContextSeed> logger) : IDbSeeder<NotificationContext>
{
    public Task SeedAsync(NotificationContext context)
    {
        logger.LogInformation("Notification database ready (no seed data required)");
        return Task.CompletedTask;
    }
}
