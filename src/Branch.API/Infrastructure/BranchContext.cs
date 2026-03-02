using Chillax.Branch.API.Model;

namespace Chillax.Branch.API.Infrastructure;

public class BranchContext(DbContextOptions<BranchContext> options) : DbContext(options)
{
    public DbSet<Model.Branch> Branches => Set<Model.Branch>();
    public DbSet<AdminBranchAssignment> AdminBranchAssignments => Set<AdminBranchAssignment>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Model.Branch>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.OwnsOne(e => e.Name, b => b.ToJson());
            entity.OwnsOne(e => e.Address, b => b.ToJson());
            entity.Property(e => e.Phone).HasMaxLength(20);
            entity.Property(e => e.IsActive).IsRequired();
            entity.Property(e => e.DisplayOrder).IsRequired();

            entity.HasIndex(e => e.IsActive);
            entity.HasIndex(e => e.DisplayOrder);
        });

        modelBuilder.Entity<AdminBranchAssignment>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.AdminUserId).IsRequired().HasMaxLength(256);

            entity.HasOne(e => e.Branch)
                .WithMany()
                .HasForeignKey(e => e.BranchId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasIndex(e => new { e.AdminUserId, e.BranchId }).IsUnique();
            entity.HasIndex(e => e.AdminUserId);
        });
    }
}

public class BranchContextSeed(ILogger<BranchContextSeed> logger) : IDbSeeder<BranchContext>
{
    public async Task SeedAsync(BranchContext context)
    {
        if (!await context.Branches.AnyAsync())
        {
            context.Branches.AddRange(
                new Model.Branch
                {
                    Name = new LocalizedText("El-Manshia", "المنشية"),
                    IsActive = true,
                    DisplayOrder = 1
                },
                new Model.Branch
                {
                    Name = new LocalizedText("El-Benzina", "البنزينة"),
                    IsActive = true,
                    DisplayOrder = 2
                }
            );
            await context.SaveChangesAsync();
            logger.LogInformation("Seeded default branches");
        }
    }
}
