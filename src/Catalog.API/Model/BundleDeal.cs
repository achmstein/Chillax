using System.Text.Json.Serialization;

namespace Chillax.Catalog.API.Model;

/// <summary>
/// Represents a bundle deal (combo) offering multiple items at a special price
/// </summary>
public class BundleDeal
{
    public int Id { get; set; }

    /// <summary>
    /// Localized name of the bundle
    /// </summary>
    public LocalizedText Name { get; set; } = new();

    /// <summary>
    /// Localized description of the bundle
    /// </summary>
    public LocalizedText Description { get; set; } = new();

    /// <summary>
    /// The special bundle price
    /// </summary>
    public decimal BundlePrice { get; set; }

    /// <summary>
    /// Optional picture file name
    /// </summary>
    public string? PictureFileName { get; set; }

    /// <summary>
    /// Whether this bundle is currently active and visible to customers
    /// </summary>
    public bool IsActive { get; set; }

    /// <summary>
    /// Display order (lower numbers appear first)
    /// </summary>
    public int DisplayOrder { get; set; }

    /// <summary>
    /// Items included in this bundle
    /// </summary>
    public ICollection<BundleDealItem> Items { get; set; } = new List<BundleDealItem>();

    /// <summary>
    /// Required for EF Core
    /// </summary>
    private BundleDeal() { }

    [JsonConstructor]
    public BundleDeal(LocalizedText name, LocalizedText? description = null)
    {
        Name = name;
        Description = description ?? new LocalizedText(string.Empty);
    }
}
