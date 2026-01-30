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
                new("Coffee") { Id = 1, TypeAr = "قهوة" },
                new("Espresso") { Id = 2, TypeAr = "اسبرسو" },
                new("Hot Drinks") { Id = 3, TypeAr = "مشروبات ساخنة" },
                new("Iced Drinks") { Id = 4, TypeAr = "مشروبات مثلجة" },
                new("Juices") { Id = 5, TypeAr = "عصائر" },
                new("Soft Drinks") { Id = 6, TypeAr = "مشروبات غازية" },
                new("Snacks") { Id = 7, TypeAr = "مقرمشات" },
                new("Desserts") { Id = 8, TypeAr = "حلويات" }
            };

            context.CatalogTypes.RemoveRange(context.CatalogTypes);
            await context.CatalogTypes.AddRangeAsync(types);
            logger.LogInformation("Seeded catalog with {NumTypes} types", types.Count);
            await context.SaveChangesAsync();

            // Seed menu items based on actual Chillax menu
            var menuItems = new List<CatalogItem>
            {
                // ============== COFFEE (Category 1) ==============
                new("Turkish Coffee")
                {
                    NameAr = "قهوة تركي",
                    Description = "Traditional Turkish coffee brewed to perfection",
                    DescriptionAr = "قهوة تركية تقليدية محضرة بإتقان",
                    Price = 25.00m,
                    CatalogTypeId = 1,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    PictureFileName = "turkish-coffee.webp"
                },
                new("Hazelnut Coffee")
                {
                    NameAr = "قهوة بالبندق",
                    Description = "Rich coffee with hazelnut flavor",
                    DescriptionAr = "قهوة غنية بنكهة البندق",
                    Price = 35.00m,
                    CatalogTypeId = 1,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    PictureFileName = "hazelnut-coffee.webp"
                },
                new("French Coffee")
                {
                    NameAr = "قهوة فرنسية",
                    Description = "Smooth French-style coffee",
                    DescriptionAr = "قهوة فرنسية ناعمة",
                    Price = 35.00m,
                    CatalogTypeId = 1,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    PictureFileName = "french-coffee.webp"
                },
                new("Caramel Coffee")
                {
                    NameAr = "قهوة بالكراميل",
                    Description = "Sweet caramel flavored coffee",
                    DescriptionAr = "قهوة حلوة بنكهة الكراميل",
                    Price = 30.00m,
                    CatalogTypeId = 1,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    PictureFileName = "caramel-coffee.webp"
                },
                new("Cappuccino")
                {
                    NameAr = "كابتشينو",
                    Description = "Classic Italian cappuccino with steamed milk foam",
                    DescriptionAr = "كابتشينو إيطالي كلاسيكي مع رغوة الحليب",
                    Price = 50.00m,
                    CatalogTypeId = 1,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    PictureFileName = "cappuccino.webp"
                },
                new("Latte")
                {
                    NameAr = "لاتيه",
                    Description = "Espresso with smooth steamed milk",
                    DescriptionAr = "اسبرسو مع حليب مبخر ناعم",
                    Price = 50.00m,
                    CatalogTypeId = 1,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    PictureFileName = "latte.webp"
                },
                new("Macchiato")
                {
                    NameAr = "ماكياتو",
                    Description = "Espresso marked with a dash of milk foam",
                    DescriptionAr = "اسبرسو مع لمسة من رغوة الحليب",
                    Price = 40.00m,
                    CatalogTypeId = 1,
                    IsAvailable = true,
                    PreparationTimeMinutes = 4,
                    PictureFileName = "macchiato.webp"
                },
                new("Nescafe")
                {
                    NameAr = "نسكافيه",
                    Description = "Instant coffee, available black or with milk",
                    DescriptionAr = "قهوة سريعة التحضير، سادة أو بالحليب",
                    Price = 35.00m,
                    CatalogTypeId = 1,
                    IsAvailable = true,
                    PreparationTimeMinutes = 3,
                    PictureFileName = "nescafe.webp"
                },
                new("American Coffee")
                {
                    NameAr = "قهوة أمريكية",
                    Description = "Classic American-style brewed coffee",
                    DescriptionAr = "قهوة أمريكية كلاسيكية",
                    Price = 60.00m,
                    CatalogTypeId = 1,
                    IsAvailable = true,
                    PreparationTimeMinutes = 3,
                    PictureFileName = "americano.webp"
                },

                // ============== ESPRESSO (Category 2) ==============
                new("Espresso")
                {
                    NameAr = "اسبرسو",
                    Description = "Strong Italian espresso shot",
                    DescriptionAr = "شوت اسبرسو إيطالي قوي",
                    Price = 35.00m,
                    CatalogTypeId = 2,
                    IsAvailable = true,
                    PreparationTimeMinutes = 3,
                    PictureFileName = "espresso.webp"
                },
                new("Mocha")
                {
                    NameAr = "موكا",
                    Description = "Espresso with chocolate and steamed milk",
                    DescriptionAr = "اسبرسو مع الشوكولاتة والحليب المبخر",
                    Price = 60.00m,
                    CatalogTypeId = 2,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    PictureFileName = "mocha.webp"
                },
                new("Iced Mocha")
                {
                    NameAr = "موكا مثلجة",
                    Description = "Chilled mocha with ice",
                    DescriptionAr = "موكا باردة مع الثلج",
                    Price = 60.00m,
                    CatalogTypeId = 2,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    PictureFileName = "iced-mocha.webp"
                },

                // ============== HOT DRINKS (Category 3) ==============
                new("Tea")
                {
                    NameAr = "شاي",
                    Description = "Traditional tea, available in various styles",
                    DescriptionAr = "شاي تقليدي متاح بأنواع مختلفة",
                    Price = 15.00m,
                    CatalogTypeId = 3,
                    IsAvailable = true,
                    PreparationTimeMinutes = 3,
                    PictureFileName = "tea.webp"
                },
                new("Green Tea")
                {
                    NameAr = "شاي أخضر",
                    Description = "Healthy green tea",
                    DescriptionAr = "شاي أخضر صحي",
                    Price = 20.00m,
                    CatalogTypeId = 3,
                    IsAvailable = true,
                    PreparationTimeMinutes = 3,
                    PictureFileName = "green-tea.webp"
                },
                new("Herbal Tea")
                {
                    NameAr = "شاي أعشاب",
                    Description = "Soothing herbal infusion - mint, anise, hibiscus, cinnamon",
                    DescriptionAr = "منقوع أعشاب مهدئ - نعناع، يانسون، كركديه، قرفة",
                    Price = 20.00m,
                    CatalogTypeId = 3,
                    IsAvailable = true,
                    PreparationTimeMinutes = 4,
                    PictureFileName = "herbal-tea.webp"
                },
                new("Hot Lemon")
                {
                    NameAr = "ليمون ساخن",
                    Description = "Warm lemon drink, optional honey",
                    DescriptionAr = "مشروب ليمون دافئ، بالعسل اختياري",
                    Price = 25.00m,
                    CatalogTypeId = 3,
                    IsAvailable = true,
                    PreparationTimeMinutes = 3,
                    PictureFileName = "hot-lemon.webp"
                },
                new("Hot Chocolate")
                {
                    NameAr = "شوكولاتة ساخنة",
                    Description = "Rich and creamy hot chocolate",
                    DescriptionAr = "شوكولاتة ساخنة غنية وكريمية",
                    Price = 50.00m,
                    CatalogTypeId = 3,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    PictureFileName = "hot-chocolate.webp"
                },
                new("Hot Cider")
                {
                    NameAr = "سيدر ساخن",
                    Description = "Warm apple cider",
                    DescriptionAr = "سيدر تفاح دافئ",
                    Price = 45.00m,
                    CatalogTypeId = 3,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    PictureFileName = "hot-cider.webp"
                },
                new("Sahlab")
                {
                    NameAr = "سحلب",
                    Description = "Traditional creamy orchid root drink with toppings",
                    DescriptionAr = "سحلب تقليدي كريمي مع الإضافات",
                    Price = 40.00m,
                    CatalogTypeId = 3,
                    IsAvailable = true,
                    PreparationTimeMinutes = 7,
                    PictureFileName = "sahlab.webp"
                },
                new("Hummus Al-Sham")
                {
                    NameAr = "حمص الشام",
                    Description = "Traditional Egyptian warm chickpea drink",
                    DescriptionAr = "حمص الشام المصري التقليدي الدافئ",
                    Price = 40.00m,
                    CatalogTypeId = 3,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    PictureFileName = "hummus-sham.webp"
                },

                // ============== ICED DRINKS (Category 4) ==============
                new("Iced Coffee")
                {
                    NameAr = "قهوة مثلجة",
                    Description = "Chilled coffee over ice",
                    DescriptionAr = "قهوة باردة مع الثلج",
                    Price = 60.00m,
                    CatalogTypeId = 4,
                    IsAvailable = true,
                    PreparationTimeMinutes = 4,
                    PictureFileName = "iced-latte.webp"
                },
                new("Frappuccino")
                {
                    NameAr = "فرابتشينو",
                    Description = "Blended iced coffee drink",
                    DescriptionAr = "مشروب قهوة مثلجة مخفوقة",
                    Price = 80.00m,
                    CatalogTypeId = 4,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    PictureFileName = "frappuccino.webp"
                },
                new("Flat White")
                {
                    NameAr = "فلات وايت",
                    Description = "Iced flat white with velvety milk",
                    DescriptionAr = "فلات وايت مثلج مع حليب ناعم",
                    Price = 80.00m,
                    CatalogTypeId = 4,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    PictureFileName = "flat-white.webp"
                },
                new("Iced Chocolate")
                {
                    NameAr = "شوكولاتة مثلجة",
                    Description = "Cold chocolate drink over ice",
                    DescriptionAr = "مشروب شوكولاتة بارد مع الثلج",
                    Price = 60.00m,
                    CatalogTypeId = 4,
                    IsAvailable = true,
                    PreparationTimeMinutes = 4,
                    PictureFileName = "iced-chocolate.webp"
                },
                new("Milkshake")
                {
                    NameAr = "ميلك شيك",
                    Description = "Creamy milkshake - chocolate, vanilla, strawberry, or caramel",
                    DescriptionAr = "ميلك شيك كريمي - شوكولاتة، فانيليا، فراولة، أو كراميل",
                    Price = 50.00m,
                    CatalogTypeId = 4,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    PictureFileName = "milkshake.webp"
                },
                new("Oreo Milkshake")
                {
                    NameAr = "ميلك شيك أوريو",
                    Description = "Creamy milkshake with Oreo cookies",
                    DescriptionAr = "ميلك شيك كريمي مع بسكويت أوريو",
                    Price = 60.00m,
                    CatalogTypeId = 4,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    PictureFileName = "oreo-milkshake.webp"
                },
                new("Galaxy Milkshake")
                {
                    NameAr = "ميلك شيك جالاكسي",
                    Description = "Rich Galaxy chocolate milkshake",
                    DescriptionAr = "ميلك شيك شوكولاتة جالاكسي غني",
                    Price = 80.00m,
                    CatalogTypeId = 4,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    PictureFileName = "galaxy-milkshake.webp"
                },
                new("Oreo Shake")
                {
                    NameAr = "شيك أوريو",
                    Description = "Oreo cookie blended shake",
                    DescriptionAr = "شيك أوريو مخفوق",
                    Price = 60.00m,
                    CatalogTypeId = 4,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    PictureFileName = "oreo-shake.webp"
                },
                new("Burio Shake")
                {
                    NameAr = "شيك بوريو",
                    Description = "Burio chocolate blended shake",
                    DescriptionAr = "شيك بوريو شوكولاتة مخفوق",
                    Price = 50.00m,
                    CatalogTypeId = 4,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    PictureFileName = "burio-shake.webp"
                },
                new("Yogurt")
                {
                    NameAr = "زبادي",
                    Description = "Fresh yogurt drink - plain, honey, or fruit",
                    DescriptionAr = "مشروب زبادي طازج - سادة، بالعسل، أو بالفواكه",
                    Price = 35.00m,
                    CatalogTypeId = 4,
                    IsAvailable = true,
                    PreparationTimeMinutes = 3,
                    PictureFileName = "yogurt.webp"
                },
                new("Brownies Shake")
                {
                    NameAr = "شيك براونيز",
                    Description = "Chocolate brownies blended shake",
                    DescriptionAr = "شيك براونيز شوكولاتة مخفوق",
                    Price = 45.00m,
                    CatalogTypeId = 4,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    PictureFileName = "brownie.webp"
                },
                new("Ice Cream Scoop")
                {
                    NameAr = "سكوب آيس كريم",
                    Description = "Premium ice cream scoop",
                    DescriptionAr = "سكوب آيس كريم فاخر",
                    Price = 20.00m,
                    CatalogTypeId = 4,
                    IsAvailable = true,
                    PreparationTimeMinutes = 2,
                    PictureFileName = "ice-cream.webp"
                },

                // ============== JUICES (Category 5) ==============
                new("Orange Juice")
                {
                    NameAr = "عصير برتقال",
                    Description = "Freshly squeezed orange juice",
                    DescriptionAr = "عصير برتقال طازج معصور",
                    Price = 20.00m,
                    CatalogTypeId = 5,
                    IsAvailable = true,
                    PreparationTimeMinutes = 4,
                    PictureFileName = "orange-juice.webp"
                },
                new("Mango Juice")
                {
                    NameAr = "عصير مانجو",
                    Description = "Fresh mango juice",
                    DescriptionAr = "عصير مانجو طازج",
                    Price = 50.00m,
                    CatalogTypeId = 5,
                    IsAvailable = true,
                    PreparationTimeMinutes = 4,
                    PictureFileName = "mango-smoothie.webp"
                },
                new("Strawberry Juice")
                {
                    NameAr = "عصير فراولة",
                    Description = "Fresh strawberry juice, plain or with milk",
                    DescriptionAr = "عصير فراولة طازج، سادة أو بالحليب",
                    Price = 50.00m,
                    CatalogTypeId = 5,
                    IsAvailable = true,
                    PreparationTimeMinutes = 4,
                    PictureFileName = "strawberry-smoothie.webp"
                },
                new("Guava Juice")
                {
                    NameAr = "عصير جوافة",
                    Description = "Fresh guava juice, plain or with milk",
                    DescriptionAr = "عصير جوافة طازج، سادة أو بالحليب",
                    Price = 50.00m,
                    CatalogTypeId = 5,
                    IsAvailable = true,
                    PreparationTimeMinutes = 4,
                    PictureFileName = "guava-juice.webp"
                },
                new("Banana Juice")
                {
                    NameAr = "عصير موز",
                    Description = "Creamy banana juice",
                    DescriptionAr = "عصير موز كريمي",
                    Price = 35.00m,
                    CatalogTypeId = 5,
                    IsAvailable = true,
                    PreparationTimeMinutes = 4,
                    PictureFileName = "banana-juice.webp"
                },
                new("Kiwi Juice")
                {
                    NameAr = "عصير كيوي",
                    Description = "Fresh kiwi juice",
                    DescriptionAr = "عصير كيوي طازج",
                    Price = 50.00m,
                    CatalogTypeId = 5,
                    IsAvailable = true,
                    PreparationTimeMinutes = 4,
                    PictureFileName = "kiwi-juice.webp"
                },
                new("Lemonade")
                {
                    NameAr = "ليمونادة",
                    Description = "Fresh lemonade, plain or with mint",
                    DescriptionAr = "ليمونادة طازجة، سادة أو بالنعناع",
                    Price = 30.00m,
                    CatalogTypeId = 5,
                    IsAvailable = true,
                    PreparationTimeMinutes = 4,
                    PictureFileName = "lemonade.webp"
                },
                new("Watermelon Juice")
                {
                    NameAr = "عصير بطيخ",
                    Description = "Refreshing watermelon juice",
                    DescriptionAr = "عصير بطيخ منعش",
                    Price = 45.00m,
                    CatalogTypeId = 5,
                    IsAvailable = true,
                    PreparationTimeMinutes = 4,
                    PictureFileName = "watermelon-juice.webp"
                },
                new("Prickly Pear Juice")
                {
                    NameAr = "عصير تين شوكي",
                    Description = "Fresh prickly pear cactus fruit juice",
                    DescriptionAr = "عصير تين شوكي طازج",
                    Price = 45.00m,
                    CatalogTypeId = 5,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    PictureFileName = "prickly-pear-juice.webp"
                },
                new("Date Shake")
                {
                    NameAr = "شيك تمر",
                    Description = "Sweet date shake, plain or with milk",
                    DescriptionAr = "شيك تمر حلو، سادة أو بالحليب",
                    Price = 50.00m,
                    CatalogTypeId = 5,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    PictureFileName = "date-shake.webp"
                },
                new("Fruit Salad")
                {
                    NameAr = "سلطة فواكه",
                    Description = "Mixed fresh fruit salad",
                    DescriptionAr = "سلطة فواكه طازجة مشكلة",
                    Price = 40.00m,
                    CatalogTypeId = 5,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    PictureFileName = "fruit-salad.webp"
                },
                new("Cocktail Juice")
                {
                    NameAr = "عصير كوكتيل",
                    Description = "Mixed fruit cocktail juice",
                    DescriptionAr = "عصير كوكتيل فواكه مشكل",
                    Price = 60.00m,
                    CatalogTypeId = 5,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    PictureFileName = "cocktail-juice.webp"
                },
                new("Sunshine Juice")
                {
                    NameAr = "عصير صن شاين",
                    Description = "Refreshing sunshine blend juice",
                    DescriptionAr = "عصير صن شاين منعش",
                    Price = 50.00m,
                    CatalogTypeId = 5,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    PictureFileName = "sunshine-juice.webp"
                },
                new("Florida Juice")
                {
                    NameAr = "عصير فلوريدا",
                    Description = "Florida-style citrus blend juice",
                    DescriptionAr = "عصير حمضيات على طريقة فلوريدا",
                    Price = 60.00m,
                    CatalogTypeId = 5,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    PictureFileName = "florida-juice.webp"
                },

                // ============== SOFT DRINKS (Category 6) ==============
                new("Pepsi")
                {
                    NameAr = "بيبسي",
                    Description = "Chilled Pepsi cola",
                    DescriptionAr = "بيبسي كولا مثلجة",
                    Price = 25.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    PictureFileName = "soft-drink.webp"
                },
                new("7Up")
                {
                    NameAr = "سفن أب",
                    Description = "Chilled lemon-lime soda",
                    DescriptionAr = "مشروب غازي ليمون مثلج",
                    Price = 25.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    PictureFileName = "soft-drink.webp"
                },
                new("Mirinda")
                {
                    NameAr = "ميرندا",
                    Description = "Chilled orange soda",
                    DescriptionAr = "مشروب غازي برتقال مثلج",
                    Price = 25.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    PictureFileName = "soft-drink.webp"
                },
                new("Mountain Dew")
                {
                    NameAr = "ماونتن ديو",
                    Description = "Chilled citrus soda",
                    DescriptionAr = "مشروب غازي حمضيات مثلج",
                    Price = 25.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    PictureFileName = "soft-drink.webp"
                },
                new("Schweppes")
                {
                    NameAr = "شويبس",
                    Description = "Sparkling tonic - lemon, pomegranate, gold, or tangerine",
                    DescriptionAr = "مشروب فوار - ليمون، رمان، جولد، أو يوسفي",
                    Price = 20.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    PictureFileName = "soft-drink.webp"
                },
                new("Birell")
                {
                    NameAr = "بيريل",
                    Description = "Non-alcoholic malt beverage",
                    DescriptionAr = "مشروب شعير خالي من الكحول",
                    Price = 25.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    PictureFileName = "soft-drink.webp"
                },
                new("Mineral Water")
                {
                    NameAr = "مياه معدنية",
                    Description = "Bottled mineral water",
                    DescriptionAr = "مياه معدنية معبأة",
                    Price = 8.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    PictureFileName = "mineral-water.webp"
                },
                new("Red Bull")
                {
                    NameAr = "ريد بول",
                    Description = "Energy drink",
                    DescriptionAr = "مشروب طاقة",
                    Price = 65.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    PictureFileName = "red-bull.webp"
                },
                new("Power Horse")
                {
                    NameAr = "باور هورس",
                    Description = "Energy drink",
                    DescriptionAr = "مشروب طاقة",
                    Price = 25.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    PictureFileName = "soft-drink.webp"
                },
                new("Buzz Energy")
                {
                    NameAr = "بز إنرجي",
                    Description = "Energy drink",
                    DescriptionAr = "مشروب طاقة",
                    Price = 20.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    PictureFileName = "soft-drink.webp"
                },
                new("Amstel Zero")
                {
                    NameAr = "أمستل زيرو",
                    Description = "Non-alcoholic beer",
                    DescriptionAr = "بيرة خالية من الكحول",
                    Price = 25.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    PictureFileName = "soft-drink.webp"
                },
                new("Barbican")
                {
                    NameAr = "باربيكان",
                    Description = "Non-alcoholic malt beverage",
                    DescriptionAr = "مشروب شعير خالي من الكحول",
                    Price = 40.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    PictureFileName = "soft-drink.webp"
                },
                new("Moussy")
                {
                    NameAr = "موسي",
                    Description = "Non-alcoholic malt beverage",
                    DescriptionAr = "مشروب شعير خالي من الكحول",
                    Price = 30.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    PictureFileName = "soft-drink.webp"
                },
                new("FreeGo")
                {
                    NameAr = "فري جو",
                    Description = "Soft drink",
                    DescriptionAr = "مشروب غازي",
                    Price = 20.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    PictureFileName = "soft-drink.webp"
                },
                new("Snaps")
                {
                    NameAr = "سنابس",
                    Description = "Carbonated drink",
                    DescriptionAr = "مشروب غازي",
                    Price = 20.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    PictureFileName = "soft-drink.webp"
                },
                new("Twist")
                {
                    NameAr = "تويست",
                    Description = "Carbonated lemon drink",
                    DescriptionAr = "مشروب غازي بالليمون",
                    Price = 25.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    PictureFileName = "soft-drink.webp"
                },
                new("V7")
                {
                    NameAr = "في سفن",
                    Description = "Vegetable juice blend",
                    DescriptionAr = "عصير خضروات مشكل",
                    Price = 25.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    PictureFileName = "soft-drink.webp"
                },
                new("Spiro Spathis")
                {
                    NameAr = "سبيرو سباتس",
                    Description = "Classic Egyptian lemon soda",
                    DescriptionAr = "مشروب ليمون غازي مصري كلاسيكي",
                    Price = 20.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    PictureFileName = "soft-drink.webp"
                },
                new("Double Deer")
                {
                    NameAr = "دبل دير",
                    Description = "Carbonated drink",
                    DescriptionAr = "مشروب غازي",
                    Price = 20.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    PictureFileName = "soft-drink.webp"
                },

                // ============== SNACKS (Category 7) ==============
                new("Chips")
                {
                    NameAr = "شيبسي",
                    Description = "Assorted potato chips",
                    DescriptionAr = "شيبسي بطاطس متنوع",
                    Price = 15.00m,
                    CatalogTypeId = 7,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    PictureFileName = "chips.webp"
                },
                new("Peanuts")
                {
                    NameAr = "فول سوداني",
                    Description = "Roasted peanuts",
                    DescriptionAr = "فول سوداني محمص",
                    Price = 20.00m,
                    CatalogTypeId = 7,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    PictureFileName = "peanuts.webp"
                },

                // ============== DESSERTS (Category 8) ==============
                new("Waffle")
                {
                    NameAr = "وافل",
                    Description = "Belgian waffle with toppings",
                    DescriptionAr = "وافل بلجيكي مع الإضافات",
                    Price = 70.00m,
                    CatalogTypeId = 8,
                    IsAvailable = true,
                    PreparationTimeMinutes = 10,
                    PictureFileName = "waffles.webp"
                },
                new("Oreo Piece")
                {
                    NameAr = "قطعة أوريو",
                    Description = "Oreo cookie dessert piece",
                    DescriptionAr = "قطعة حلوى أوريو",
                    Price = 15.00m,
                    CatalogTypeId = 8,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    PictureFileName = "oreo-piece.webp"
                }
            };

            await context.CatalogItems.AddRangeAsync(menuItems);
            await context.SaveChangesAsync();
            logger.LogInformation("Seeded catalog with {NumItems} menu items", menuItems.Count);

            // Add customizations for Turkish Coffee
            var turkishCoffee = await context.CatalogItems.FirstOrDefaultAsync(i => i.Name == "Turkish Coffee");
            if (turkishCoffee != null)
            {
                var customizations = new List<ItemCustomization>
                {
                    new("Size") { NameAr = "الحجم",
                        CatalogItemId = turkishCoffee.Id,
                        IsRequired = true,
                        AllowMultiple = false,
                        DisplayOrder = 1,
                        Options = new List<CustomizationOption>
                        {
                            new("Single") { NameAr = "سنجل", PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new("Double") { NameAr = "دبل", PriceAdjustment = 15.00m, IsDefault = false, DisplayOrder = 2 }
                        }
                    },
                    new("Tahwiga") { NameAr = "التحويجة",
                        CatalogItemId = turkishCoffee.Id,
                        IsRequired = false,
                        AllowMultiple = false,
                        DisplayOrder = 2,
                        Options = new List<CustomizationOption>
                        {
                            new("Plain") { NameAr = "سادة", PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new("Light") { NameAr = "خفيفة", PriceAdjustment = 0, IsDefault = false, DisplayOrder = 2 },
                            new("Medium") { NameAr = "متوسطة", PriceAdjustment = 0, IsDefault = false, DisplayOrder = 3 },
                            new("Heavy") { NameAr = "تقيلة", PriceAdjustment = 0, IsDefault = false, DisplayOrder = 4 }
                        }
                    },
                    new("Roasting") { NameAr = "التحميص",
                        CatalogItemId = turkishCoffee.Id,
                        IsRequired = false,
                        AllowMultiple = false,
                        DisplayOrder = 3,
                        Options = new List<CustomizationOption>
                        {
                            new("Light Roast") { NameAr = "تحميص خفيف", PriceAdjustment = 0, IsDefault = false, DisplayOrder = 1 },
                            new("Medium Roast") { NameAr = "تحميص متوسط", PriceAdjustment = 0, IsDefault = true, DisplayOrder = 2 },
                            new("Dark Roast") { NameAr = "تحميص غامق", PriceAdjustment = 0, IsDefault = false, DisplayOrder = 3 }
                        }
                    },
                    new("Sugar Level") { NameAr = "مستوى السكر",
                        CatalogItemId = turkishCoffee.Id,
                        IsRequired = false,
                        AllowMultiple = false,
                        DisplayOrder = 4,
                        Options = new List<CustomizationOption>
                        {
                            new("No Sugar (Sada)") { NameAr = "سادة", PriceAdjustment = 0, IsDefault = false, DisplayOrder = 1 },
                            new("Light Sugar") { NameAr = "سكر خفيف", PriceAdjustment = 0, IsDefault = false, DisplayOrder = 2 },
                            new("Medium Sugar (Mazboot)") { NameAr = "مظبوط", PriceAdjustment = 0, IsDefault = true, DisplayOrder = 3 },
                            new("Sweet (Ziyada)") { NameAr = "زيادة", PriceAdjustment = 0, IsDefault = false, DisplayOrder = 4 }
                        }
                    },
                    new("Cup Size") { NameAr = "حجم الفنجان",
                        CatalogItemId = turkishCoffee.Id,
                        IsRequired = false,
                        AllowMultiple = false,
                        DisplayOrder = 5,
                        Options = new List<CustomizationOption>
                        {
                            new("Regular Cup") { NameAr = "فنجان عادي", PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new("Large Cup") { NameAr = "فنجان كبير", PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 2 }
                        }
                    }
                };
                await context.ItemCustomizations.AddRangeAsync(customizations);
            }

            // Add customizations for other coffees with size options
            var sizedCoffees = await context.CatalogItems
                .Where(i => i.Name == "Hazelnut Coffee" || i.Name == "French Coffee" ||
                           i.Name == "Caramel Coffee" || i.Name == "Macchiato" || i.Name == "Espresso")
                .ToListAsync();

            foreach (var coffee in sizedCoffees)
            {
                var customizations = new List<ItemCustomization>
                {
                    new("Size") { NameAr = "الحجم",
                        CatalogItemId = coffee.Id,
                        IsRequired = true,
                        AllowMultiple = false,
                        DisplayOrder = 1,
                        Options = new List<CustomizationOption>
                        {
                            new("Single") { NameAr = "سنجل", PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new("Double") { NameAr = "دبل", PriceAdjustment = coffee.Name == "Espresso" ? 15.00m : 10.00m, IsDefault = false, DisplayOrder = 2 }
                        }
                    },
                    new("Sugar Level") { NameAr = "مستوى السكر",
                        CatalogItemId = coffee.Id,
                        IsRequired = false,
                        AllowMultiple = false,
                        DisplayOrder = 2,
                        Options = new List<CustomizationOption>
                        {
                            new("No Sugar") { NameAr = "بدون سكر", PriceAdjustment = 0, IsDefault = false, DisplayOrder = 1 },
                            new("Light Sugar") { NameAr = "سكر خفيف", PriceAdjustment = 0, IsDefault = false, DisplayOrder = 2 },
                            new("Regular Sugar") { NameAr = "سكر عادي", PriceAdjustment = 0, IsDefault = true, DisplayOrder = 3 },
                            new("Extra Sugar") { NameAr = "سكر زيادة", PriceAdjustment = 0, IsDefault = false, DisplayOrder = 4 }
                        }
                    }
                };
                await context.ItemCustomizations.AddRangeAsync(customizations);
            }

            // Add customizations for Nescafe
            var nescafe = await context.CatalogItems.FirstOrDefaultAsync(i => i.Name == "Nescafe");
            if (nescafe != null)
            {
                var customizations = new List<ItemCustomization>
                {
                    new("Type") { NameAr = "النوع",
                        CatalogItemId = nescafe.Id,
                        IsRequired = true,
                        AllowMultiple = false,
                        DisplayOrder = 1,
                        Options = new List<CustomizationOption>
                        {
                            new("Black") { NameAr = "سادة", PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new("With Milk") { NameAr = "بالحليب", PriceAdjustment = 10.00m, IsDefault = false, DisplayOrder = 2 }
                        }
                    }
                };
                await context.ItemCustomizations.AddRangeAsync(customizations);
            }

            // Add customizations for Tea
            var tea = await context.CatalogItems.FirstOrDefaultAsync(i => i.Name == "Tea");
            if (tea != null)
            {
                var customizations = new List<ItemCustomization>
                {
                    new("Type") { NameAr = "النوع",
                        CatalogItemId = tea.Id,
                        IsRequired = true,
                        AllowMultiple = false,
                        DisplayOrder = 1,
                        Options = new List<CustomizationOption>
                        {
                            new("Tea Bag") { NameAr = "كيس شاي", PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 1 },
                            new("Lipton") { NameAr = "ليبتون", PriceAdjustment = 0, IsDefault = true, DisplayOrder = 2 },
                            new("With Milk") { NameAr = "بالحليب", PriceAdjustment = 10.00m, IsDefault = false, DisplayOrder = 3 },
                            new("With Mint") { NameAr = "بالنعناع", PriceAdjustment = 0, IsDefault = false, DisplayOrder = 4 },
                            new("With Lemon") { NameAr = "بالليمون", PriceAdjustment = 0, IsDefault = false, DisplayOrder = 5 }
                        }
                    },
                    new("Sugar Level") { NameAr = "مستوى السكر",
                        CatalogItemId = tea.Id,
                        IsRequired = false,
                        AllowMultiple = false,
                        DisplayOrder = 2,
                        Options = new List<CustomizationOption>
                        {
                            new("No Sugar") { NameAr = "بدون سكر", PriceAdjustment = 0, IsDefault = false, DisplayOrder = 1 },
                            new("Light Sugar") { NameAr = "سكر خفيف", PriceAdjustment = 0, IsDefault = false, DisplayOrder = 2 },
                            new("Regular Sugar") { NameAr = "سكر عادي", PriceAdjustment = 0, IsDefault = true, DisplayOrder = 3 },
                            new("Extra Sugar") { NameAr = "سكر زيادة", PriceAdjustment = 0, IsDefault = false, DisplayOrder = 4 }
                        }
                    },
                    new("Cup Size") { NameAr = "حجم الفنجان",
                        CatalogItemId = tea.Id,
                        IsRequired = false,
                        AllowMultiple = false,
                        DisplayOrder = 3,
                        Options = new List<CustomizationOption>
                        {
                            new("Regular Cup") { NameAr = "فنجان عادي", PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new("Large Cup") { NameAr = "فنجان كبير", PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 2 }
                        }
                    }
                };
                await context.ItemCustomizations.AddRangeAsync(customizations);
            }

            // Add customizations for Herbal Tea
            var herbalTea = await context.CatalogItems.FirstOrDefaultAsync(i => i.Name == "Herbal Tea");
            if (herbalTea != null)
            {
                var customizations = new List<ItemCustomization>
                {
                    new("Type") { NameAr = "النوع",
                        CatalogItemId = herbalTea.Id,
                        IsRequired = true,
                        AllowMultiple = false,
                        DisplayOrder = 1,
                        Options = new List<CustomizationOption>
                        {
                            new("Mint") { NameAr = "نعناع", PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new("Anise") { NameAr = "يانسون", PriceAdjustment = 0, IsDefault = false, DisplayOrder = 2 },
                            new("Hibiscus") { NameAr = "كركديه", PriceAdjustment = 0, IsDefault = false, DisplayOrder = 3 },
                            new("Cinnamon") { NameAr = "قرفة", PriceAdjustment = 0, IsDefault = false, DisplayOrder = 4 },
                            new("Cinnamon with Milk") { NameAr = "قرفة بالحليب", PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 5 },
                            new("Cinnamon Ginger") { NameAr = "قرفة بالزنجبيل", PriceAdjustment = 0, IsDefault = false, DisplayOrder = 6 },
                            new("Cocktail Mix") { NameAr = "كوكتيل مشكل", PriceAdjustment = 10.00m, IsDefault = false, DisplayOrder = 7 }
                        }
                    }
                };
                await context.ItemCustomizations.AddRangeAsync(customizations);
            }

            // Add customizations for Sahlab
            var sahlab = await context.CatalogItems.FirstOrDefaultAsync(i => i.Name == "Sahlab");
            if (sahlab != null)
            {
                var customizations = new List<ItemCustomization>
                {
                    new("Type") { NameAr = "النوع",
                        CatalogItemId = sahlab.Id,
                        IsRequired = true,
                        AllowMultiple = false,
                        DisplayOrder = 1,
                        Options = new List<CustomizationOption>
                        {
                            new("Plain") { NameAr = "سادة", PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new("With Chocolate") { NameAr = "بالشوكولاتة", PriceAdjustment = 10.00m, IsDefault = false, DisplayOrder = 2 },
                            new("With Nuts") { NameAr = "بالمكسرات", PriceAdjustment = 10.00m, IsDefault = false, DisplayOrder = 3 },
                            new("With Oreo") { NameAr = "بالأوريو", PriceAdjustment = 20.00m, IsDefault = false, DisplayOrder = 4 },
                            new("With Burio") { NameAr = "بالبوريو", PriceAdjustment = 20.00m, IsDefault = false, DisplayOrder = 5 },
                            new("With Fruits") { NameAr = "بالفواكه", PriceAdjustment = 25.00m, IsDefault = false, DisplayOrder = 6 }
                        }
                    }
                };
                await context.ItemCustomizations.AddRangeAsync(customizations);
            }

            // Add customizations for Hot Lemon
            var hotLemon = await context.CatalogItems.FirstOrDefaultAsync(i => i.Name == "Hot Lemon");
            if (hotLemon != null)
            {
                var customizations = new List<ItemCustomization>
                {
                    new("Type") { NameAr = "النوع",
                        CatalogItemId = hotLemon.Id,
                        IsRequired = true,
                        AllowMultiple = false,
                        DisplayOrder = 1,
                        Options = new List<CustomizationOption>
                        {
                            new("Plain") { NameAr = "سادة", PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new("With Honey") { NameAr = "بالعسل", PriceAdjustment = 10.00m, IsDefault = false, DisplayOrder = 2 }
                        }
                    }
                };
                await context.ItemCustomizations.AddRangeAsync(customizations);
            }

            // Add customizations for Milkshake
            var milkshake = await context.CatalogItems.FirstOrDefaultAsync(i => i.Name == "Milkshake");
            if (milkshake != null)
            {
                var customizations = new List<ItemCustomization>
                {
                    new("Flavor") { NameAr = "النكهة",
                        CatalogItemId = milkshake.Id,
                        IsRequired = true,
                        AllowMultiple = false,
                        DisplayOrder = 1,
                        Options = new List<CustomizationOption>
                        {
                            new("Chocolate") { NameAr = "شوكولاتة", PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new("Vanilla") { NameAr = "فانيليا", PriceAdjustment = 0, IsDefault = false, DisplayOrder = 2 },
                            new("Strawberry") { NameAr = "فراولة", PriceAdjustment = 20.00m, IsDefault = false, DisplayOrder = 3 },
                            new("Caramel") { NameAr = "كراميل", PriceAdjustment = 0, IsDefault = false, DisplayOrder = 4 }
                        }
                    }
                };
                await context.ItemCustomizations.AddRangeAsync(customizations);
            }

            // Add customizations for Oreo and Burio shakes
            var shakes = await context.CatalogItems
                .Where(i => i.Name == "Oreo Shake" || i.Name == "Burio Shake")
                .ToListAsync();

            foreach (var shake in shakes)
            {
                var customizations = new List<ItemCustomization>
                {
                    new("Type") { NameAr = "النوع",
                        CatalogItemId = shake.Id,
                        IsRequired = true,
                        AllowMultiple = false,
                        DisplayOrder = 1,
                        Options = new List<CustomizationOption>
                        {
                            new("Plain") { NameAr = "سادة", PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new("With Chunks") { NameAr = "بالقطع", PriceAdjustment = 10.00m, IsDefault = false, DisplayOrder = 2 }
                        }
                    }
                };
                await context.ItemCustomizations.AddRangeAsync(customizations);
            }

            // Add customizations for Yogurt
            var yogurt = await context.CatalogItems.FirstOrDefaultAsync(i => i.Name == "Yogurt");
            if (yogurt != null)
            {
                var customizations = new List<ItemCustomization>
                {
                    new("Type") { NameAr = "النوع",
                        CatalogItemId = yogurt.Id,
                        IsRequired = true,
                        AllowMultiple = false,
                        DisplayOrder = 1,
                        Options = new List<CustomizationOption>
                        {
                            new("Plain") { NameAr = "سادة", PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new("With Honey") { NameAr = "بالعسل", PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 2 },
                            new("With Fruits") { NameAr = "بالفواكه", PriceAdjustment = 30.00m, IsDefault = false, DisplayOrder = 3 }
                        }
                    }
                };
                await context.ItemCustomizations.AddRangeAsync(customizations);
            }

            // Add customizations for juices with milk option
            var juicesWithMilk = await context.CatalogItems
                .Where(i => i.Name == "Strawberry Juice" || i.Name == "Guava Juice" || i.Name == "Date Shake")
                .ToListAsync();

            foreach (var juice in juicesWithMilk)
            {
                var customizations = new List<ItemCustomization>
                {
                    new("Type") { NameAr = "النوع",
                        CatalogItemId = juice.Id,
                        IsRequired = true,
                        AllowMultiple = false,
                        DisplayOrder = 1,
                        Options = new List<CustomizationOption>
                        {
                            new("Plain") { NameAr = "سادة", PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new("With Milk") { NameAr = "بالحليب", PriceAdjustment = 10.00m, IsDefault = false, DisplayOrder = 2 }
                        }
                    }
                };
                await context.ItemCustomizations.AddRangeAsync(customizations);
            }

            // Add customizations for Lemonade
            var lemonade = await context.CatalogItems.FirstOrDefaultAsync(i => i.Name == "Lemonade");
            if (lemonade != null)
            {
                var customizations = new List<ItemCustomization>
                {
                    new("Type") { NameAr = "النوع",
                        CatalogItemId = lemonade.Id,
                        IsRequired = true,
                        AllowMultiple = false,
                        DisplayOrder = 1,
                        Options = new List<CustomizationOption>
                        {
                            new("Plain") { NameAr = "سادة", PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new("With Mint") { NameAr = "بالنعناع", PriceAdjustment = 10.00m, IsDefault = false, DisplayOrder = 2 }
                        }
                    }
                };
                await context.ItemCustomizations.AddRangeAsync(customizations);
            }

            // Add customizations for Schweppes
            var schweppes = await context.CatalogItems.FirstOrDefaultAsync(i => i.Name == "Schweppes");
            if (schweppes != null)
            {
                var customizations = new List<ItemCustomization>
                {
                    new("Flavor") { NameAr = "النكهة",
                        CatalogItemId = schweppes.Id,
                        IsRequired = true,
                        AllowMultiple = false,
                        DisplayOrder = 1,
                        Options = new List<CustomizationOption>
                        {
                            new("Lemon") { NameAr = "ليمون", PriceAdjustment = 5.00m, IsDefault = true, DisplayOrder = 1 },
                            new("Pomegranate") { NameAr = "رمان", PriceAdjustment = 0, IsDefault = false, DisplayOrder = 2 },
                            new("Gold") { NameAr = "جولد", PriceAdjustment = 0, IsDefault = false, DisplayOrder = 3 },
                            new("Tangerine") { NameAr = "يوسفي", PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 4 }
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
