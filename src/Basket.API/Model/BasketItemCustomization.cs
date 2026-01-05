namespace Chillax.Basket.API.Model;

/// <summary>
/// Represents a selected customization option for a basket item.
/// Used for cafe menu customizations like roasting level, sugar, milk type, etc.
/// </summary>
public class BasketItemCustomization
{
    /// <summary>
    /// The ID of the customization group (e.g., "Roasting", "Sugar Level")
    /// </summary>
    public int CustomizationId { get; set; }

    /// <summary>
    /// Display name of the customization group
    /// </summary>
    public string CustomizationName { get; set; } = string.Empty;

    /// <summary>
    /// The ID of the selected option within the customization group
    /// </summary>
    public int OptionId { get; set; }

    /// <summary>
    /// Display name of the selected option (e.g., "Dark Roast", "No Sugar")
    /// </summary>
    public string OptionName { get; set; } = string.Empty;

    /// <summary>
    /// Price adjustment for this customization option (can be 0, positive, or negative)
    /// </summary>
    public decimal PriceAdjustment { get; set; }
}
