using System.Text.Json;

namespace Chillax.Catalog.API.Infrastructure;

public partial class CatalogContextSeed(
    IWebHostEnvironment env,
    ILogger<CatalogContextSeed> logger) : IDbSeeder<CatalogContext>
{
    public async Task SeedAsync(CatalogContext context)
    {
        var contentRootPath = env.ContentRootPath;

        if (!context.CatalogItems.Any())
        {
            // Seed catalog types (menu categories)
            var types = new List<CatalogType>
            {
                new("Drinks") { Id = 1 },
                new("Food") { Id = 2 },
                new("Snacks") { Id = 3 },
                new("Desserts") { Id = 4 }
            };

            context.CatalogTypes.RemoveRange(context.CatalogTypes);
            await context.CatalogTypes.AddRangeAsync(types);
            logger.LogInformation("Seeded catalog with {NumTypes} types", types.Count);
            await context.SaveChangesAsync();

            // Seed menu items
            var menuItems = new List<CatalogItem>
            {
                // Drinks
                new("Espresso")
                {
                    Description = "Strong Italian coffee",
                    Price = 25.00m,
                    CatalogTypeId = 1,
                    IsAvailable = true,
                    PreparationTimeMinutes = 3,
                    PictureFileName = "espresso.webp"
                },
                new("Cappuccino")
                {
                    Description = "Espresso with steamed milk foam",
                    Price = 35.00m,
                    CatalogTypeId = 1,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    PictureFileName = "cappuccino.webp"
                },
                new("Latte")
                {
                    Description = "Espresso with steamed milk",
                    Price = 35.00m,
                    CatalogTypeId = 1,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    PictureFileName = "latte.webp"
                },
                new("Mocha")
                {
                    Description = "Espresso with chocolate and steamed milk",
                    Price = 40.00m,
                    CatalogTypeId = 1,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    PictureFileName = "mocha.webp"
                },
                new("Fresh Orange Juice")
                {
                    Description = "Freshly squeezed orange juice",
                    Price = 30.00m,
                    CatalogTypeId = 1,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    PictureFileName = "orange-juice.webp"
                },
                new("Mango Smoothie")
                {
                    Description = "Fresh mango blended with yogurt",
                    Price = 45.00m,
                    CatalogTypeId = 1,
                    IsAvailable = true,
                    PreparationTimeMinutes = 7,
                    PictureFileName = "mango-smoothie.webp"
                },

                // Food
                new("Club Sandwich")
                {
                    Description = "Triple-decker sandwich with chicken, bacon, lettuce, tomato",
                    Price = 65.00m,
                    CatalogTypeId = 2,
                    IsAvailable = true,
                    PreparationTimeMinutes = 15,
                    PictureFileName = "club-sandwich.webp"
                },
                new("Chicken Burger")
                {
                    Description = "Grilled chicken burger with special sauce",
                    Price = 75.00m,
                    CatalogTypeId = 2,
                    IsAvailable = true,
                    PreparationTimeMinutes = 15,
                    PictureFileName = "chicken-burger.webp"
                },
                new("Beef Burger")
                {
                    Description = "Juicy beef patty with cheese and vegetables",
                    Price = 85.00m,
                    CatalogTypeId = 2,
                    IsAvailable = true,
                    PreparationTimeMinutes = 15,
                    PictureFileName = "beef-burger.webp"
                },
                new("Pasta Alfredo")
                {
                    Description = "Creamy pasta with parmesan cheese",
                    Price = 70.00m,
                    CatalogTypeId = 2,
                    IsAvailable = true,
                    PreparationTimeMinutes = 20,
                    PictureFileName = "pasta-alfredo.webp"
                },

                // Snacks
                new("French Fries")
                {
                    Description = "Crispy golden fries",
                    Price = 25.00m,
                    CatalogTypeId = 3,
                    IsAvailable = true,
                    PreparationTimeMinutes = 10,
                    PictureFileName = "french-fries.webp"
                },
                new("Chicken Wings")
                {
                    Description = "Spicy chicken wings (6 pcs)",
                    Price = 55.00m,
                    CatalogTypeId = 3,
                    IsAvailable = true,
                    PreparationTimeMinutes = 15,
                    PictureFileName = "chicken-wings.webp"
                },
                new("Nachos")
                {
                    Description = "Tortilla chips with cheese and salsa",
                    Price = 45.00m,
                    CatalogTypeId = 3,
                    IsAvailable = true,
                    PreparationTimeMinutes = 10,
                    PictureFileName = "nachos.webp"
                },

                // Desserts
                new("Chocolate Cake")
                {
                    Description = "Rich chocolate layer cake",
                    Price = 45.00m,
                    CatalogTypeId = 4,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    PictureFileName = "chocolate-cake.webp"
                },
                new("Cheesecake")
                {
                    Description = "New York style cheesecake",
                    Price = 50.00m,
                    CatalogTypeId = 4,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    PictureFileName = "cheesecake.webp"
                },
                new("Ice Cream")
                {
                    Description = "Three scoops of your choice",
                    Price = 35.00m,
                    CatalogTypeId = 4,
                    IsAvailable = true,
                    PreparationTimeMinutes = 3,
                    PictureFileName = "ice-cream.webp"
                }
            };

            await context.CatalogItems.AddRangeAsync(menuItems);
            await context.SaveChangesAsync();
            logger.LogInformation("Seeded catalog with {NumItems} menu items", menuItems.Count);

            // Add customizations for coffee drinks
            var coffeeItems = await context.CatalogItems
                .Where(i => i.Name == "Espresso" || i.Name == "Cappuccino" || i.Name == "Latte" || i.Name == "Mocha")
                .ToListAsync();

            foreach (var coffee in coffeeItems)
            {
                var customizations = new List<ItemCustomization>
                {
                    new("Size")
                    {
                        CatalogItemId = coffee.Id,
                        IsRequired = true,
                        AllowMultiple = false,
                        DisplayOrder = 1,
                        Options = new List<CustomizationOption>
                        {
                            new("Small") { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new("Medium") { PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 2 },
                            new("Large") { PriceAdjustment = 10.00m, IsDefault = false, DisplayOrder = 3 }
                        }
                    },
                    new("Sugar Level")
                    {
                        CatalogItemId = coffee.Id,
                        IsRequired = false,
                        AllowMultiple = false,
                        DisplayOrder = 2,
                        Options = new List<CustomizationOption>
                        {
                            new("No Sugar") { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 1 },
                            new("Light Sugar") { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 2 },
                            new("Regular Sugar") { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 3 },
                            new("Extra Sugar") { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 4 }
                        }
                    },
                    new("Milk Type")
                    {
                        CatalogItemId = coffee.Id,
                        IsRequired = false,
                        AllowMultiple = false,
                        DisplayOrder = 3,
                        Options = new List<CustomizationOption>
                        {
                            new("Regular Milk") { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new("Oat Milk") { PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 2 },
                            new("Almond Milk") { PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 3 },
                            new("Skim Milk") { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 4 }
                        }
                    }
                };

                await context.ItemCustomizations.AddRangeAsync(customizations);
            }

            // Add customizations for burgers
            var burgers = await context.CatalogItems
                .Where(i => i.Name.Contains("Burger"))
                .ToListAsync();

            foreach (var burger in burgers)
            {
                var customizations = new List<ItemCustomization>
                {
                    new("Extras")
                    {
                        CatalogItemId = burger.Id,
                        IsRequired = false,
                        AllowMultiple = true,
                        DisplayOrder = 1,
                        Options = new List<CustomizationOption>
                        {
                            new("Extra Cheese") { PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 1 },
                            new("Bacon") { PriceAdjustment = 10.00m, IsDefault = false, DisplayOrder = 2 },
                            new("Avocado") { PriceAdjustment = 10.00m, IsDefault = false, DisplayOrder = 3 },
                            new("Egg") { PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 4 }
                        }
                    }
                };

                await context.ItemCustomizations.AddRangeAsync(customizations);
            }

            await context.SaveChangesAsync();
            logger.LogInformation("Seeded customizations for menu items");
        }
    }
}
