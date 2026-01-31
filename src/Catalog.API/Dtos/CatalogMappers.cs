using Chillax.Catalog.API.Model;

namespace Chillax.Catalog.API.Dtos;

/// <summary>
/// Extension methods for mapping entities to DTOs
/// </summary>
public static class CatalogMappers
{
    public static CatalogItemDto ToDto(this CatalogItem item, string? baseUrl = null)
    {
        return new CatalogItemDto
        {
            Id = item.Id,
            Name = item.Name,
            NameAr = item.NameAr,
            Description = item.Description,
            DescriptionAr = item.DescriptionAr,
            Price = item.Price,
            PictureUri = string.IsNullOrEmpty(item.PictureFileName)
                ? null
                : $"{baseUrl}/api/catalog/items/{item.Id}/pic",
            CatalogTypeId = item.CatalogTypeId,
            CatalogTypeName = item.CatalogType?.Type ?? string.Empty,
            CatalogTypeNameAr = item.CatalogType?.TypeAr,
            IsAvailable = item.IsAvailable,
            PreparationTimeMinutes = item.PreparationTimeMinutes,
            Customizations = item.Customizations.Select(c => c.ToDto()).ToList()
        };
    }

    public static List<CatalogItemDto> ToDtoList(this IEnumerable<CatalogItem> items, string? baseUrl = null)
    {
        return items.Select(i => i.ToDto(baseUrl)).ToList();
    }

    public static CatalogTypeDto ToDto(this CatalogType type)
    {
        return new CatalogTypeDto
        {
            Id = type.Id,
            Type = type.Type,
            TypeAr = type.TypeAr
        };
    }

    public static List<CatalogTypeDto> ToDtoList(this IEnumerable<CatalogType> types)
    {
        return types.Select(t => t.ToDto()).ToList();
    }

    public static ItemCustomizationDto ToDto(this ItemCustomization customization)
    {
        return new ItemCustomizationDto
        {
            Id = customization.Id,
            Name = customization.Name,
            NameAr = customization.NameAr,
            IsRequired = customization.IsRequired,
            AllowMultiple = customization.AllowMultiple,
            Options = customization.Options.OrderBy(o => o.DisplayOrder).Select(o => o.ToDto()).ToList()
        };
    }

    public static List<ItemCustomizationDto> ToDtoList(this IEnumerable<ItemCustomization> customizations)
    {
        return customizations.Select(c => c.ToDto()).ToList();
    }

    public static CustomizationOptionDto ToDto(this CustomizationOption option)
    {
        return new CustomizationOptionDto
        {
            Id = option.Id,
            Name = option.Name,
            NameAr = option.NameAr,
            PriceAdjustment = option.PriceAdjustment,
            IsDefault = option.IsDefault
        };
    }

    public static UserItemPreferenceDto ToDto(this UserItemPreference preference)
    {
        return new UserItemPreferenceDto
        {
            CatalogItemId = preference.CatalogItemId,
            LastUpdated = preference.LastUpdated,
            SelectedOptions = preference.SelectedOptions
                .Select(o => new UserPreferenceOptionDto
                {
                    CustomizationId = o.CustomizationId,
                    OptionId = o.OptionId
                })
                .ToList()
        };
    }

    public static List<UserItemPreferenceDto> ToDtoList(this IEnumerable<UserItemPreference> preferences)
    {
        return preferences.Select(p => p.ToDto()).ToList();
    }
}
