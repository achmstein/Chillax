namespace Chillax.Catalog.API.Infrastructure.EntityConfigurations;

class BundleDealEntityTypeConfiguration
    : IEntityTypeConfiguration<BundleDeal>
{
    public void Configure(EntityTypeBuilder<BundleDeal> builder)
    {
        builder.ToTable("BundleDeals");

        builder.OwnsOne(b => b.Name, b => b.ToJson());
        builder.OwnsOne(b => b.Description, b => b.ToJson());

        builder.Property(b => b.BundlePrice)
            .HasPrecision(18, 2);

        builder.HasMany(b => b.Items)
            .WithOne(i => i.BundleDeal)
            .HasForeignKey(i => i.BundleDealId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(b => b.IsActive);
    }
}
