namespace Chillax.Catalog.API.Infrastructure.EntityConfigurations;

class ItemCustomizationEntityTypeConfiguration
    : IEntityTypeConfiguration<ItemCustomization>
{
    public void Configure(EntityTypeBuilder<ItemCustomization> builder)
    {
        builder.ToTable("ItemCustomizations");

        builder.Property(ic => ic.Name)
            .HasMaxLength(100)
            .IsRequired();

        builder.HasMany(ic => ic.Options)
            .WithOne(o => o.ItemCustomization)
            .HasForeignKey(o => o.ItemCustomizationId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(ic => new { ic.CatalogItemId, ic.DisplayOrder });
    }
}
