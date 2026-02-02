namespace Chillax.Catalog.API.Model;

/// <summary>
/// Represents a menu item in the cafe catalog (drinks, food, snacks, desserts)
/// </summary>
public class CatalogItem
{
    public int Id { get; set; }

    /// <summary>
    /// Localized name of the menu item
    /// </summary>
    public LocalizedText Name { get; set; } = new();

    /// <summary>
    /// Localized description of the menu item
    /// </summary>
    public LocalizedText Description { get; set; } = new();

    public decimal Price { get; set; }

    public string? PictureFileName { get; set; }

    public int CatalogTypeId { get; set; }

    public CatalogType? CatalogType { get; set; }

    /// <summary>
    /// Indicates if the item is currently available for ordering
    /// </summary>
    public bool IsAvailable { get; set; } = true;

    /// <summary>
    /// Estimated preparation time in minutes (optional)
    /// </summary>
    public int? PreparationTimeMinutes { get; set; }

    /// <summary>
    /// Display order within the category (lower numbers appear first)
    /// </summary>
    public int DisplayOrder { get; set; }

    /// <summary>
    /// Available customization options for this item (e.g., size, sugar level, roasting)
    /// </summary>
    public ICollection<ItemCustomization> Customizations { get; set; } = new List<ItemCustomization>();

    /// <summary>
    /// Required for EF Core
    /// </summary>
    private CatalogItem() { }

    public CatalogItem(string name, string? description = null)
    {
        Name = new LocalizedText(name);
        Description = new LocalizedText(description ?? string.Empty);
    }

    public CatalogItem(LocalizedText name, LocalizedText? description = null)
    {
        Name = name;
        Description = description ?? new LocalizedText(string.Empty);
    }
}
