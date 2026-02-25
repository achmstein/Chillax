namespace Chillax.Catalog.API.Model;

/// <summary>
/// Represents a single item within a bundle deal
/// </summary>
public class BundleDealItem
{
    public int Id { get; set; }

    public int BundleDealId { get; set; }

    public BundleDeal? BundleDeal { get; set; }

    public int CatalogItemId { get; set; }

    public CatalogItem? CatalogItem { get; set; }

    /// <summary>
    /// Quantity of this item in the bundle
    /// </summary>
    public int Quantity { get; set; } = 1;
}
