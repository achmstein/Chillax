using System.ComponentModel.DataAnnotations;

namespace Chillax.Catalog.API.Model;

/// <summary>
/// Represents a menu item in the cafe catalog (drinks, food, snacks, desserts)
/// </summary>
public class CatalogItem
{
    public int Id { get; set; }

    [Required]
    public string Name { get; set; }

    public string? Description { get; set; }

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
    /// Available customization options for this item (e.g., size, sugar level, roasting)
    /// </summary>
    public ICollection<ItemCustomization> Customizations { get; set; } = new List<ItemCustomization>();

    public CatalogItem(string name)
    {
        Name = name;
    }
}
