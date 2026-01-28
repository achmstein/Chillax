using System.ComponentModel;
using System.ComponentModel.DataAnnotations;
using System.Security.Claims;
using Chillax.Catalog.API.Dtos;
using Chillax.ServiceDefaults;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Mvc;

namespace Chillax.Catalog.API;

public static class CatalogApi
{
    public static IEndpointRouteBuilder MapCatalogApi(this IEndpointRouteBuilder app)
    {
        var vApi = app.NewVersionedApi("Catalog");
        var api = vApi.MapGroup("api/catalog").HasApiVersion(1, 0);

        // Menu Items endpoints
        api.MapGet("/items", GetAllItems)
            .WithName("ListItems")
            .WithSummary("List menu items")
            .WithDescription("Get a paginated list of menu items")
            .WithTags("Items");

        api.MapGet("/items/by", GetItemsByIds)
            .WithName("BatchGetItems")
            .WithSummary("Batch get menu items")
            .WithDescription("Get multiple items by IDs")
            .WithTags("Items");

        api.MapGet("/items/{id:int}", GetItemById)
            .WithName("GetItem")
            .WithSummary("Get menu item")
            .WithDescription("Get a menu item by ID")
            .WithTags("Items");

        api.MapGet("/items/by/{name:minlength(1)}", GetItemsByName)
            .WithName("GetItemsByName")
            .WithSummary("Search menu items by name")
            .WithDescription("Get a paginated list of menu items matching the name")
            .WithTags("Items");

        api.MapGet("/items/{id:int}/pic", GetItemPictureById)
            .WithName("GetItemPicture")
            .WithSummary("Get menu item picture")
            .WithDescription("Get the picture for a menu item")
            .WithTags("Items");

        api.MapGet("/items/type/{typeId}", GetItemsByType)
            .WithName("GetItemsByType")
            .WithSummary("Get menu items by category")
            .WithDescription("Get menu items of the specified category")
            .WithTags("Categories");

        api.MapGet("/items/available", GetAvailableItems)
            .WithName("GetAvailableItems")
            .WithSummary("Get available menu items")
            .WithDescription("Get only available menu items")
            .WithTags("Items");

        // Categories endpoints
        api.MapGet("/categories", GetCategories)
            .WithName("ListCategories")
            .WithSummary("List menu categories")
            .WithDescription("Get a list of menu categories (Drinks, Food, Snacks, Desserts)")
            .WithTags("Categories");

        api.MapGet("/categories/{id:int}", GetCategoryById)
            .WithName("GetCategory")
            .WithSummary("Get menu category")
            .WithDescription("Get a menu category by ID")
            .WithTags("Categories");

        api.MapPost("/categories", CreateCategory)
            .WithName("CreateCategory")
            .WithSummary("Create a menu category")
            .WithDescription("Create a new menu category")
            .WithTags("Categories");

        api.MapPut("/categories/{id:int}", UpdateCategory)
            .WithName("UpdateCategory")
            .WithSummary("Update a menu category")
            .WithDescription("Update an existing menu category")
            .WithTags("Categories");

        api.MapDelete("/categories/{id:int}", DeleteCategory)
            .WithName("DeleteCategory")
            .WithSummary("Delete menu category")
            .WithDescription("Delete the specified menu category")
            .WithTags("Categories");

        // CRUD endpoints
        api.MapPost("/items", CreateItem)
            .WithName("CreateItem")
            .WithSummary("Create a menu item")
            .WithDescription("Create a new menu item")
            .WithTags("Items");

        api.MapPut("/items/{id:int}", UpdateItem)
            .WithName("UpdateItem")
            .WithSummary("Update a menu item")
            .WithDescription("Update an existing menu item")
            .WithTags("Items");

        api.MapDelete("/items/{id:int}", DeleteItemById)
            .WithName("DeleteItem")
            .WithSummary("Delete menu item")
            .WithDescription("Delete the specified menu item")
            .WithTags("Items");

        api.MapPatch("/items/{id:int}/availability", ToggleItemAvailability)
            .WithName("ToggleItemAvailability")
            .WithSummary("Toggle item availability")
            .WithDescription("Toggle the availability of a menu item")
            .WithTags("Items");

        // Customization endpoints
        api.MapGet("/items/{id:int}/customizations", GetItemCustomizations)
            .WithName("GetItemCustomizations")
            .WithSummary("Get item customizations")
            .WithDescription("Get all customization options for a menu item")
            .WithTags("Customizations");

        // User preferences endpoints
        api.MapGet("/preferences/{catalogItemId:int}", GetUserPreference)
            .WithName("GetUserPreference")
            .WithSummary("Get user's saved preferences for a menu item")
            .WithDescription("Get the user's saved customization preferences for a specific menu item")
            .WithTags("Preferences")
            .RequireAuthorization();

        api.MapGet("/preferences", GetUserPreferences)
            .WithName("GetUserPreferences")
            .WithSummary("Get all user preferences")
            .WithDescription("Get all saved customization preferences for the current user")
            .WithTags("Preferences")
            .RequireAuthorization();

        api.MapPost("/preferences/batch", GetUserPreferencesForItems)
            .WithName("GetUserPreferencesForItems")
            .WithSummary("Get preferences for multiple items")
            .WithDescription("Get the user's saved preferences for a list of catalog item IDs")
            .WithTags("Preferences")
            .RequireAuthorization();

        api.MapPost("/preferences", SaveUserPreferences)
            .WithName("SaveUserPreferences")
            .WithSummary("Save user preferences")
            .WithDescription("Save the user's customization preferences for multiple items (called after successful order)")
            .WithTags("Preferences")
            .RequireAuthorization();

        // Favorites endpoints
        api.MapGet("/favorites", GetUserFavorites)
            .WithName("GetUserFavorites")
            .WithSummary("Get user's favorite items")
            .WithDescription("Get the list of catalog item IDs that the user has favorited")
            .WithTags("Favorites")
            .RequireAuthorization();

        api.MapPost("/favorites/{catalogItemId:int}", AddFavorite)
            .WithName("AddFavorite")
            .WithSummary("Add item to favorites")
            .WithDescription("Add a catalog item to the user's favorites")
            .WithTags("Favorites")
            .RequireAuthorization();

        api.MapDelete("/favorites/{catalogItemId:int}", RemoveFavorite)
            .WithName("RemoveFavorite")
            .WithSummary("Remove item from favorites")
            .WithDescription("Remove a catalog item from the user's favorites")
            .WithTags("Favorites")
            .RequireAuthorization();

        return app;
    }

