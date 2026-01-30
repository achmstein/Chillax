namespace Chillax.Catalog.API.Infrastructure.EntityConfigurations;

class CustomizationOptionEntityTypeConfiguration
    : IEntityTypeConfiguration<CustomizationOption>
{
    public void Configure(EntityTypeBuilder<CustomizationOption> builder)
    {
        builder.ToTable("CustomizationOptions");

        builder.Property(co => co.Name)
            .HasMaxLength(100)
            .IsRequired();

        builder.Property(co => co.NameAr)
            .HasMaxLength(100);

        builder.Property(co => co.PriceAdjustment)
            .HasPrecision(18, 2);

        builder.HasIndex(co => new { co.ItemCustomizationId, co.DisplayOrder });
    }
}
