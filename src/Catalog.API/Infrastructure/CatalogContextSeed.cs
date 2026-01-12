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
                // Drinks - Hot Coffee
                new("Espresso")
                {
                    Description = "Strong Italian coffee shot",
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
                new("Americano")
                {
                    Description = "Espresso diluted with hot water",
                    Price = 30.00m,
                    CatalogTypeId = 1,
                    IsAvailable = true,
                    PreparationTimeMinutes = 3,
                    PictureFileName = "americano.webp"
                },
                new("Flat White")
                {
                    Description = "Double espresso with velvety steamed milk",
                    Price = 38.00m,
                    CatalogTypeId = 1,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    PictureFileName = "flat-white.webp"
                },

                // Drinks - Cold
                new("Iced Latte")
                {
                    Description = "Chilled espresso with cold milk over ice",
                    Price = 40.00m,
                    CatalogTypeId = 1,
                    IsAvailable = true,
                    PreparationTimeMinutes = 4,
                    PictureFileName = "iced-latte.webp"
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
                    Description = "Fresh mango blended with yogurt and honey",
                    Price = 45.00m,
                    CatalogTypeId = 1,
                    IsAvailable = true,
                    PreparationTimeMinutes = 7,
                    PictureFileName = "mango-smoothie.webp"
                },
                new("Strawberry Smoothie")
                {
                    Description = "Fresh strawberries blended with yogurt",
                    Price = 45.00m,
                    CatalogTypeId = 1,
                    IsAvailable = true,
                    PreparationTimeMinutes = 7,
                    PictureFileName = "strawberry-smoothie.webp"
                },
                new("Milkshake")
                {
                    Description = "Classic creamy milkshake",
                    Price = 40.00m,
                    CatalogTypeId = 1,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    PictureFileName = "milkshake.webp"
                },
                new("Soft Drink")
                {
                    Description = "Chilled carbonated beverage",
                    Price = 15.00m,
                    CatalogTypeId = 1,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    PictureFileName = "soft-drink.webp"
                },

                // Food - Main Dishes
                new("Club Sandwich")
                {
                    Description = "Triple-decker sandwich with chicken, bacon, lettuce, tomato and mayo",
                    Price = 65.00m,
                    CatalogTypeId = 2,
                    IsAvailable = true,
                    PreparationTimeMinutes = 15,
                    PictureFileName = "club-sandwich.webp"
                },
                new("Chicken Burger")
                {
                    Description = "Grilled chicken breast burger with special sauce and fresh vegetables",
                    Price = 75.00m,
                    CatalogTypeId = 2,
                    IsAvailable = true,
                    PreparationTimeMinutes = 15,
                    PictureFileName = "chicken-burger.webp"
                },
                new("Beef Burger")
                {
                    Description = "Juicy beef patty with cheese, lettuce, tomato and pickles",
                    Price = 85.00m,
                    CatalogTypeId = 2,
                    IsAvailable = true,
                    PreparationTimeMinutes = 15,
                    PictureFileName = "beef-burger.webp"
                },
                new("Pasta Alfredo")
                {
                    Description = "Creamy fettuccine pasta with parmesan cheese",
                    Price = 70.00m,
                    CatalogTypeId = 2,
                    IsAvailable = true,
                    PreparationTimeMinutes = 20,
                    PictureFileName = "pasta-alfredo.webp"
                },
                new("Margherita Pizza")
                {
                    Description = "Classic pizza with tomato sauce, mozzarella and fresh basil",
                    Price = 80.00m,
                    CatalogTypeId = 2,
                    IsAvailable = true,
                    PreparationTimeMinutes = 20,
                    PictureFileName = "margherita-pizza.webp"
                },
                new("Pepperoni Pizza")
                {
                    Description = "Pizza topped with pepperoni and mozzarella cheese",
                    Price = 90.00m,
                    CatalogTypeId = 2,
                    IsAvailable = true,
                    PreparationTimeMinutes = 20,
                    PictureFileName = "pepperoni-pizza.webp"
                },
                new("Caesar Salad")
                {
                    Description = "Crisp romaine lettuce with caesar dressing, croutons and parmesan",
                    Price = 55.00m,
                    CatalogTypeId = 2,
                    IsAvailable = true,
                    PreparationTimeMinutes = 10,
                    PictureFileName = "caesar-salad.webp"
                },

                // Snacks
                new("French Fries")
                {
                    Description = "Crispy golden french fries",
                    Price = 25.00m,
                    CatalogTypeId = 3,
                    IsAvailable = true,
                    PreparationTimeMinutes = 10,
                    PictureFileName = "french-fries.webp"
                },
                new("Chicken Wings")
                {
                    Description = "Crispy chicken wings (6 pcs)",
                    Price = 55.00m,
                    CatalogTypeId = 3,
                    IsAvailable = true,
                    PreparationTimeMinutes = 15,
                    PictureFileName = "chicken-wings.webp"
                },
                new("Nachos")
                {
                    Description = "Tortilla chips with melted cheese, salsa and sour cream",
                    Price = 45.00m,
                    CatalogTypeId = 3,
                    IsAvailable = true,
                    PreparationTimeMinutes = 10,
                    PictureFileName = "nachos.webp"
                },
                new("Mozzarella Sticks")
                {
                    Description = "Breaded mozzarella sticks with marinara sauce (6 pcs)",
                    Price = 40.00m,
                    CatalogTypeId = 3,
                    IsAvailable = true,
                    PreparationTimeMinutes = 10,
                    PictureFileName = "mozzarella-sticks.webp"
                },
                new("Onion Rings")
                {
                    Description = "Crispy battered onion rings",
                    Price = 30.00m,
                    CatalogTypeId = 3,
                    IsAvailable = true,
                    PreparationTimeMinutes = 10,
                    PictureFileName = "onion-rings.webp"
                },
                new("Chicken Nuggets")
                {
                    Description = "Crispy chicken nuggets (8 pcs)",
                    Price = 45.00m,
                    CatalogTypeId = 3,
                    IsAvailable = true,
                    PreparationTimeMinutes = 10,
                    PictureFileName = "chicken-nuggets.webp"
                },

                // Desserts
                new("Chocolate Cake")
                {
                    Description = "Rich chocolate layer cake with chocolate ganache",
                    Price = 45.00m,
                    CatalogTypeId = 4,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    PictureFileName = "chocolate-cake.webp"
                },
                new("Cheesecake")
                {
                    Description = "Creamy New York style cheesecake",
                    Price = 50.00m,
                    CatalogTypeId = 4,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    PictureFileName = "cheesecake.webp"
                },
                new("Ice Cream")
                {
                    Description = "Premium ice cream scoops",
                    Price = 35.00m,
                    CatalogTypeId = 4,
                    IsAvailable = true,
                    PreparationTimeMinutes = 3,
                    PictureFileName = "ice-cream.webp"
                },
                new("Brownie")
                {
                    Description = "Warm chocolate brownie with vanilla ice cream",
                    Price = 45.00m,
                    CatalogTypeId = 4,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    PictureFileName = "brownie.webp"
                },
                new("Waffles")
                {
                    Description = "Belgian waffles with your choice of toppings",
                    Price = 50.00m,
                    CatalogTypeId = 4,
                    IsAvailable = true,
                    PreparationTimeMinutes = 10,
                    PictureFileName = "waffles.webp"
                },
                new("Pancakes")
                {
                    Description = "Fluffy pancakes stack with maple syrup",
                    Price = 45.00m,
                    CatalogTypeId = 4,
                    IsAvailable = true,
                    PreparationTimeMinutes = 10,
                    PictureFileName = "pancakes.webp"
                }
            };

            await context.CatalogItems.AddRangeAsync(menuItems);
            await context.SaveChangesAsync();
            logger.LogInformation("Seeded catalog with {NumItems} menu items", menuItems.Count);

            // Add customizations for hot coffee drinks
            var hotCoffeeItems = await context.CatalogItems
                .Where(i => i.Name == "Espresso" || i.Name == "Cappuccino" || i.Name == "Latte" ||
                           i.Name == "Mocha" || i.Name == "Americano" || i.Name == "Flat White")
                .ToListAsync();

            foreach (var coffee in hotCoffeeItems)
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
                            new("Soy Milk") { PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 4 },
                            new("Skim Milk") { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 5 }
                        }
                    },
                    new("Extras")
                    {
                        CatalogItemId = coffee.Id,
                        IsRequired = false,
                        AllowMultiple = true,
                        DisplayOrder = 4,
                        Options = new List<CustomizationOption>
                        {
                            new("Extra Shot") { PriceAdjustment = 8.00m, IsDefault = false, DisplayOrder = 1 },
                            new("Vanilla Syrup") { PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 2 },
                            new("Caramel Syrup") { PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 3 },
                            new("Hazelnut Syrup") { PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 4 },
                            new("Whipped Cream") { PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 5 }
                        }
                    }
                };

                await context.ItemCustomizations.AddRangeAsync(customizations);
            }

            // Add customizations for iced latte
            var icedLatte = await context.CatalogItems.FirstOrDefaultAsync(i => i.Name == "Iced Latte");
            if (icedLatte != null)
            {
                var customizations = new List<ItemCustomization>
                {
                    new("Size")
                    {
                        CatalogItemId = icedLatte.Id,
                        IsRequired = true,
                        AllowMultiple = false,
                        DisplayOrder = 1,
                        Options = new List<CustomizationOption>
                        {
                            new("Regular") { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new("Large") { PriceAdjustment = 8.00m, IsDefault = false, DisplayOrder = 2 }
                        }
                    },
                    new("Milk Type")
                    {
                        CatalogItemId = icedLatte.Id,
                        IsRequired = false,
                        AllowMultiple = false,
                        DisplayOrder = 2,
                        Options = new List<CustomizationOption>
                        {
                            new("Regular Milk") { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new("Oat Milk") { PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 2 },
                            new("Almond Milk") { PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 3 }
                        }
                    },
                    new("Sweetness")
                    {
                        CatalogItemId = icedLatte.Id,
                        IsRequired = false,
                        AllowMultiple = false,
                        DisplayOrder = 3,
                        Options = new List<CustomizationOption>
                        {
                            new("Unsweetened") { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 1 },
                            new("Lightly Sweet") { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 2 },
                            new("Regular Sweet") { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 3 },
                            new("Extra Sweet") { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 4 }
                        }
                    }
                };

                await context.ItemCustomizations.AddRangeAsync(customizations);
            }

            // Add customizations for smoothies
            var smoothies = await context.CatalogItems
                .Where(i => i.Name.Contains("Smoothie"))
                .ToListAsync();

            foreach (var smoothie in smoothies)
            {
                var customizations = new List<ItemCustomization>
                {
                    new("Size")
                    {
                        CatalogItemId = smoothie.Id,
                        IsRequired = true,
                        AllowMultiple = false,
                        DisplayOrder = 1,
                        Options = new List<CustomizationOption>
                        {
                            new("Regular") { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new("Large") { PriceAdjustment = 10.00m, IsDefault = false, DisplayOrder = 2 }
                        }
                    },
                    new("Add-ins")
                    {
                        CatalogItemId = smoothie.Id,
                        IsRequired = false,
                        AllowMultiple = true,
                        DisplayOrder = 2,
                        Options = new List<CustomizationOption>
                        {
                            new("Protein Powder") { PriceAdjustment = 10.00m, IsDefault = false, DisplayOrder = 1 },
                            new("Chia Seeds") { PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 2 },
                            new("Honey") { PriceAdjustment = 3.00m, IsDefault = false, DisplayOrder = 3 },
                            new("Peanut Butter") { PriceAdjustment = 8.00m, IsDefault = false, DisplayOrder = 4 }
                        }
                    }
                };

                await context.ItemCustomizations.AddRangeAsync(customizations);
            }

            // Add customizations for milkshake
            var milkshake = await context.CatalogItems.FirstOrDefaultAsync(i => i.Name == "Milkshake");
            if (milkshake != null)
            {
                var customizations = new List<ItemCustomization>
                {
                    new("Flavor")
                    {
                        CatalogItemId = milkshake.Id,
                        IsRequired = true,
                        AllowMultiple = false,
                        DisplayOrder = 1,
                        Options = new List<CustomizationOption>
                        {
                            new("Chocolate") { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new("Vanilla") { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 2 },
                            new("Strawberry") { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 3 },
                            new("Oreo") { PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 4 },
                            new("Caramel") { PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 5 }
                        }
                    },
                    new("Size")
                    {
                        CatalogItemId = milkshake.Id,
                        IsRequired = true,
                        AllowMultiple = false,
                        DisplayOrder = 2,
                        Options = new List<CustomizationOption>
                        {
                            new("Regular") { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new("Large") { PriceAdjustment = 10.00m, IsDefault = false, DisplayOrder = 2 }
                        }
                    },
                    new("Toppings")
                    {
                        CatalogItemId = milkshake.Id,
                        IsRequired = false,
                        AllowMultiple = true,
                        DisplayOrder = 3,
                        Options = new List<CustomizationOption>
                        {
                            new("Whipped Cream") { PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 1 },
                            new("Chocolate Chips") { PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 2 },
                            new("Sprinkles") { PriceAdjustment = 3.00m, IsDefault = false, DisplayOrder = 3 }
                        }
                    }
                };

                await context.ItemCustomizations.AddRangeAsync(customizations);
            }

            // Add customizations for soft drink
            var softDrink = await context.CatalogItems.FirstOrDefaultAsync(i => i.Name == "Soft Drink");
            if (softDrink != null)
            {
                var customizations = new List<ItemCustomization>
                {
                    new("Type")
                    {
                        CatalogItemId = softDrink.Id,
                        IsRequired = true,
                        AllowMultiple = false,
                        DisplayOrder = 1,
                        Options = new List<CustomizationOption>
                        {
                            new("Coca-Cola") { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new("Pepsi") { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 2 },
                            new("Sprite") { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 3 },
                            new("Fanta Orange") { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 4 },
                            new("7UP") { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 5 }
                        }
                    },
                    new("Size")
                    {
                        CatalogItemId = softDrink.Id,
                        IsRequired = true,
                        AllowMultiple = false,
                        DisplayOrder = 2,
                        Options = new List<CustomizationOption>
                        {
                            new("Can") { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new("Bottle") { PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 2 }
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
                    new("Patty")
                    {
                        CatalogItemId = burger.Id,
                        IsRequired = true,
                        AllowMultiple = false,
                        DisplayOrder = 1,
                        Options = new List<CustomizationOption>
                        {
                            new("Single Patty") { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new("Double Patty") { PriceAdjustment = 20.00m, IsDefault = false, DisplayOrder = 2 }
                        }
                    },
                    new("Extras")
                    {
                        CatalogItemId = burger.Id,
                        IsRequired = false,
                        AllowMultiple = true,
                        DisplayOrder = 2,
                        Options = new List<CustomizationOption>
                        {
                            new("Extra Cheese") { PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 1 },
                            new("Bacon") { PriceAdjustment = 10.00m, IsDefault = false, DisplayOrder = 2 },
                            new("Avocado") { PriceAdjustment = 10.00m, IsDefault = false, DisplayOrder = 3 },
                            new("Fried Egg") { PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 4 },
                            new("Jalapenos") { PriceAdjustment = 3.00m, IsDefault = false, DisplayOrder = 5 },
                            new("Mushrooms") { PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 6 }
                        }
                    },
                    new("Side")
                    {
                        CatalogItemId = burger.Id,
                        IsRequired = false,
                        AllowMultiple = false,
                        DisplayOrder = 3,
                        Options = new List<CustomizationOption>
                        {
                            new("No Side") { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new("French Fries") { PriceAdjustment = 15.00m, IsDefault = false, DisplayOrder = 2 },
                            new("Onion Rings") { PriceAdjustment = 18.00m, IsDefault = false, DisplayOrder = 3 },
                            new("Coleslaw") { PriceAdjustment = 10.00m, IsDefault = false, DisplayOrder = 4 }
                        }
                    }
                };

                await context.ItemCustomizations.AddRangeAsync(customizations);
            }

            // Add customizations for pizzas
            var pizzas = await context.CatalogItems
                .Where(i => i.Name.Contains("Pizza"))
                .ToListAsync();

            foreach (var pizza in pizzas)
            {
                var customizations = new List<ItemCustomization>
                {
                    new("Size")
                    {
                        CatalogItemId = pizza.Id,
                        IsRequired = true,
                        AllowMultiple = false,
                        DisplayOrder = 1,
                        Options = new List<CustomizationOption>
                        {
                            new("Medium (10\")") { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new("Large (14\")") { PriceAdjustment = 25.00m, IsDefault = false, DisplayOrder = 2 }
                        }
                    },
                    new("Crust")
                    {
                        CatalogItemId = pizza.Id,
                        IsRequired = true,
                        AllowMultiple = false,
                        DisplayOrder = 2,
                        Options = new List<CustomizationOption>
                        {
                            new("Classic") { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new("Thin Crust") { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 2 },
                            new("Stuffed Crust") { PriceAdjustment = 15.00m, IsDefault = false, DisplayOrder = 3 }
                        }
                    },
                    new("Extra Toppings")
                    {
                        CatalogItemId = pizza.Id,
                        IsRequired = false,
                        AllowMultiple = true,
                        DisplayOrder = 3,
                        Options = new List<CustomizationOption>
                        {
                            new("Extra Cheese") { PriceAdjustment = 10.00m, IsDefault = false, DisplayOrder = 1 },
                            new("Mushrooms") { PriceAdjustment = 8.00m, IsDefault = false, DisplayOrder = 2 },
                            new("Olives") { PriceAdjustment = 8.00m, IsDefault = false, DisplayOrder = 3 },
                            new("Onions") { PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 4 },
                            new("Bell Peppers") { PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 5 }
                        }
                    }
                };

                await context.ItemCustomizations.AddRangeAsync(customizations);
            }

            // Add customizations for pasta
            var pasta = await context.CatalogItems.FirstOrDefaultAsync(i => i.Name == "Pasta Alfredo");
            if (pasta != null)
            {
                var customizations = new List<ItemCustomization>
                {
                    new("Protein")
                    {
                        CatalogItemId = pasta.Id,
                        IsRequired = false,
                        AllowMultiple = false,
                        DisplayOrder = 1,
                        Options = new List<CustomizationOption>
                        {
                            new("No Protein") { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new("Grilled Chicken") { PriceAdjustment = 15.00m, IsDefault = false, DisplayOrder = 2 },
                            new("Shrimp") { PriceAdjustment = 25.00m, IsDefault = false, DisplayOrder = 3 }
                        }
                    },
                    new("Extras")
                    {
                        CatalogItemId = pasta.Id,
                        IsRequired = false,
                        AllowMultiple = true,
                        DisplayOrder = 2,
                        Options = new List<CustomizationOption>
                        {
                            new("Garlic Bread") { PriceAdjustment = 10.00m, IsDefault = false, DisplayOrder = 1 },
                            new("Extra Parmesan") { PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 2 },
                            new("Mushrooms") { PriceAdjustment = 8.00m, IsDefault = false, DisplayOrder = 3 }
                        }
                    }
                };

                await context.ItemCustomizations.AddRangeAsync(customizations);
            }

            // Add customizations for Caesar Salad
            var salad = await context.CatalogItems.FirstOrDefaultAsync(i => i.Name == "Caesar Salad");
            if (salad != null)
            {
                var customizations = new List<ItemCustomization>
                {
                    new("Protein")
                    {
                        CatalogItemId = salad.Id,
                        IsRequired = false,
                        AllowMultiple = false,
                        DisplayOrder = 1,
                        Options = new List<CustomizationOption>
                        {
                            new("No Protein") { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new("Grilled Chicken") { PriceAdjustment = 15.00m, IsDefault = false, DisplayOrder = 2 },
                            new("Grilled Shrimp") { PriceAdjustment = 25.00m, IsDefault = false, DisplayOrder = 3 }
                        }
                    },
                    new("Dressing")
                    {
                        CatalogItemId = salad.Id,
                        IsRequired = false,
                        AllowMultiple = false,
                        DisplayOrder = 2,
                        Options = new List<CustomizationOption>
                        {
                            new("Caesar Dressing") { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new("Dressing on the Side") { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 2 },
                            new("Light Dressing") { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 3 }
                        }
                    }
                };

                await context.ItemCustomizations.AddRangeAsync(customizations);
            }

            // Add customizations for chicken wings
            var wings = await context.CatalogItems.FirstOrDefaultAsync(i => i.Name == "Chicken Wings");
            if (wings != null)
            {
                var customizations = new List<ItemCustomization>
                {
                    new("Quantity")
                    {
                        CatalogItemId = wings.Id,
                        IsRequired = true,
                        AllowMultiple = false,
                        DisplayOrder = 1,
                        Options = new List<CustomizationOption>
                        {
                            new("6 Pieces") { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new("12 Pieces") { PriceAdjustment = 45.00m, IsDefault = false, DisplayOrder = 2 },
                            new("18 Pieces") { PriceAdjustment = 85.00m, IsDefault = false, DisplayOrder = 3 }
                        }
                    },
                    new("Flavor")
                    {
                        CatalogItemId = wings.Id,
                        IsRequired = true,
                        AllowMultiple = false,
                        DisplayOrder = 2,
                        Options = new List<CustomizationOption>
                        {
                            new("Buffalo Hot") { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new("BBQ") { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 2 },
                            new("Honey Mustard") { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 3 },
                            new("Garlic Parmesan") { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 4 },
                            new("Plain") { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 5 }
                        }
                    },
                    new("Dipping Sauce")
                    {
                        CatalogItemId = wings.Id,
                        IsRequired = false,
                        AllowMultiple = true,
                        DisplayOrder = 3,
                        Options = new List<CustomizationOption>
                        {
                            new("Ranch") { PriceAdjustment = 3.00m, IsDefault = false, DisplayOrder = 1 },
                            new("Blue Cheese") { PriceAdjustment = 3.00m, IsDefault = false, DisplayOrder = 2 },
                            new("BBQ Sauce") { PriceAdjustment = 3.00m, IsDefault = false, DisplayOrder = 3 }
                        }
                    }
                };

                await context.ItemCustomizations.AddRangeAsync(customizations);
            }

            // Add customizations for french fries
            var fries = await context.CatalogItems.FirstOrDefaultAsync(i => i.Name == "French Fries");
            if (fries != null)
            {
                var customizations = new List<ItemCustomization>
                {
                    new("Size")
                    {
                        CatalogItemId = fries.Id,
                        IsRequired = true,
                        AllowMultiple = false,
                        DisplayOrder = 1,
                        Options = new List<CustomizationOption>
                        {
                            new("Regular") { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new("Large") { PriceAdjustment = 10.00m, IsDefault = false, DisplayOrder = 2 }
                        }
                    },
                    new("Seasoning")
                    {
                        CatalogItemId = fries.Id,
                        IsRequired = false,
                        AllowMultiple = false,
                        DisplayOrder = 2,
                        Options = new List<CustomizationOption>
                        {
                            new("Classic Salt") { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new("Cajun Spice") { PriceAdjustment = 3.00m, IsDefault = false, DisplayOrder = 2 },
                            new("Cheese Sauce") { PriceAdjustment = 8.00m, IsDefault = false, DisplayOrder = 3 },
                            new("Truffle & Parmesan") { PriceAdjustment = 15.00m, IsDefault = false, DisplayOrder = 4 }
                        }
                    }
                };

                await context.ItemCustomizations.AddRangeAsync(customizations);
            }

            // Add customizations for nachos
            var nachos = await context.CatalogItems.FirstOrDefaultAsync(i => i.Name == "Nachos");
            if (nachos != null)
            {
                var customizations = new List<ItemCustomization>
                {
                    new("Protein")
                    {
                        CatalogItemId = nachos.Id,
                        IsRequired = false,
                        AllowMultiple = false,
                        DisplayOrder = 1,
                        Options = new List<CustomizationOption>
                        {
                            new("No Protein") { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new("Chicken") { PriceAdjustment = 15.00m, IsDefault = false, DisplayOrder = 2 },
                            new("Beef") { PriceAdjustment = 18.00m, IsDefault = false, DisplayOrder = 3 }
                        }
                    },
                    new("Extras")
                    {
                        CatalogItemId = nachos.Id,
                        IsRequired = false,
                        AllowMultiple = true,
                        DisplayOrder = 2,
                        Options = new List<CustomizationOption>
                        {
                            new("Extra Cheese") { PriceAdjustment = 8.00m, IsDefault = false, DisplayOrder = 1 },
                            new("Guacamole") { PriceAdjustment = 10.00m, IsDefault = false, DisplayOrder = 2 },
                            new("Sour Cream") { PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 3 },
                            new("Jalapenos") { PriceAdjustment = 3.00m, IsDefault = false, DisplayOrder = 4 }
                        }
                    }
                };

                await context.ItemCustomizations.AddRangeAsync(customizations);
            }

            // Add customizations for ice cream
            var iceCream = await context.CatalogItems.FirstOrDefaultAsync(i => i.Name == "Ice Cream");
            if (iceCream != null)
            {
                var customizations = new List<ItemCustomization>
                {
                    new("Scoops")
                    {
                        CatalogItemId = iceCream.Id,
                        IsRequired = true,
                        AllowMultiple = false,
                        DisplayOrder = 1,
                        Options = new List<CustomizationOption>
                        {
                            new("2 Scoops") { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new("3 Scoops") { PriceAdjustment = 10.00m, IsDefault = false, DisplayOrder = 2 }
                        }
                    },
                    new("Flavors")
                    {
                        CatalogItemId = iceCream.Id,
                        IsRequired = true,
                        AllowMultiple = true,
                        DisplayOrder = 2,
                        Options = new List<CustomizationOption>
                        {
                            new("Vanilla") { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new("Chocolate") { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 2 },
                            new("Strawberry") { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 3 },
                            new("Cookies & Cream") { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 4 },
                            new("Mango") { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 5 },
                            new("Pistachio") { PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 6 }
                        }
                    },
                    new("Toppings")
                    {
                        CatalogItemId = iceCream.Id,
                        IsRequired = false,
                        AllowMultiple = true,
                        DisplayOrder = 3,
                        Options = new List<CustomizationOption>
                        {
                            new("Chocolate Sauce") { PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 1 },
                            new("Caramel Sauce") { PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 2 },
                            new("Sprinkles") { PriceAdjustment = 3.00m, IsDefault = false, DisplayOrder = 3 },
                            new("Nuts") { PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 4 },
                            new("Whipped Cream") { PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 5 }
                        }
                    },
                    new("Serving")
                    {
                        CatalogItemId = iceCream.Id,
                        IsRequired = true,
                        AllowMultiple = false,
                        DisplayOrder = 4,
                        Options = new List<CustomizationOption>
                        {
                            new("Cup") { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new("Cone") { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 2 },
                            new("Waffle Cone") { PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 3 }
                        }
                    }
                };

                await context.ItemCustomizations.AddRangeAsync(customizations);
            }

            // Add customizations for waffles
            var waffles = await context.CatalogItems.FirstOrDefaultAsync(i => i.Name == "Waffles");
            if (waffles != null)
            {
                var customizations = new List<ItemCustomization>
                {
                    new("Toppings")
                    {
                        CatalogItemId = waffles.Id,
                        IsRequired = true,
                        AllowMultiple = true,
                        DisplayOrder = 1,
                        Options = new List<CustomizationOption>
                        {
                            new("Maple Syrup") { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new("Nutella") { PriceAdjustment = 8.00m, IsDefault = false, DisplayOrder = 2 },
                            new("Fresh Strawberries") { PriceAdjustment = 10.00m, IsDefault = false, DisplayOrder = 3 },
                            new("Bananas") { PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 4 },
                            new("Whipped Cream") { PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 5 },
                            new("Ice Cream Scoop") { PriceAdjustment = 15.00m, IsDefault = false, DisplayOrder = 6 }
                        }
                    }
                };

                await context.ItemCustomizations.AddRangeAsync(customizations);
            }

            // Add customizations for pancakes
            var pancakes = await context.CatalogItems.FirstOrDefaultAsync(i => i.Name == "Pancakes");
            if (pancakes != null)
            {
                var customizations = new List<ItemCustomization>
                {
                    new("Stack Size")
                    {
                        CatalogItemId = pancakes.Id,
                        IsRequired = true,
                        AllowMultiple = false,
                        DisplayOrder = 1,
                        Options = new List<CustomizationOption>
                        {
                            new("3 Pancakes") { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new("5 Pancakes") { PriceAdjustment = 15.00m, IsDefault = false, DisplayOrder = 2 }
                        }
                    },
                    new("Toppings")
                    {
                        CatalogItemId = pancakes.Id,
                        IsRequired = false,
                        AllowMultiple = true,
                        DisplayOrder = 2,
                        Options = new List<CustomizationOption>
                        {
                            new("Maple Syrup") { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new("Blueberries") { PriceAdjustment = 10.00m, IsDefault = false, DisplayOrder = 2 },
                            new("Chocolate Chips") { PriceAdjustment = 8.00m, IsDefault = false, DisplayOrder = 3 },
                            new("Bananas") { PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 4 },
                            new("Whipped Cream") { PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 5 }
                        }
                    }
                };

                await context.ItemCustomizations.AddRangeAsync(customizations);
            }

            // Add customizations for cheesecake
            var cheesecake = await context.CatalogItems.FirstOrDefaultAsync(i => i.Name == "Cheesecake");
            if (cheesecake != null)
            {
                var customizations = new List<ItemCustomization>
                {
                    new("Topping")
                    {
                        CatalogItemId = cheesecake.Id,
                        IsRequired = false,
                        AllowMultiple = false,
                        DisplayOrder = 1,
                        Options = new List<CustomizationOption>
                        {
                            new("Plain") { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new("Strawberry Sauce") { PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 2 },
                            new("Blueberry Sauce") { PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 3 },
                            new("Chocolate Sauce") { PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 4 }
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
