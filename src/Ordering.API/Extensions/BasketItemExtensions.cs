#nullable enable
namespace Chillax.Ordering.API.Extensions;

public static class BasketItemExtensions
{
    public static IEnumerable<OrderItemDTO> ToOrderItemsDTO(this IEnumerable<BasketItem> basketItems)
    {
        foreach (var item in basketItems)
        {
            yield return item.ToOrderItemDTO();
        }
    }

    public static OrderItemDTO ToOrderItemDTO(this BasketItem item)
    {
        // Build customizations description
        string? customizationsDescription = null;
        if (item.SelectedCustomizations.Count > 0)
        {
            customizationsDescription = string.Join(", ",
                item.SelectedCustomizations.Select(c => $"{c.CustomizationName}: {c.OptionName}"));
        }

        return new OrderItemDTO()
        {
            ProductId = item.ProductId,
            ProductName = item.ProductName,
            PictureUrl = item.PictureUrl,
            // Use TotalPrice which includes customization adjustments
            UnitPrice = item.TotalPrice,
            Units = item.Quantity,
            SpecialInstructions = item.SpecialInstructions,
            CustomizationsDescription = customizationsDescription
        };
    }
}