    [ProducesResponseType<ProblemDetails>(StatusCodes.Status400BadRequest, "application/problem+json")]
    public static async Task<Ok<List<CatalogItemDto>>> GetAllItems(
        [AsParameters] CatalogServices services,
        HttpContext httpContext,
        [Description("Filter by category")] int? categoryId = null)
    {
        var baseUrl = GetBaseUrl(httpContext);

        var query = services.Context.CatalogItems
            .Include(c => c.CatalogType)
            .Include(c => c.Customizations)
                .ThenInclude(c => c.Options)
            .AsQueryable();

        if (categoryId.HasValue)
        {
            query = query.Where(c => c.CatalogTypeId == categoryId.Value);
        }

        var items = await query.OrderBy(c => c.Name).ToListAsync();
        return TypedResults.Ok(items.ToDtoList(baseUrl));
    }

    [ProducesResponseType<ProblemDetails>(StatusCodes.Status400BadRequest, "application/problem+json")]
    public static async Task<Ok<List<CatalogItemDto>>> GetAvailableItems(
        [AsParameters] CatalogServices services,
        HttpContext httpContext,
        [Description("Filter by category")] int? categoryId = null)
    {
        var baseUrl = GetBaseUrl(httpContext);

        var query = services.Context.CatalogItems
            .Include(c => c.CatalogType)
            .Include(c => c.Customizations)
                .ThenInclude(c => c.Options)
            .Where(c => c.IsAvailable);

        if (categoryId.HasValue)
        {
            query = query.Where(c => c.CatalogTypeId == categoryId.Value);
        }

        var items = await query.OrderBy(c => c.Name).ToListAsync();
        return TypedResults.Ok(items.ToDtoList(baseUrl));
    }

