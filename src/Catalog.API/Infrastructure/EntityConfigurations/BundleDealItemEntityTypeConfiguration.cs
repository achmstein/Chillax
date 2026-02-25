namespace Chillax.Catalog.API.Infrastructure.EntityConfigurations;

class BundleDealItemEntityTypeConfiguration
    : IEntityTypeConfiguration<BundleDealItem>
{
    public void Configure(EntityTypeBuilder<BundleDealItem> builder)
    {
        builder.ToTable("BundleDealItems");

        builder.HasOne(i => i.CatalogItem)
            .WithMany()
            .HasForeignKey(i => i.CatalogItemId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
