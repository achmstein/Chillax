using System.Text.Json;
using Chillax.Catalog.API.Model;

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
                new(new LocalizedText("Coffee", "قهوة")) { Id = 1, DisplayOrder = 1 },
                new(new LocalizedText("Espresso", "اسبرسو")) { Id = 2, DisplayOrder = 2 },
                new(new LocalizedText("Hot Drinks", "مشروبات ساخنة")) { Id = 3, DisplayOrder = 3 },
                new(new LocalizedText("Iced Drinks", "مشروبات مثلجة")) { Id = 4, DisplayOrder = 4 },
                new(new LocalizedText("Juices", "عصائر")) { Id = 5, DisplayOrder = 5 },
                new(new LocalizedText("Soft Drinks", "مشروبات غازية")) { Id = 6, DisplayOrder = 6 },
                new(new LocalizedText("Snacks", "مقرمشات")) { Id = 7, DisplayOrder = 7 },
                new(new LocalizedText("Desserts", "حلويات")) { Id = 8, DisplayOrder = 8 }
            };

            context.CatalogTypes.RemoveRange(context.CatalogTypes);
            await context.CatalogTypes.AddRangeAsync(types);
            logger.LogInformation("Seeded catalog with {NumTypes} types", types.Count);
            await context.SaveChangesAsync();

            // Seed menu items based on actual Chillax menu
            var menuItems = new List<CatalogItem>
            {
                // ============== COFFEE (Category 1) ==============
                new(new LocalizedText("Turkish Coffee", "قهوة تركي"),
                    new LocalizedText("Traditional Turkish coffee brewed to perfection", "قهوة تركية تقليدية محضرة بإتقان"))
                {
                    Price = 25.00m,
                    CatalogTypeId = 1,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    DisplayOrder = 1,
                    PictureFileName = "turkish-coffee.webp"
                },
                new(new LocalizedText("Hazelnut Coffee", "قهوة بالبندق"),
                    new LocalizedText("Rich coffee with hazelnut flavor", "قهوة غنية بنكهة البندق"))
                {
                    Price = 35.00m,
                    CatalogTypeId = 1,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    DisplayOrder = 2,
                    PictureFileName = "hazelnut-coffee.webp"
                },
                new(new LocalizedText("French Coffee", "قهوة فرنسية"),
                    new LocalizedText("Smooth French-style coffee", "قهوة فرنسية ناعمة"))
                {
                    Price = 35.00m,
                    CatalogTypeId = 1,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    DisplayOrder = 3,
                    PictureFileName = "french-coffee.webp"
                },
                new(new LocalizedText("Caramel Coffee", "قهوة بالكراميل"),
                    new LocalizedText("Sweet caramel flavored coffee", "قهوة حلوة بنكهة الكراميل"))
                {
                    Price = 30.00m,
                    CatalogTypeId = 1,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    DisplayOrder = 4,
                    PictureFileName = "caramel-coffee.webp"
                },
                new(new LocalizedText("Cappuccino", "كابتشينو"),
                    new LocalizedText("Classic Italian cappuccino with steamed milk foam", "كابتشينو إيطالي كلاسيكي مع رغوة الحليب"))
                {
                    Price = 50.00m,
                    CatalogTypeId = 1,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    DisplayOrder = 5,
                    PictureFileName = "cappuccino.webp"
                },
                new(new LocalizedText("Latte", "لاتيه"),
                    new LocalizedText("Espresso with smooth steamed milk", "اسبرسو مع حليب مبخر ناعم"))
                {
                    Price = 50.00m,
                    CatalogTypeId = 1,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    DisplayOrder = 6,
                    PictureFileName = "latte.webp"
                },
                new(new LocalizedText("Macchiato", "ماكياتو"),
                    new LocalizedText("Espresso marked with a dash of milk foam", "اسبرسو مع لمسة من رغوة الحليب"))
                {
                    Price = 40.00m,
                    CatalogTypeId = 1,
                    IsAvailable = true,
                    PreparationTimeMinutes = 4,
                    DisplayOrder = 7,
                    PictureFileName = "macchiato.webp"
                },
                new(new LocalizedText("Nescafe", "نسكافيه"),
                    new LocalizedText("Instant coffee, available black or with milk", "قهوة سريعة التحضير، سادة أو بالحليب"))
                {
                    Price = 35.00m,
                    CatalogTypeId = 1,
                    IsAvailable = true,
                    PreparationTimeMinutes = 3,
                    DisplayOrder = 8,
                    PictureFileName = "nescafe.webp"
                },
                new(new LocalizedText("American Coffee", "قهوة أمريكية"),
                    new LocalizedText("Classic American-style brewed coffee", "قهوة أمريكية كلاسيكية"))
                {
                    Price = 60.00m,
                    CatalogTypeId = 1,
                    IsAvailable = true,
                    PreparationTimeMinutes = 3,
                    DisplayOrder = 9,
                    PictureFileName = "americano.webp"
                },

                // ============== ESPRESSO (Category 2) ==============
                new(new LocalizedText("Espresso", "اسبرسو"),
                    new LocalizedText("Strong Italian espresso shot", "شوت اسبرسو إيطالي قوي"))
                {
                    Price = 35.00m,
                    CatalogTypeId = 2,
                    IsAvailable = true,
                    PreparationTimeMinutes = 3,
                    DisplayOrder = 1,
                    PictureFileName = "espresso.webp"
                },
                new(new LocalizedText("Mocha", "موكا"),
                    new LocalizedText("Espresso with chocolate and steamed milk", "اسبرسو مع الشوكولاتة والحليب المبخر"))
                {
                    Price = 60.00m,
                    CatalogTypeId = 2,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    DisplayOrder = 2,
                    PictureFileName = "mocha.webp"
                },
                new(new LocalizedText("Iced Mocha", "موكا مثلجة"),
                    new LocalizedText("Chilled mocha with ice", "موكا باردة مع الثلج"))
                {
                    Price = 60.00m,
                    CatalogTypeId = 2,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    DisplayOrder = 3,
                    PictureFileName = "iced-mocha.webp"
                },

                // ============== HOT DRINKS (Category 3) ==============
                new(new LocalizedText("Tea", "شاي"),
                    new LocalizedText("Traditional tea, available in various styles", "شاي تقليدي متاح بأنواع مختلفة"))
                {
                    Price = 15.00m,
                    CatalogTypeId = 3,
                    IsAvailable = true,
                    PreparationTimeMinutes = 3,
                    DisplayOrder = 1,
                    PictureFileName = "tea.webp"
                },
                new(new LocalizedText("Green Tea", "شاي أخضر"),
                    new LocalizedText("Healthy green tea", "شاي أخضر صحي"))
                {
                    Price = 20.00m,
                    CatalogTypeId = 3,
                    IsAvailable = true,
                    PreparationTimeMinutes = 3,
                    DisplayOrder = 2,
                    PictureFileName = "green-tea.webp"
                },
                new(new LocalizedText("Herbal Tea", "شاي أعشاب"),
                    new LocalizedText("Soothing herbal infusion - mint, anise, hibiscus, cinnamon", "منقوع أعشاب مهدئ - نعناع، يانسون، كركديه، قرفة"))
                {
                    Price = 20.00m,
                    CatalogTypeId = 3,
                    IsAvailable = true,
                    PreparationTimeMinutes = 4,
                    DisplayOrder = 3,
                    PictureFileName = "herbal-tea.webp"
                },
                new(new LocalizedText("Hot Lemon", "ليمون ساخن"),
                    new LocalizedText("Warm lemon drink, optional honey", "مشروب ليمون دافئ، بالعسل اختياري"))
                {
                    Price = 25.00m,
                    CatalogTypeId = 3,
                    IsAvailable = true,
                    PreparationTimeMinutes = 3,
                    DisplayOrder = 4,
                    PictureFileName = "hot-lemon.webp"
                },
                new(new LocalizedText("Hot Chocolate", "شوكولاتة ساخنة"),
                    new LocalizedText("Rich and creamy hot chocolate", "شوكولاتة ساخنة غنية وكريمية"))
                {
                    Price = 50.00m,
                    CatalogTypeId = 3,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    DisplayOrder = 5,
                    PictureFileName = "hot-chocolate.webp"
                },
                new(new LocalizedText("Hot Cider", "سيدر ساخن"),
                    new LocalizedText("Warm apple cider", "سيدر تفاح دافئ"))
                {
                    Price = 45.00m,
                    CatalogTypeId = 3,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    DisplayOrder = 6,
                    PictureFileName = "hot-cider.webp"
                },
                new(new LocalizedText("Sahlab", "سحلب"),
                    new LocalizedText("Traditional creamy orchid root drink with toppings", "سحلب تقليدي كريمي مع الإضافات"))
                {
                    Price = 40.00m,
                    CatalogTypeId = 3,
                    IsAvailable = true,
                    PreparationTimeMinutes = 7,
                    DisplayOrder = 7,
                    PictureFileName = "sahlab.webp"
                },
                new(new LocalizedText("Hummus Al-Sham", "حمص الشام"),
                    new LocalizedText("Traditional Egyptian warm chickpea drink", "حمص الشام المصري التقليدي الدافئ"))
                {
                    Price = 40.00m,
                    CatalogTypeId = 3,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    DisplayOrder = 8,
                    PictureFileName = "hummus-sham.webp"
                },

                // ============== ICED DRINKS (Category 4) ==============
                new(new LocalizedText("Iced Coffee", "قهوة مثلجة"),
                    new LocalizedText("Chilled coffee over ice", "قهوة باردة مع الثلج"))
                {
                    Price = 60.00m,
                    CatalogTypeId = 4,
                    IsAvailable = true,
                    PreparationTimeMinutes = 4,
                    DisplayOrder = 1,
                    PictureFileName = "iced-latte.webp"
                },
                new(new LocalizedText("Frappuccino", "فرابتشينو"),
                    new LocalizedText("Blended iced coffee drink", "مشروب قهوة مثلجة مخفوقة"))
                {
                    Price = 80.00m,
                    CatalogTypeId = 4,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    DisplayOrder = 2,
                    PictureFileName = "frappuccino.webp"
                },
                new(new LocalizedText("Flat White", "فلات وايت"),
                    new LocalizedText("Iced flat white with velvety milk", "فلات وايت مثلج مع حليب ناعم"))
                {
                    Price = 80.00m,
                    CatalogTypeId = 4,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    DisplayOrder = 3,
                    PictureFileName = "flat-white.webp"
                },
                new(new LocalizedText("Iced Chocolate", "شوكولاتة مثلجة"),
                    new LocalizedText("Cold chocolate drink over ice", "مشروب شوكولاتة بارد مع الثلج"))
                {
                    Price = 60.00m,
                    CatalogTypeId = 4,
                    IsAvailable = true,
                    PreparationTimeMinutes = 4,
                    DisplayOrder = 4,
                    PictureFileName = "iced-chocolate.webp"
                },
                new(new LocalizedText("Milkshake", "ميلك شيك"),
                    new LocalizedText("Creamy milkshake - chocolate, vanilla, strawberry, or caramel", "ميلك شيك كريمي - شوكولاتة، فانيليا، فراولة، أو كراميل"))
                {
                    Price = 50.00m,
                    CatalogTypeId = 4,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    DisplayOrder = 5,
                    PictureFileName = "milkshake.webp"
                },
                new(new LocalizedText("Oreo Milkshake", "ميلك شيك أوريو"),
                    new LocalizedText("Creamy milkshake with Oreo cookies", "ميلك شيك كريمي مع بسكويت أوريو"))
                {
                    Price = 60.00m,
                    CatalogTypeId = 4,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    DisplayOrder = 6,
                    PictureFileName = "oreo-milkshake.webp"
                },
                new(new LocalizedText("Galaxy Milkshake", "ميلك شيك جالاكسي"),
                    new LocalizedText("Rich Galaxy chocolate milkshake", "ميلك شيك شوكولاتة جالاكسي غني"))
                {
                    Price = 80.00m,
                    CatalogTypeId = 4,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    DisplayOrder = 7,
                    PictureFileName = "galaxy-milkshake.webp"
                },
                new(new LocalizedText("Oreo Shake", "شيك أوريو"),
                    new LocalizedText("Oreo cookie blended shake", "شيك أوريو مخفوق"))
                {
                    Price = 60.00m,
                    CatalogTypeId = 4,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    DisplayOrder = 8,
                    PictureFileName = "oreo-shake.webp"
                },
                new(new LocalizedText("Burio Shake", "شيك بوريو"),
                    new LocalizedText("Burio chocolate blended shake", "شيك بوريو شوكولاتة مخفوق"))
                {
                    Price = 50.00m,
                    CatalogTypeId = 4,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    DisplayOrder = 9,
                    PictureFileName = "burio-shake.webp"
                },
                new(new LocalizedText("Yogurt", "زبادي"),
                    new LocalizedText("Fresh yogurt drink - plain, honey, or fruit", "مشروب زبادي طازج - سادة، بالعسل، أو بالفواكه"))
                {
                    Price = 35.00m,
                    CatalogTypeId = 4,
                    IsAvailable = true,
                    PreparationTimeMinutes = 3,
                    DisplayOrder = 10,
                    PictureFileName = "yogurt.webp"
                },
                new(new LocalizedText("Brownies Shake", "شيك براونيز"),
                    new LocalizedText("Chocolate brownies blended shake", "شيك براونيز شوكولاتة مخفوق"))
                {
                    Price = 45.00m,
                    CatalogTypeId = 4,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    DisplayOrder = 11,
                    PictureFileName = "brownie.webp"
                },
                new(new LocalizedText("Ice Cream Scoop", "سكوب آيس كريم"),
                    new LocalizedText("Premium ice cream scoop", "سكوب آيس كريم فاخر"))
                {
                    Price = 20.00m,
                    CatalogTypeId = 4,
                    IsAvailable = true,
                    PreparationTimeMinutes = 2,
                    DisplayOrder = 12,
                    PictureFileName = "ice-cream.webp"
                },

                // ============== JUICES (Category 5) ==============
                new(new LocalizedText("Orange Juice", "عصير برتقال"),
                    new LocalizedText("Freshly squeezed orange juice", "عصير برتقال طازج معصور"))
                {
                    Price = 20.00m,
                    CatalogTypeId = 5,
                    IsAvailable = true,
                    PreparationTimeMinutes = 4,
                    DisplayOrder = 1,
                    PictureFileName = "orange-juice.webp"
                },
                new(new LocalizedText("Mango Juice", "عصير مانجو"),
                    new LocalizedText("Fresh mango juice", "عصير مانجو طازج"))
                {
                    Price = 50.00m,
                    CatalogTypeId = 5,
                    IsAvailable = true,
                    PreparationTimeMinutes = 4,
                    DisplayOrder = 2,
                    PictureFileName = "mango-smoothie.webp"
                },
                new(new LocalizedText("Strawberry Juice", "عصير فراولة"),
                    new LocalizedText("Fresh strawberry juice, plain or with milk", "عصير فراولة طازج، سادة أو بالحليب"))
                {
                    Price = 50.00m,
                    CatalogTypeId = 5,
                    IsAvailable = true,
                    PreparationTimeMinutes = 4,
                    DisplayOrder = 3,
                    PictureFileName = "strawberry-smoothie.webp"
                },
                new(new LocalizedText("Guava Juice", "عصير جوافة"),
                    new LocalizedText("Fresh guava juice, plain or with milk", "عصير جوافة طازج، سادة أو بالحليب"))
                {
                    Price = 50.00m,
                    CatalogTypeId = 5,
                    IsAvailable = true,
                    PreparationTimeMinutes = 4,
                    DisplayOrder = 4,
                    PictureFileName = "guava-juice.webp"
                },
                new(new LocalizedText("Banana Juice", "عصير موز"),
                    new LocalizedText("Creamy banana juice", "عصير موز كريمي"))
                {
                    Price = 35.00m,
                    CatalogTypeId = 5,
                    IsAvailable = true,
                    PreparationTimeMinutes = 4,
                    DisplayOrder = 5,
                    PictureFileName = "banana-juice.webp"
                },
                new(new LocalizedText("Kiwi Juice", "عصير كيوي"),
                    new LocalizedText("Fresh kiwi juice", "عصير كيوي طازج"))
                {
                    Price = 50.00m,
                    CatalogTypeId = 5,
                    IsAvailable = true,
                    PreparationTimeMinutes = 4,
                    DisplayOrder = 6,
                    PictureFileName = "kiwi-juice.webp"
                },
                new(new LocalizedText("Lemonade", "ليمونادة"),
                    new LocalizedText("Fresh lemonade, plain or with mint", "ليمونادة طازجة، سادة أو بالنعناع"))
                {
                    Price = 30.00m,
                    CatalogTypeId = 5,
                    IsAvailable = true,
                    PreparationTimeMinutes = 4,
                    DisplayOrder = 7,
                    PictureFileName = "lemonade.webp"
                },
                new(new LocalizedText("Watermelon Juice", "عصير بطيخ"),
                    new LocalizedText("Refreshing watermelon juice", "عصير بطيخ منعش"))
                {
                    Price = 45.00m,
                    CatalogTypeId = 5,
                    IsAvailable = true,
                    PreparationTimeMinutes = 4,
                    DisplayOrder = 8,
                    PictureFileName = "watermelon-juice.webp"
                },
                new(new LocalizedText("Prickly Pear Juice", "عصير تين شوكي"),
                    new LocalizedText("Fresh prickly pear cactus fruit juice", "عصير تين شوكي طازج"))
                {
                    Price = 45.00m,
                    CatalogTypeId = 5,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    DisplayOrder = 9,
                    PictureFileName = "prickly-pear-juice.webp"
                },
                new(new LocalizedText("Date Shake", "شيك تمر"),
                    new LocalizedText("Sweet date shake, plain or with milk", "شيك تمر حلو، سادة أو بالحليب"))
                {
                    Price = 50.00m,
                    CatalogTypeId = 5,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    DisplayOrder = 10,
                    PictureFileName = "date-shake.webp"
                },
                new(new LocalizedText("Fruit Salad", "سلطة فواكه"),
                    new LocalizedText("Mixed fresh fruit salad", "سلطة فواكه طازجة مشكلة"))
                {
                    Price = 40.00m,
                    CatalogTypeId = 5,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    DisplayOrder = 11,
                    PictureFileName = "fruit-salad.webp"
                },
                new(new LocalizedText("Cocktail Juice", "عصير كوكتيل"),
                    new LocalizedText("Mixed fruit cocktail juice", "عصير كوكتيل فواكه مشكل"))
                {
                    Price = 60.00m,
                    CatalogTypeId = 5,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    DisplayOrder = 12,
                    PictureFileName = "cocktail-juice.webp"
                },
                new(new LocalizedText("Sunshine Juice", "عصير صن شاين"),
                    new LocalizedText("Refreshing sunshine blend juice", "عصير صن شاين منعش"))
                {
                    Price = 50.00m,
                    CatalogTypeId = 5,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    DisplayOrder = 13,
                    PictureFileName = "sunshine-juice.webp"
                },
                new(new LocalizedText("Florida Juice", "عصير فلوريدا"),
                    new LocalizedText("Florida-style citrus blend juice", "عصير حمضيات على طريقة فلوريدا"))
                {
                    Price = 60.00m,
                    CatalogTypeId = 5,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    DisplayOrder = 14,
                    PictureFileName = "florida-juice.webp"
                },

                // ============== SOFT DRINKS (Category 6) ==============
                new(new LocalizedText("Pepsi", "بيبسي"),
                    new LocalizedText("Chilled Pepsi cola", "بيبسي كولا مثلجة"))
                {
                    Price = 25.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    DisplayOrder = 1,
                    PictureFileName = "soft-drink.webp"
                },
                new(new LocalizedText("7Up", "سفن أب"),
                    new LocalizedText("Chilled lemon-lime soda", "مشروب غازي ليمون مثلج"))
                {
                    Price = 25.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    DisplayOrder = 2,
                    PictureFileName = "soft-drink.webp"
                },
                new(new LocalizedText("Mirinda", "ميرندا"),
                    new LocalizedText("Chilled orange soda", "مشروب غازي برتقال مثلج"))
                {
                    Price = 25.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    DisplayOrder = 3,
                    PictureFileName = "soft-drink.webp"
                },
                new(new LocalizedText("Mountain Dew", "ماونتن ديو"),
                    new LocalizedText("Chilled citrus soda", "مشروب غازي حمضيات مثلج"))
                {
                    Price = 25.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    DisplayOrder = 4,
                    PictureFileName = "soft-drink.webp"
                },
                new(new LocalizedText("Schweppes", "شويبس"),
                    new LocalizedText("Sparkling tonic - lemon, pomegranate, gold, or tangerine", "مشروب فوار - ليمون، رمان، جولد، أو يوسفي"))
                {
                    Price = 20.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    DisplayOrder = 5,
                    PictureFileName = "soft-drink.webp"
                },
                new(new LocalizedText("Birell", "بيريل"),
                    new LocalizedText("Non-alcoholic malt beverage", "مشروب شعير خالي من الكحول"))
                {
                    Price = 25.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    DisplayOrder = 6,
                    PictureFileName = "soft-drink.webp"
                },
                new(new LocalizedText("Mineral Water", "مياه معدنية"),
                    new LocalizedText("Bottled mineral water", "مياه معدنية معبأة"))
                {
                    Price = 8.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    DisplayOrder = 7,
                    PictureFileName = "mineral-water.webp"
                },
                new(new LocalizedText("Red Bull", "ريد بول"),
                    new LocalizedText("Energy drink", "مشروب طاقة"))
                {
                    Price = 65.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    DisplayOrder = 8,
                    PictureFileName = "red-bull.webp"
                },
                new(new LocalizedText("Power Horse", "باور هورس"),
                    new LocalizedText("Energy drink", "مشروب طاقة"))
                {
                    Price = 25.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    DisplayOrder = 9,
                    PictureFileName = "soft-drink.webp"
                },
                new(new LocalizedText("Buzz Energy", "بز إنرجي"),
                    new LocalizedText("Energy drink", "مشروب طاقة"))
                {
                    Price = 20.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    DisplayOrder = 10,
                    PictureFileName = "soft-drink.webp"
                },
                new(new LocalizedText("Amstel Zero", "أمستل زيرو"),
                    new LocalizedText("Non-alcoholic beer", "بيرة خالية من الكحول"))
                {
                    Price = 25.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    DisplayOrder = 11,
                    PictureFileName = "soft-drink.webp"
                },
                new(new LocalizedText("Barbican", "باربيكان"),
                    new LocalizedText("Non-alcoholic malt beverage", "مشروب شعير خالي من الكحول"))
                {
                    Price = 40.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    DisplayOrder = 12,
                    PictureFileName = "soft-drink.webp"
                },
                new(new LocalizedText("Moussy", "موسي"),
                    new LocalizedText("Non-alcoholic malt beverage", "مشروب شعير خالي من الكحول"))
                {
                    Price = 30.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    DisplayOrder = 13,
                    PictureFileName = "soft-drink.webp"
                },
                new(new LocalizedText("FreeGo", "فري جو"),
                    new LocalizedText("Soft drink", "مشروب غازي"))
                {
                    Price = 20.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    DisplayOrder = 14,
                    PictureFileName = "soft-drink.webp"
                },
                new(new LocalizedText("Snaps", "سنابس"),
                    new LocalizedText("Carbonated drink", "مشروب غازي"))
                {
                    Price = 20.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    DisplayOrder = 15,
                    PictureFileName = "soft-drink.webp"
                },
                new(new LocalizedText("Twist", "تويست"),
                    new LocalizedText("Carbonated lemon drink", "مشروب غازي بالليمون"))
                {
                    Price = 25.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    DisplayOrder = 16,
                    PictureFileName = "soft-drink.webp"
                },
                new(new LocalizedText("V7", "في سفن"),
                    new LocalizedText("Vegetable juice blend", "عصير خضروات مشكل"))
                {
                    Price = 25.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    DisplayOrder = 17,
                    PictureFileName = "soft-drink.webp"
                },
                new(new LocalizedText("Spiro Spathis", "سبيرو سباتس"),
                    new LocalizedText("Classic Egyptian lemon soda", "مشروب ليمون غازي مصري كلاسيكي"))
                {
                    Price = 20.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    DisplayOrder = 18,
                    PictureFileName = "soft-drink.webp"
                },
                new(new LocalizedText("Double Deer", "دبل دير"),
                    new LocalizedText("Carbonated drink", "مشروب غازي"))
                {
                    Price = 20.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    DisplayOrder = 19,
                    PictureFileName = "soft-drink.webp"
                },

                // ============== SNACKS (Category 7) ==============
                new(new LocalizedText("Chips", "شيبسي"),
                    new LocalizedText("Assorted potato chips", "شيبسي بطاطس متنوع"))
                {
                    Price = 15.00m,
                    CatalogTypeId = 7,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    DisplayOrder = 1,
                    PictureFileName = "chips.webp"
                },
                new(new LocalizedText("Peanuts", "فول سوداني"),
                    new LocalizedText("Roasted peanuts", "فول سوداني محمص"))
                {
                    Price = 20.00m,
                    CatalogTypeId = 7,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    DisplayOrder = 2,
                    PictureFileName = "peanuts.webp"
                },

                // ============== DESSERTS (Category 8) ==============
                new(new LocalizedText("Waffle", "وافل"),
                    new LocalizedText("Belgian waffle with toppings", "وافل بلجيكي مع الإضافات"))
                {
                    Price = 70.00m,
                    CatalogTypeId = 8,
                    IsAvailable = true,
                    PreparationTimeMinutes = 10,
                    DisplayOrder = 1,
                    PictureFileName = "waffles.webp"
                },
                new(new LocalizedText("Oreo Piece", "قطعة أوريو"),
                    new LocalizedText("Oreo cookie dessert piece", "قطعة حلوى أوريو"))
                {
                    Price = 15.00m,
                    CatalogTypeId = 8,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    DisplayOrder = 2,
                    PictureFileName = "oreo-piece.webp"
                }
            };

            await context.CatalogItems.AddRangeAsync(menuItems);
            await context.SaveChangesAsync();
            logger.LogInformation("Seeded catalog with {NumItems} menu items", menuItems.Count);

            // Add customizations for Turkish Coffee
            var turkishCoffee = await context.CatalogItems.FirstOrDefaultAsync(i => i.Name.En == "Turkish Coffee");
            if (turkishCoffee != null)
            {
                var customizations = new List<ItemCustomization>
                {
                    new(new LocalizedText("Size", "الحجم"))
                    {
                        CatalogItemId = turkishCoffee.Id,
                        IsRequired = true,
                        AllowMultiple = false,
                        DisplayOrder = 1,
                        Options = new List<CustomizationOption>
                        {
                            new(new LocalizedText("Single", "سنجل")) { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new(new LocalizedText("Double", "دبل")) { PriceAdjustment = 15.00m, IsDefault = false, DisplayOrder = 2 }
                        }
                    },
                    new(new LocalizedText("Tahwiga", "التحويجة"))
                    {
                        CatalogItemId = turkishCoffee.Id,
                        IsRequired = false,
                        AllowMultiple = false,
                        DisplayOrder = 2,
                        Options = new List<CustomizationOption>
                        {
                            new(new LocalizedText("Plain", "سادة")) { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new(new LocalizedText("Light", "خفيفة")) { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 2 },
                            new(new LocalizedText("Medium", "متوسطة")) { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 3 },
                            new(new LocalizedText("Heavy", "تقيلة")) { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 4 }
                        }
                    },
                    new(new LocalizedText("Roasting", "التحميص"))
                    {
                        CatalogItemId = turkishCoffee.Id,
                        IsRequired = false,
                        AllowMultiple = false,
                        DisplayOrder = 3,
                        Options = new List<CustomizationOption>
                        {
                            new(new LocalizedText("Light Roast", "تحميص خفيف")) { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 1 },
                            new(new LocalizedText("Medium Roast", "تحميص متوسط")) { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 2 },
                            new(new LocalizedText("Dark Roast", "تحميص غامق")) { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 3 }
                        }
                    },
                    new(new LocalizedText("Sugar Level", "مستوى السكر"))
                    {
                        CatalogItemId = turkishCoffee.Id,
                        IsRequired = false,
                        AllowMultiple = false,
                        DisplayOrder = 4,
                        Options = new List<CustomizationOption>
                        {
                            new(new LocalizedText("No Sugar (Sada)", "سادة")) { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 1 },
                            new(new LocalizedText("Light Sugar", "سكر خفيف")) { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 2 },
                            new(new LocalizedText("Medium Sugar (Mazboot)", "مظبوط")) { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 3 },
                            new(new LocalizedText("Sweet (Ziyada)", "زيادة")) { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 4 }
                        }
                    },
                    new(new LocalizedText("Cup Size", "حجم الفنجان"))
                    {
                        CatalogItemId = turkishCoffee.Id,
                        IsRequired = false,
                        AllowMultiple = false,
                        DisplayOrder = 5,
                        Options = new List<CustomizationOption>
                        {
                            new(new LocalizedText("Regular Cup", "فنجان عادي")) { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new(new LocalizedText("Large Cup", "فنجان كبير")) { PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 2 }
                        }
                    }
                };
                await context.ItemCustomizations.AddRangeAsync(customizations);
            }

            // Add customizations for other coffees with size options
            var sizedCoffees = await context.CatalogItems
                .Where(i => i.Name.En == "Hazelnut Coffee" || i.Name.En == "French Coffee" ||
                           i.Name.En == "Caramel Coffee" || i.Name.En == "Macchiato" || i.Name.En == "Espresso")
                .ToListAsync();

            foreach (var coffee in sizedCoffees)
            {
                var customizations = new List<ItemCustomization>
                {
                    new(new LocalizedText("Size", "الحجم"))
                    {
                        CatalogItemId = coffee.Id,
                        IsRequired = true,
                        AllowMultiple = false,
                        DisplayOrder = 1,
                        Options = new List<CustomizationOption>
                        {
                            new(new LocalizedText("Single", "سنجل")) { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new(new LocalizedText("Double", "دبل")) { PriceAdjustment = coffee.Name.En == "Espresso" ? 15.00m : 10.00m, IsDefault = false, DisplayOrder = 2 }
                        }
                    },
                    new(new LocalizedText("Sugar Level", "مستوى السكر"))
                    {
                        CatalogItemId = coffee.Id,
                        IsRequired = false,
                        AllowMultiple = false,
                        DisplayOrder = 2,
                        Options = new List<CustomizationOption>
                        {
                            new(new LocalizedText("No Sugar", "بدون سكر")) { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 1 },
                            new(new LocalizedText("Light Sugar", "سكر خفيف")) { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 2 },
                            new(new LocalizedText("Regular Sugar", "سكر عادي")) { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 3 },
                            new(new LocalizedText("Extra Sugar", "سكر زيادة")) { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 4 }
                        }
                    }
                };
                await context.ItemCustomizations.AddRangeAsync(customizations);
            }

            // Add customizations for Nescafe
            var nescafe = await context.CatalogItems.FirstOrDefaultAsync(i => i.Name.En == "Nescafe");
            if (nescafe != null)
            {
                var customizations = new List<ItemCustomization>
                {
                    new(new LocalizedText("Type", "النوع"))
                    {
                        CatalogItemId = nescafe.Id,
                        IsRequired = true,
                        AllowMultiple = false,
                        DisplayOrder = 1,
                        Options = new List<CustomizationOption>
                        {
                            new(new LocalizedText("Black", "سادة")) { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new(new LocalizedText("With Milk", "بالحليب")) { PriceAdjustment = 10.00m, IsDefault = false, DisplayOrder = 2 }
                        }
                    }
                };
                await context.ItemCustomizations.AddRangeAsync(customizations);
            }

            // Add customizations for Tea
            var tea = await context.CatalogItems.FirstOrDefaultAsync(i => i.Name.En == "Tea");
            if (tea != null)
            {
                var customizations = new List<ItemCustomization>
                {
                    new(new LocalizedText("Type", "النوع"))
                    {
                        CatalogItemId = tea.Id,
                        IsRequired = true,
                        AllowMultiple = false,
                        DisplayOrder = 1,
                        Options = new List<CustomizationOption>
                        {
                            new(new LocalizedText("Tea Bag", "كيس شاي")) { PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 1 },
                            new(new LocalizedText("Lipton", "ليبتون")) { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 2 },
                            new(new LocalizedText("With Milk", "بالحليب")) { PriceAdjustment = 10.00m, IsDefault = false, DisplayOrder = 3 },
                            new(new LocalizedText("With Mint", "بالنعناع")) { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 4 },
                            new(new LocalizedText("With Lemon", "بالليمون")) { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 5 }
                        }
                    },
                    new(new LocalizedText("Sugar Level", "مستوى السكر"))
                    {
                        CatalogItemId = tea.Id,
                        IsRequired = false,
                        AllowMultiple = false,
                        DisplayOrder = 2,
                        Options = new List<CustomizationOption>
                        {
                            new(new LocalizedText("No Sugar", "بدون سكر")) { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 1 },
                            new(new LocalizedText("Light Sugar", "سكر خفيف")) { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 2 },
                            new(new LocalizedText("Regular Sugar", "سكر عادي")) { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 3 },
                            new(new LocalizedText("Extra Sugar", "سكر زيادة")) { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 4 }
                        }
                    },
                    new(new LocalizedText("Cup Size", "حجم الفنجان"))
                    {
                        CatalogItemId = tea.Id,
                        IsRequired = false,
                        AllowMultiple = false,
                        DisplayOrder = 3,
                        Options = new List<CustomizationOption>
                        {
                            new(new LocalizedText("Regular Cup", "فنجان عادي")) { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new(new LocalizedText("Large Cup", "فنجان كبير")) { PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 2 }
                        }
                    }
                };
                await context.ItemCustomizations.AddRangeAsync(customizations);
            }

            // Add customizations for Herbal Tea
            var herbalTea = await context.CatalogItems.FirstOrDefaultAsync(i => i.Name.En == "Herbal Tea");
            if (herbalTea != null)
            {
                var customizations = new List<ItemCustomization>
                {
                    new(new LocalizedText("Type", "النوع"))
                    {
                        CatalogItemId = herbalTea.Id,
                        IsRequired = true,
                        AllowMultiple = false,
                        DisplayOrder = 1,
                        Options = new List<CustomizationOption>
                        {
                            new(new LocalizedText("Mint", "نعناع")) { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new(new LocalizedText("Anise", "يانسون")) { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 2 },
                            new(new LocalizedText("Hibiscus", "كركديه")) { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 3 },
                            new(new LocalizedText("Cinnamon", "قرفة")) { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 4 },
                            new(new LocalizedText("Cinnamon with Milk", "قرفة بالحليب")) { PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 5 },
                            new(new LocalizedText("Cinnamon Ginger", "قرفة بالزنجبيل")) { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 6 },
                            new(new LocalizedText("Cocktail Mix", "كوكتيل مشكل")) { PriceAdjustment = 10.00m, IsDefault = false, DisplayOrder = 7 }
                        }
                    }
                };
                await context.ItemCustomizations.AddRangeAsync(customizations);
            }

            // Add customizations for Sahlab
            var sahlab = await context.CatalogItems.FirstOrDefaultAsync(i => i.Name.En == "Sahlab");
            if (sahlab != null)
            {
                var customizations = new List<ItemCustomization>
                {
                    new(new LocalizedText("Type", "النوع"))
                    {
                        CatalogItemId = sahlab.Id,
                        IsRequired = true,
                        AllowMultiple = false,
                        DisplayOrder = 1,
                        Options = new List<CustomizationOption>
                        {
                            new(new LocalizedText("Plain", "سادة")) { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new(new LocalizedText("With Chocolate", "بالشوكولاتة")) { PriceAdjustment = 10.00m, IsDefault = false, DisplayOrder = 2 },
                            new(new LocalizedText("With Nuts", "بالمكسرات")) { PriceAdjustment = 10.00m, IsDefault = false, DisplayOrder = 3 },
                            new(new LocalizedText("With Oreo", "بالأوريو")) { PriceAdjustment = 20.00m, IsDefault = false, DisplayOrder = 4 },
                            new(new LocalizedText("With Burio", "بالبوريو")) { PriceAdjustment = 20.00m, IsDefault = false, DisplayOrder = 5 },
                            new(new LocalizedText("With Fruits", "بالفواكه")) { PriceAdjustment = 25.00m, IsDefault = false, DisplayOrder = 6 }
                        }
                    }
                };
                await context.ItemCustomizations.AddRangeAsync(customizations);
            }

            // Add customizations for Hot Lemon
            var hotLemon = await context.CatalogItems.FirstOrDefaultAsync(i => i.Name.En == "Hot Lemon");
            if (hotLemon != null)
            {
                var customizations = new List<ItemCustomization>
                {
                    new(new LocalizedText("Type", "النوع"))
                    {
                        CatalogItemId = hotLemon.Id,
                        IsRequired = true,
                        AllowMultiple = false,
                        DisplayOrder = 1,
                        Options = new List<CustomizationOption>
                        {
                            new(new LocalizedText("Plain", "سادة")) { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new(new LocalizedText("With Honey", "بالعسل")) { PriceAdjustment = 10.00m, IsDefault = false, DisplayOrder = 2 }
                        }
                    }
                };
                await context.ItemCustomizations.AddRangeAsync(customizations);
            }

            // Add customizations for Milkshake
            var milkshake = await context.CatalogItems.FirstOrDefaultAsync(i => i.Name.En == "Milkshake");
            if (milkshake != null)
            {
                var customizations = new List<ItemCustomization>
                {
                    new(new LocalizedText("Flavor", "النكهة"))
                    {
                        CatalogItemId = milkshake.Id,
                        IsRequired = true,
                        AllowMultiple = false,
                        DisplayOrder = 1,
                        Options = new List<CustomizationOption>
                        {
                            new(new LocalizedText("Chocolate", "شوكولاتة")) { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new(new LocalizedText("Vanilla", "فانيليا")) { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 2 },
                            new(new LocalizedText("Strawberry", "فراولة")) { PriceAdjustment = 20.00m, IsDefault = false, DisplayOrder = 3 },
                            new(new LocalizedText("Caramel", "كراميل")) { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 4 }
                        }
                    }
                };
                await context.ItemCustomizations.AddRangeAsync(customizations);
            }

            // Add customizations for Oreo and Burio shakes
            var shakes = await context.CatalogItems
                .Where(i => i.Name.En == "Oreo Shake" || i.Name.En == "Burio Shake")
                .ToListAsync();

            foreach (var shake in shakes)
            {
                var customizations = new List<ItemCustomization>
                {
                    new(new LocalizedText("Type", "النوع"))
                    {
                        CatalogItemId = shake.Id,
                        IsRequired = true,
                        AllowMultiple = false,
                        DisplayOrder = 1,
                        Options = new List<CustomizationOption>
                        {
                            new(new LocalizedText("Plain", "سادة")) { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new(new LocalizedText("With Chunks", "بالقطع")) { PriceAdjustment = 10.00m, IsDefault = false, DisplayOrder = 2 }
                        }
                    }
                };
                await context.ItemCustomizations.AddRangeAsync(customizations);
            }

            // Add customizations for Yogurt
            var yogurt = await context.CatalogItems.FirstOrDefaultAsync(i => i.Name.En == "Yogurt");
            if (yogurt != null)
            {
                var customizations = new List<ItemCustomization>
                {
                    new(new LocalizedText("Type", "النوع"))
                    {
                        CatalogItemId = yogurt.Id,
                        IsRequired = true,
                        AllowMultiple = false,
                        DisplayOrder = 1,
                        Options = new List<CustomizationOption>
                        {
                            new(new LocalizedText("Plain", "سادة")) { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new(new LocalizedText("With Honey", "بالعسل")) { PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 2 },
                            new(new LocalizedText("With Fruits", "بالفواكه")) { PriceAdjustment = 30.00m, IsDefault = false, DisplayOrder = 3 }
                        }
                    }
                };
                await context.ItemCustomizations.AddRangeAsync(customizations);
            }

            // Add customizations for juices with milk option
            var juicesWithMilk = await context.CatalogItems
                .Where(i => i.Name.En == "Strawberry Juice" || i.Name.En == "Guava Juice" || i.Name.En == "Date Shake")
                .ToListAsync();

            foreach (var juice in juicesWithMilk)
            {
                var customizations = new List<ItemCustomization>
                {
                    new(new LocalizedText("Type", "النوع"))
                    {
                        CatalogItemId = juice.Id,
                        IsRequired = true,
                        AllowMultiple = false,
                        DisplayOrder = 1,
                        Options = new List<CustomizationOption>
                        {
                            new(new LocalizedText("Plain", "سادة")) { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new(new LocalizedText("With Milk", "بالحليب")) { PriceAdjustment = 10.00m, IsDefault = false, DisplayOrder = 2 }
                        }
                    }
                };
                await context.ItemCustomizations.AddRangeAsync(customizations);
            }

            // Add customizations for Lemonade
            var lemonade = await context.CatalogItems.FirstOrDefaultAsync(i => i.Name.En == "Lemonade");
            if (lemonade != null)
            {
                var customizations = new List<ItemCustomization>
                {
                    new(new LocalizedText("Type", "النوع"))
                    {
                        CatalogItemId = lemonade.Id,
                        IsRequired = true,
                        AllowMultiple = false,
                        DisplayOrder = 1,
                        Options = new List<CustomizationOption>
                        {
                            new(new LocalizedText("Plain", "سادة")) { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new(new LocalizedText("With Mint", "بالنعناع")) { PriceAdjustment = 10.00m, IsDefault = false, DisplayOrder = 2 }
                        }
                    }
                };
                await context.ItemCustomizations.AddRangeAsync(customizations);
            }

            // Add customizations for Schweppes
            var schweppes = await context.CatalogItems.FirstOrDefaultAsync(i => i.Name.En == "Schweppes");
            if (schweppes != null)
            {
                var customizations = new List<ItemCustomization>
                {
                    new(new LocalizedText("Flavor", "النكهة"))
                    {
                        CatalogItemId = schweppes.Id,
                        IsRequired = true,
                        AllowMultiple = false,
                        DisplayOrder = 1,
                        Options = new List<CustomizationOption>
                        {
                            new(new LocalizedText("Lemon", "ليمون")) { PriceAdjustment = 5.00m, IsDefault = true, DisplayOrder = 1 },
                            new(new LocalizedText("Pomegranate", "رمان")) { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 2 },
                            new(new LocalizedText("Gold", "جولد")) { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 3 },
                            new(new LocalizedText("Tangerine", "يوسفي")) { PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 4 }
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