    [ProducesResponseType<ProblemDetails>(StatusCodes.Status400BadRequest, "application/problem+json")]
    public static async Task<Ok<List<CatalogItemDto>>> GetItemsByIds(
        [AsParameters] CatalogServices services,
        HttpContext httpContext,
        [Description("List of ids for menu items to return")] int[] ids)
    {
        var baseUrl = GetBaseUrl(httpContext);
        var items = await services.Context.CatalogItems
            .Include(c => c.CatalogType)
            .Include(c => c.Customizations)
                .ThenInclude(c => c.Options)
            .Where(item => ids.Contains(item.Id))
            .ToListAsync();
        return TypedResults.Ok(items.ToDtoList(baseUrl));
    }

    [ProducesResponseType<ProblemDetails>(StatusCodes.Status400BadRequest, "application/problem+json")]
    public static async Task<Results<Ok<CatalogItemDto>, NotFound, BadRequest<ProblemDetails>>> GetItemById(
        [AsParameters] CatalogServices services,
        HttpContext httpContext,
        [Description("The menu item id")] int id)
    {
        if (id <= 0)
        {
            return TypedResults.BadRequest<ProblemDetails>(new()
            {
                Detail = "Id is not valid"
            });
        }

        var baseUrl = GetBaseUrl(httpContext);
        var item = await services.Context.CatalogItems
            .Include(ci => ci.CatalogType)
            .Include(ci => ci.Customizations)
                .ThenInclude(c => c.Options)
            .SingleOrDefaultAsync(ci => ci.Id == id);

        if (item == null)
        {
            return TypedResults.NotFound();
        }

        return TypedResults.Ok(item.ToDto(baseUrl));
    }

    [ProducesResponseType<ProblemDetails>(StatusCodes.Status400BadRequest, "application/problem+json")]
    public static async Task<Ok<PaginatedItemsDto<CatalogItemDto>>> GetItemsByName(
        [AsParameters] PaginationRequest paginationRequest,
        [AsParameters] CatalogServices services,
        HttpContext httpContext,
        [Description("The name to search for")] string name)
    {
        var pageSize = paginationRequest.PageSize;
        var pageIndex = paginationRequest.PageIndex;
        var baseUrl = GetBaseUrl(httpContext);

        var query = services.Context.CatalogItems
            .Include(c => c.CatalogType)
            .Include(c => c.Customizations)
                .ThenInclude(c => c.Options)
            .Where(c => c.Name.ToLower().Contains(name.ToLower()));

        var totalItems = await query.LongCountAsync();

        var itemsOnPage = await query
            .OrderBy(c => c.Name)
            .Skip(pageSize * pageIndex)
            .Take(pageSize)
            .ToListAsync();

        var dtos = itemsOnPage.ToDtoList(baseUrl);
        return TypedResults.Ok(new PaginatedItemsDto<CatalogItemDto>(pageIndex, pageSize, totalItems, dtos));
    }

    [ProducesResponseType<ProblemDetails>(StatusCodes.Status400BadRequest, "application/problem+json")]
    public static async Task<Ok<PaginatedItemsDto<CatalogItemDto>>> GetItemsByType(
        [AsParameters] PaginationRequest paginationRequest,
        [AsParameters] CatalogServices services,
        HttpContext httpContext,
        [Description("The category id")] int typeId)
    {
        var pageSize = paginationRequest.PageSize;
        var pageIndex = paginationRequest.PageIndex;
        var baseUrl = GetBaseUrl(httpContext);

        var query = services.Context.CatalogItems
            .Include(c => c.CatalogType)
            .Include(c => c.Customizations)
                .ThenInclude(c => c.Options)
            .Where(c => c.CatalogTypeId == typeId);

        var totalItems = await query.LongCountAsync();

        var itemsOnPage = await query
            .OrderBy(c => c.Name)
            .Skip(pageSize * pageIndex)
            .Take(pageSize)
            .ToListAsync();

        var dtos = itemsOnPage.ToDtoList(baseUrl);
        return TypedResults.Ok(new PaginatedItemsDto<CatalogItemDto>(pageIndex, pageSize, totalItems, dtos));
    }

