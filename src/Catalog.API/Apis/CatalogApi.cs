using System.ComponentModel;
using System.ComponentModel.DataAnnotations;
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

        return app;
    }

    [ProducesResponseType<ProblemDetails>(StatusCodes.Status400BadRequest, "application/problem+json")]
    public static async Task<Ok<PaginatedItems<CatalogItem>>> GetAllItems(
        [AsParameters] PaginationRequest paginationRequest,
        [AsParameters] CatalogServices services,
        [Description("Filter by category")] int? categoryId = null)
    {
        var pageSize = paginationRequest.PageSize;
        var pageIndex = paginationRequest.PageIndex;

        var query = services.Context.CatalogItems
            .Include(c => c.CatalogType)
            .AsQueryable();

        if (categoryId.HasValue)
        {
            query = query.Where(c => c.CatalogTypeId == categoryId.Value);
        }

        var totalItems = await query.LongCountAsync();

        var itemsOnPage = await query
            .OrderBy(c => c.Name)
            .Skip(pageSize * pageIndex)
            .Take(pageSize)
            .ToListAsync();

        return TypedResults.Ok(new PaginatedItems<CatalogItem>(pageIndex, pageSize, totalItems, itemsOnPage));
    }

    [ProducesResponseType<ProblemDetails>(StatusCodes.Status400BadRequest, "application/problem+json")]
    public static async Task<Ok<PaginatedItems<CatalogItem>>> GetAvailableItems(
        [AsParameters] PaginationRequest paginationRequest,
        [AsParameters] CatalogServices services,
        [Description("Filter by category")] int? categoryId = null)
    {
        var pageSize = paginationRequest.PageSize;
        var pageIndex = paginationRequest.PageIndex;

        var query = services.Context.CatalogItems
            .Include(c => c.CatalogType)
            .Where(c => c.IsAvailable);

        if (categoryId.HasValue)
        {
            query = query.Where(c => c.CatalogTypeId == categoryId.Value);
        }

        var totalItems = await query.LongCountAsync();

        var itemsOnPage = await query
            .OrderBy(c => c.Name)
            .Skip(pageSize * pageIndex)
            .Take(pageSize)
            .ToListAsync();

        return TypedResults.Ok(new PaginatedItems<CatalogItem>(pageIndex, pageSize, totalItems, itemsOnPage));
    }

    [ProducesResponseType<ProblemDetails>(StatusCodes.Status400BadRequest, "application/problem+json")]
    public static async Task<Ok<List<CatalogItem>>> GetItemsByIds(
        [AsParameters] CatalogServices services,
        [Description("List of ids for menu items to return")] int[] ids)
    {
        var items = await services.Context.CatalogItems
            .Include(c => c.CatalogType)
            .Include(c => c.Customizations)
                .ThenInclude(c => c.Options)
            .Where(item => ids.Contains(item.Id))
            .ToListAsync();
        return TypedResults.Ok(items);
    }

    [ProducesResponseType<ProblemDetails>(StatusCodes.Status400BadRequest, "application/problem+json")]
    public static async Task<Results<Ok<CatalogItem>, NotFound, BadRequest<ProblemDetails>>> GetItemById(
        [AsParameters] CatalogServices services,
        [Description("The menu item id")] int id)
    {
        if (id <= 0)
        {
            return TypedResults.BadRequest<ProblemDetails>(new()
            {
                Detail = "Id is not valid"
            });
        }

        var item = await services.Context.CatalogItems
            .Include(ci => ci.CatalogType)
            .Include(ci => ci.Customizations)
                .ThenInclude(c => c.Options)
            .SingleOrDefaultAsync(ci => ci.Id == id);

        if (item == null)
        {
            return TypedResults.NotFound();
        }

        return TypedResults.Ok(item);
    }

    [ProducesResponseType<ProblemDetails>(StatusCodes.Status400BadRequest, "application/problem+json")]
    public static async Task<Ok<PaginatedItems<CatalogItem>>> GetItemsByName(
        [AsParameters] PaginationRequest paginationRequest,
        [AsParameters] CatalogServices services,
        [Description("The name to search for")] string name)
    {
        var pageSize = paginationRequest.PageSize;
        var pageIndex = paginationRequest.PageIndex;

        var query = services.Context.CatalogItems
            .Include(c => c.CatalogType)
            .Where(c => c.Name.ToLower().Contains(name.ToLower()));

        var totalItems = await query.LongCountAsync();

        var itemsOnPage = await query
            .OrderBy(c => c.Name)
            .Skip(pageSize * pageIndex)
            .Take(pageSize)
            .ToListAsync();

        return TypedResults.Ok(new PaginatedItems<CatalogItem>(pageIndex, pageSize, totalItems, itemsOnPage));
    }

    [ProducesResponseType<ProblemDetails>(StatusCodes.Status400BadRequest, "application/problem+json")]
    public static async Task<Ok<PaginatedItems<CatalogItem>>> GetItemsByType(
        [AsParameters] PaginationRequest paginationRequest,
        [AsParameters] CatalogServices services,
        [Description("The category id")] int typeId)
    {
        var pageSize = paginationRequest.PageSize;
        var pageIndex = paginationRequest.PageIndex;

        var query = services.Context.CatalogItems
            .Include(c => c.CatalogType)
            .Where(c => c.CatalogTypeId == typeId);

        var totalItems = await query.LongCountAsync();

        var itemsOnPage = await query
            .OrderBy(c => c.Name)
            .Skip(pageSize * pageIndex)
            .Take(pageSize)
            .ToListAsync();

        return TypedResults.Ok(new PaginatedItems<CatalogItem>(pageIndex, pageSize, totalItems, itemsOnPage));
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

    public static async Task<Ok<List<CatalogType>>> GetCategories(CatalogContext context)
    {
        var categories = await context.CatalogTypes.OrderBy(x => x.Type).ToListAsync();
        return TypedResults.Ok(categories);
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

    public static async Task<Results<Ok<CatalogItem>, NotFound>> ToggleItemAvailability(
        [AsParameters] CatalogServices services,
        [Description("The id of the menu item")] int id)
    {
        var item = await services.Context.CatalogItems.SingleOrDefaultAsync(x => x.Id == id);

        if (item is null)
        {
            return TypedResults.NotFound();
        }

        item.IsAvailable = !item.IsAvailable;
        await services.Context.SaveChangesAsync();

        return TypedResults.Ok(item);
    }

    public static async Task<Results<Ok<List<ItemCustomization>>, NotFound>> GetItemCustomizations(
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

        return TypedResults.Ok(customizations);
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
}
