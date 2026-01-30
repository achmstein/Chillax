namespace Chillax.Catalog.API.Infrastructure.EntityConfigurations;

class CatalogItemEntityTypeConfiguration
    : IEntityTypeConfiguration<CatalogItem>
{
    public void Configure(EntityTypeBuilder<CatalogItem> builder)
    {
        builder.ToTable("Catalog");

        builder.Property(ci => ci.Name)
            .HasMaxLength(100);

        builder.Property(ci => ci.NameAr)
            .HasMaxLength(100);

        builder.Property(ci => ci.Description)
            .HasMaxLength(500);

        builder.Property(ci => ci.DescriptionAr)
            .HasMaxLength(500);

        builder.Property(ci => ci.Price)
            .HasPrecision(18, 2);

        builder.HasOne(ci => ci.CatalogType)
            .WithMany()
            .HasForeignKey(ci => ci.CatalogTypeId);

        builder.HasMany(ci => ci.Customizations)
            .WithOne(c => c.CatalogItem)
            .HasForeignKey(c => c.CatalogItemId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(ci => ci.Name);
        builder.HasIndex(ci => ci.IsAvailable);
    }
}