    [ProducesResponseType<byte[]>(StatusCodes.Status200OK, "application/octet-stream",
        ["image/png", "image/gif", "image/jpeg", "image/bmp", "image/tiff",
          "image/wmf", "image/jp2", "image/svg+xml", "image/webp"])]
    public static async Task<Results<PhysicalFileHttpResult, NotFound>> GetItemPictureById(
        CatalogContext context,
        IWebHostEnvironment environment,
        [Description("The menu item id")] int id)
    {
        var item = await context.CatalogItems.FindAsync(id);

        if (item is null || item.PictureFileName is null)
        {
            return TypedResults.NotFound();
        }

        var path = GetFullPath(environment.ContentRootPath, item.PictureFileName);

        string imageFileExtension = Path.GetExtension(item.PictureFileName) ?? string.Empty;
        string mimetype = GetImageMimeTypeFromImageFileExtension(imageFileExtension);
        DateTime lastModified = File.GetLastWriteTimeUtc(path);

        return TypedResults.PhysicalFile(path, mimetype, lastModified: lastModified);
    }

    public static async Task<Ok<List<CatalogTypeDto>>> GetCategories(CatalogContext context)
    {
        var categories = await context.CatalogTypes.OrderBy(x => x.Type).ToListAsync();
        return TypedResults.Ok(categories.ToDtoList());
    }

    public static async Task<Results<Ok<CatalogTypeDto>, NotFound>> GetCategoryById(
        CatalogContext context,
        [Description("The category id")] int id)
    {
        var category = await context.CatalogTypes.FindAsync(id);

        if (category is null)
        {
            return TypedResults.NotFound();
        }

        return TypedResults.Ok(category.ToDto());
    }

    public static async Task<Created<CatalogTypeDto>> CreateCategory(
        CatalogContext context,
        CatalogType category)
    {
        var newCategory = new CatalogType(category.Type);
        context.CatalogTypes.Add(newCategory);
        await context.SaveChangesAsync();

        return TypedResults.Created($"/api/catalog/categories/{newCategory.Id}", newCategory.ToDto());
    }

    public static async Task<Results<Ok<CatalogTypeDto>, NotFound>> UpdateCategory(
        CatalogContext context,
        [Description("The category id")] int id,
        CatalogType categoryToUpdate)
    {
        var category = await context.CatalogTypes.FindAsync(id);

        if (category is null)
        {
            return TypedResults.NotFound();
        }

        category.Type = categoryToUpdate.Type;
        await context.SaveChangesAsync();

        return TypedResults.Ok(category.ToDto());
    }

    public static async Task<Results<NoContent, NotFound, Conflict<ProblemDetails>>> DeleteCategory(
        CatalogContext context,
        [Description("The category id")] int id)
    {
        var category = await context.CatalogTypes.FindAsync(id);

        if (category is null)
        {
            return TypedResults.NotFound();
        }

        // Check if any items use this category
        var hasItems = await context.CatalogItems.AnyAsync(i => i.CatalogTypeId == id);
        if (hasItems)
        {
            return TypedResults.Conflict<ProblemDetails>(new()
            {
                Detail = "Cannot delete category that has menu items. Move or delete the items first."
            });
        }

        context.CatalogTypes.Remove(category);
        await context.SaveChangesAsync();

        return TypedResults.NoContent();
    }

