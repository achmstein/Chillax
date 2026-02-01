using Chillax.Catalog.API.Model;

namespace Chillax.Catalog.API.Dtos;

/// <summary>
/// DTO for catalog item (menu item)
/// </summary>
public record CatalogItemDto
{
    public int Id { get; init; }
    public LocalizedText Name { get; init; } = new();
    public LocalizedText Description { get; init; } = new();
    public decimal Price { get; init; }
    public string? PictureUri { get; init; }
    public int CatalogTypeId { get; init; }
    public LocalizedText CatalogTypeName { get; init; } = new();
    public bool IsAvailable { get; init; }
    public int? PreparationTimeMinutes { get; init; }
    public int DisplayOrder { get; init; }
    public List<ItemCustomizationDto> Customizations { get; init; } = new();
}

/// <summary>
/// DTO for catalog type (category)
/// </summary>
public record CatalogTypeDto
{
    public int Id { get; init; }
    public LocalizedText Name { get; init; } = new();
    public int DisplayOrder { get; init; }
}

/// <summary>
/// DTO for item customization group
/// </summary>
public record ItemCustomizationDto
{
    public int Id { get; init; }
    public LocalizedText Name { get; init; } = new();
    public bool IsRequired { get; init; }
    public bool AllowMultiple { get; init; }
    public List<CustomizationOptionDto> Options { get; init; } = new();
}

/// <summary>
/// DTO for customization option
/// </summary>
public record CustomizationOptionDto
{
    public int Id { get; init; }
    public LocalizedText Name { get; init; } = new();
    public decimal PriceAdjustment { get; init; }
    public bool IsDefault { get; init; }
}

/// <summary>
/// Paginated items response
/// </summary>
public record PaginatedItemsDto<T>
{
    public int PageIndex { get; init; }
    public int PageSize { get; init; }
    public long Count { get; init; }
    public List<T> Data { get; init; } = new();

    public PaginatedItemsDto(int pageIndex, int pageSize, long count, List<T> data)
    {
        PageIndex = pageIndex;
        PageSize = pageSize;
        Count = count;
        Data = data;
    }
}

/// <summary>
/// DTO for user's item preference
/// </summary>
public record UserItemPreferenceDto
{
    public int CatalogItemId { get; init; }
    public DateTime LastUpdated { get; init; }
    public List<UserPreferenceOptionDto> SelectedOptions { get; init; } = new();
}

/// <summary>
/// DTO for a selected option in user preference
/// </summary>
public record UserPreferenceOptionDto
{
    public int CustomizationId { get; init; }
    public int OptionId { get; init; }
}

/// <summary>
/// Request to save user preferences for multiple items
/// </summary>
public record SaveUserPreferencesRequest
{
    public List<SaveItemPreference> Items { get; init; } = new();
}

/// <summary>
/// Preference data for a single item
/// </summary>
public record SaveItemPreference
{
    public int CatalogItemId { get; init; }
    public List<UserPreferenceOptionDto> SelectedOptions { get; init; } = new();
}
