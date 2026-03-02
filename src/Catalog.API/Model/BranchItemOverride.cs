namespace Chillax.Catalog.API.Model;

/// <summary>
/// Per-branch override for a catalog item's availability and pricing.
/// If no override row exists for a branch+item combination, the global values apply.
/// </summary>
public class BranchItemOverride
{
    public int Id { get; set; }
    public int BranchId { get; set; }
    public int CatalogItemId { get; set; }
    public CatalogItem CatalogItem { get; set; } = null!;

    /// <summary>
    /// Whether this item is available at this branch
    /// </summary>
    public bool IsAvailable { get; set; } = true;

    /// <summary>
    /// Branch-specific price override (null = use global price)
    /// </summary>
    public decimal? PriceOverride { get; set; }

    /// <summary>
    /// Branch-specific offer price override (null = use global offer price)
    /// </summary>
    public decimal? OfferPriceOverride { get; set; }

    /// <summary>
    /// Branch-specific offer status override (null = use global)
    /// </summary>
    public bool? IsOnOfferOverride { get; set; }
}