    [ProducesResponseType<ProblemDetails>(StatusCodes.Status400BadRequest, "application/problem+json")]
    public static async Task<Created> CreateItem(
        [AsParameters] CatalogServices services,
        CatalogItem product)
    {
        var item = new CatalogItem(product.Name)
        {
            CatalogTypeId = product.CatalogTypeId,
            Description = product.Description,
            PictureFileName = product.PictureFileName,
            Price = product.Price,
            IsAvailable = product.IsAvailable,
            PreparationTimeMinutes = product.PreparationTimeMinutes
        };

        services.Context.CatalogItems.Add(item);
        await services.Context.SaveChangesAsync();

        return TypedResults.Created($"/api/catalog/items/{item.Id}");
    }

    public static async Task<Results<Ok, NotFound<ProblemDetails>>> UpdateItem(
        [Description("The id of the menu item to update")] int id,
        [AsParameters] CatalogServices services,
        CatalogItem productToUpdate)
    {
        var catalogItem = await services.Context.CatalogItems.SingleOrDefaultAsync(i => i.Id == id);

        if (catalogItem == null)
        {
            return TypedResults.NotFound<ProblemDetails>(new()
            {
                Detail = $"Item with id {id} not found."
            });
        }

        // Update properties
        catalogItem.Name = productToUpdate.Name;
        catalogItem.Description = productToUpdate.Description;
        catalogItem.Price = productToUpdate.Price;
        catalogItem.PictureFileName = productToUpdate.PictureFileName;
        catalogItem.CatalogTypeId = productToUpdate.CatalogTypeId;
        catalogItem.IsAvailable = productToUpdate.IsAvailable;
        catalogItem.PreparationTimeMinutes = productToUpdate.PreparationTimeMinutes;

        var priceChanged = services.Context.Entry(catalogItem).Property(i => i.Price).IsModified;

        if (priceChanged)
        {
            var originalPrice = services.Context.Entry(catalogItem).Property(i => i.Price).OriginalValue;
            var priceChangedEvent = new ProductPriceChangedIntegrationEvent(catalogItem.Id, productToUpdate.Price, originalPrice);
            await services.EventService.SaveEventAndCatalogContextChangesAsync(priceChangedEvent);
            await services.EventService.PublishThroughEventBusAsync(priceChangedEvent);
        }
        else
        {
            await services.Context.SaveChangesAsync();
        }

        return TypedResults.Ok();
    }

    public static async Task<Results<NoContent, NotFound>> DeleteItemById(
        [AsParameters] CatalogServices services,
        [Description("The id of the menu item to delete")] int id)
    {
        var item = await services.Context.CatalogItems.SingleOrDefaultAsync(x => x.Id == id);

        if (item is null)
        {
            return TypedResults.NotFound();
        }

        services.Context.CatalogItems.Remove(item);
        await services.Context.SaveChangesAsync();
        return TypedResults.NoContent();
    }

    public static async Task<Results<Ok<CatalogItemDto>, NotFound>> ToggleItemAvailability(
        [AsParameters] CatalogServices services,
        HttpContext httpContext,
        [Description("The id of the menu item")] int id)
    {
        var item = await services.Context.CatalogItems
            .Include(c => c.CatalogType)
            .Include(c => c.Customizations)
                .ThenInclude(c => c.Options)
            .SingleOrDefaultAsync(x => x.Id == id);

        if (item is null)
        {
            return TypedResults.NotFound();
        }

        item.IsAvailable = !item.IsAvailable;
        await services.Context.SaveChangesAsync();

        var baseUrl = GetBaseUrl(httpContext);
        return TypedResults.Ok(item.ToDto(baseUrl));
    }

    public static async Task<Results<Ok<List<ItemCustomizationDto>>, NotFound>> GetItemCustomizations(
        [AsParameters] CatalogServices services,
        [Description("The id of the menu item")] int id)
    {
        var item = await services.Context.CatalogItems.SingleOrDefaultAsync(x => x.Id == id);

        if (item is null)
        {
            return TypedResults.NotFound();
        }

        var customizations = await services.Context.ItemCustomizations
            .Include(c => c.Options.OrderBy(o => o.DisplayOrder))
            .Where(c => c.CatalogItemId == id)
            .OrderBy(c => c.DisplayOrder)
            .ToListAsync();

        return TypedResults.Ok(customizations.ToDtoList());
    }

