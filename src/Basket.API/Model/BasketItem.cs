#nullable enable
namespace Chillax.Basket.API.Model;

/// <summary>
/// Represents an item in the customer's basket.
/// Enhanced for cafe menu with customization support.
/// </summary>
public class BasketItem : IValidatableObject
{
    public string Id { get; set; } = string.Empty;
    public int ProductId { get; set; }
    public string ProductName { get; set; } = string.Empty;

    /// <summary>
    /// Base unit price before customizations
    /// </summary>
    public decimal UnitPrice { get; set; }

    public decimal OldUnitPrice { get; set; }
    public int Quantity { get; set; }
    public string PictureUrl { get; set; } = string.Empty;

    /// <summary>
    /// Special instructions from the customer (e.g., "extra hot", "no ice")
    /// </summary>
    public string? SpecialInstructions { get; set; }

    /// <summary>
    /// Selected customization options for this item
    /// </summary>
    public List<BasketItemCustomization> SelectedCustomizations { get; set; } = new();

    /// <summary>
    /// Calculated total price including customization adjustments
    /// </summary>
    public decimal TotalPrice => UnitPrice + SelectedCustomizations.Sum(c => c.PriceAdjustment);

    /// <summary>
    /// Line total (TotalPrice * Quantity)
    /// </summary>
    public decimal LineTotal => TotalPrice * Quantity;

    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        var results = new List<ValidationResult>();

        if (Quantity < 1)
        {
            results.Add(new ValidationResult("Invalid number of units", new[] { "Quantity" }));
        }

        return results;
    }
}