    private static string GetImageMimeTypeFromImageFileExtension(string extension) => extension switch
    {
        ".png" => "image/png",
        ".gif" => "image/gif",
        ".jpg" or ".jpeg" => "image/jpeg",
        ".bmp" => "image/bmp",
        ".tiff" => "image/tiff",
        ".wmf" => "image/wmf",
        ".jp2" => "image/jp2",
        ".svg" => "image/svg+xml",
        ".webp" => "image/webp",
        _ => "application/octet-stream",
    };

    public static string GetFullPath(string contentRootPath, string pictureFileName) =>
        Path.Combine(contentRootPath, "Pics", pictureFileName);

    private static string GetBaseUrl(HttpContext httpContext)
    {
        var request = httpContext.Request;

        // Check for forwarded headers (when behind a reverse proxy like YARP)
        var forwardedHost = request.Headers["X-Forwarded-Host"].FirstOrDefault();
        var forwardedProto = request.Headers["X-Forwarded-Proto"].FirstOrDefault();

        if (!string.IsNullOrEmpty(forwardedHost))
        {
            var scheme = forwardedProto ?? request.Scheme;
            return $"{scheme}://{forwardedHost}";
        }

        return $"{request.Scheme}://{request.Host}";
    }

    // User preferences handlers
    public static async Task<Results<Ok<UserItemPreferenceDto>, NotFound>> GetUserPreference(
        [AsParameters] CatalogServices services,
        ClaimsPrincipal user,
        [Description("The catalog item id")] int catalogItemId)
    {
        var userId = user.GetUserId();
        if (string.IsNullOrEmpty(userId))
        {
            return TypedResults.NotFound();
        }

        var preference = await services.Context.UserItemPreferences
            .Include(p => p.SelectedOptions)
            .FirstOrDefaultAsync(p => p.UserId == userId && p.CatalogItemId == catalogItemId);

        if (preference == null)
        {
            return TypedResults.NotFound();
        }

        return TypedResults.Ok(preference.ToDto());
    }

    public static async Task<Ok<List<UserItemPreferenceDto>>> GetUserPreferences(
        [AsParameters] CatalogServices services,
        ClaimsPrincipal user)
    {
        var userId = user.GetUserId();
        if (string.IsNullOrEmpty(userId))
        {
            return TypedResults.Ok(new List<UserItemPreferenceDto>());
        }

        var preferences = await services.Context.UserItemPreferences
            .Include(p => p.SelectedOptions)
            .Where(p => p.UserId == userId)
            .ToListAsync();

        return TypedResults.Ok(preferences.ToDtoList());
    }

    public static async Task<Ok<List<UserItemPreferenceDto>>> GetUserPreferencesForItems(
        [AsParameters] CatalogServices services,
        ClaimsPrincipal user,
        [FromBody] int[] catalogItemIds)
    {
        var userId = user.GetUserId();
        if (string.IsNullOrEmpty(userId) || catalogItemIds.Length == 0)
        {
            return TypedResults.Ok(new List<UserItemPreferenceDto>());
        }

        var preferences = await services.Context.UserItemPreferences
            .Include(p => p.SelectedOptions)
            .Where(p => p.UserId == userId && catalogItemIds.Contains(p.CatalogItemId))
            .ToListAsync();

        return TypedResults.Ok(preferences.ToDtoList());
    }

    public static async Task<Ok> SaveUserPreferences(
        [AsParameters] CatalogServices services,
        ClaimsPrincipal user,
        [FromBody] SaveUserPreferencesRequest request)
    {
        var userId = user.GetUserId();
        if (string.IsNullOrEmpty(userId) || request.Items.Count == 0)
        {
            return TypedResults.Ok();
        }

        foreach (var item in request.Items)
        {
            if (item.SelectedOptions.Count == 0)
            {
                continue;
            }

            // Find or create preference
            var existingPreference = await services.Context.UserItemPreferences
                .Include(p => p.SelectedOptions)
                .FirstOrDefaultAsync(p =>
                    p.UserId == userId &&
                    p.CatalogItemId == item.CatalogItemId);

            if (existingPreference != null)
            {
                // Update existing preference - clear old options and add new ones
                services.Context.UserPreferenceOptions.RemoveRange(existingPreference.SelectedOptions);
                existingPreference.SelectedOptions.Clear();

                foreach (var option in item.SelectedOptions)
                {
                    existingPreference.SelectedOptions.Add(new Model.UserPreferenceOption
                    {
                        CustomizationId = option.CustomizationId,
                        OptionId = option.OptionId
                    });
                }
                existingPreference.LastUpdated = DateTime.UtcNow;
            }
            else
            {
                // Create new preference
                var newPreference = new Model.UserItemPreference
                {
                    UserId = userId,
                    CatalogItemId = item.CatalogItemId,
                    LastUpdated = DateTime.UtcNow
                };

                foreach (var option in item.SelectedOptions)
                {
                    newPreference.SelectedOptions.Add(new Model.UserPreferenceOption
                    {
                        CustomizationId = option.CustomizationId,
                        OptionId = option.OptionId
                    });
                }

                services.Context.UserItemPreferences.Add(newPreference);
            }
        }

        await services.Context.SaveChangesAsync();
        return TypedResults.Ok();
    }

    // Favorites handlers
    public static async Task<Ok<List<int>>> GetUserFavorites(
        [AsParameters] CatalogServices services,
        ClaimsPrincipal user)
    {
        var userId = user.GetUserId();
        if (string.IsNullOrEmpty(userId))
        {
            return TypedResults.Ok(new List<int>());
        }

        var favoriteIds = await services.Context.UserItemFavorites
            .Where(f => f.UserId == userId)
            .OrderByDescending(f => f.AddedAt)
            .Select(f => f.CatalogItemId)
            .ToListAsync();

        return TypedResults.Ok(favoriteIds);
    }

    public static async Task<Results<Ok, NotFound>> AddFavorite(
        [AsParameters] CatalogServices services,
        ClaimsPrincipal user,
        [Description("The catalog item id to add to favorites")] int catalogItemId)
    {
        var userId = user.GetUserId();
        if (string.IsNullOrEmpty(userId))
        {
            return TypedResults.NotFound();
        }

        // Check if item exists
        var itemExists = await services.Context.CatalogItems.AnyAsync(i => i.Id == catalogItemId);
        if (!itemExists)
        {
            return TypedResults.NotFound();
        }

        // Check if already favorited
        var existingFavorite = await services.Context.UserItemFavorites
            .FirstOrDefaultAsync(f => f.UserId == userId && f.CatalogItemId == catalogItemId);

        if (existingFavorite == null)
        {
            var favorite = new Model.UserItemFavorite
            {
                UserId = userId,
                CatalogItemId = catalogItemId,
                AddedAt = DateTime.UtcNow
            };
            services.Context.UserItemFavorites.Add(favorite);
            await services.Context.SaveChangesAsync();
        }

        return TypedResults.Ok();
    }

    public static async Task<Results<Ok, NotFound>> RemoveFavorite(
        [AsParameters] CatalogServices services,
        ClaimsPrincipal user,
        [Description("The catalog item id to remove from favorites")] int catalogItemId)
    {
        var userId = user.GetUserId();
        if (string.IsNullOrEmpty(userId))
        {
            return TypedResults.NotFound();
        }

        var favorite = await services.Context.UserItemFavorites
            .FirstOrDefaultAsync(f => f.UserId == userId && f.CatalogItemId == catalogItemId);

        if (favorite == null)
        {
            return TypedResults.NotFound();
        }

        services.Context.UserItemFavorites.Remove(favorite);
        await services.Context.SaveChangesAsync();

        return TypedResults.Ok();
    }
}
