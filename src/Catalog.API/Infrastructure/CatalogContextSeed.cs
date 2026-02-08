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

            // Seed menu items based on Loyverse export
            var menuItems = new List<CatalogItem>
            {
                // ============== COFFEE - قهوة (Category 1) ==============
                new(new LocalizedText("Turkish Coffee", "قهوة تركي"),
                    new LocalizedText("Our signature Turkish coffee, roasted fresh daily", "قهوتنا التركي المميزة، محمصة طازة كل يوم"))
                {
                    Price = 25.00m,
                    CatalogTypeId = 1,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    DisplayOrder = 1,
                    PictureFileName = "turkish-coffee.webp"
                },
                new(new LocalizedText("Hazelnut Coffee", "قهوة بندق"),
                    new LocalizedText("Turkish coffee with rich hazelnut flavor", "قهوة تركي بنكهة البندق الغنية"))
                {
                    Price = 35.00m,
                    CatalogTypeId = 1,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    DisplayOrder = 2,
                    PictureFileName = "hazelnut-coffee.webp"
                },
                new(new LocalizedText("French Coffee", "قهوة فرنساوي"),
                    new LocalizedText("Smooth French-style coffee with a creamy taste", "قهوة فرنساوي ناعمة بطعم كريمي"))
                {
                    Price = 35.00m,
                    CatalogTypeId = 1,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    DisplayOrder = 3,
                    PictureFileName = "french-coffee.webp"
                },
                new(new LocalizedText("Caramel Coffee", "قهوة كاراميل"),
                    new LocalizedText("Sweet caramel flavored Turkish coffee", "قهوة تركي بنكهة الكراميل الحلوة"))
                {
                    Price = 30.00m,
                    CatalogTypeId = 1,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    DisplayOrder = 4,
                    PictureFileName = "caramel-coffee.webp"
                },
                new(new LocalizedText("Cappuccino", "كابتشينو"),
                    new LocalizedText("Classic Italian cappuccino with creamy foam", "كابتشينو إيطالي كلاسيك برغوة كريمية"))
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
                new(new LocalizedText("Macchiato", "ميكاتو"),
                    new LocalizedText("Strong espresso with a touch of milk foam", "اسبرسو قوي بلمسة من رغوة الحليب"))
                {
                    Price = 40.00m,
                    CatalogTypeId = 1,
                    IsAvailable = true,
                    PreparationTimeMinutes = 4,
                    DisplayOrder = 7,
                    PictureFileName = "macchiato.webp"
                },
                new(new LocalizedText("Nescafe", "نسكافيه"),
                    new LocalizedText("Instant Nescafe, black or with milk", "نسكافيه سريع التحضير، سادة أو بالحليب"))
                {
                    Price = 35.00m,
                    CatalogTypeId = 1,
                    IsAvailable = true,
                    PreparationTimeMinutes = 3,
                    DisplayOrder = 8,
                    PictureFileName = "nescafe.webp"
                },
                new(new LocalizedText("American Coffee", "امريكان كوفي"),
                    new LocalizedText("Classic American brewed coffee", "قهوة أمريكان كلاسيك"))
                {
                    Price = 60.00m,
                    CatalogTypeId = 1,
                    IsAvailable = true,
                    PreparationTimeMinutes = 3,
                    DisplayOrder = 9,
                    PictureFileName = "americano.webp"
                },

                // ============== ESPRESSO - اسبرسو (Category 2) ==============
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
                    new LocalizedText("Espresso with chocolate and steamed milk", "اسبرسو بالشوكولاتة والحليب"))
                {
                    Price = 60.00m,
                    CatalogTypeId = 2,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    DisplayOrder = 2,
                    PictureFileName = "mocha.webp"
                },
                new(new LocalizedText("Iced Mocha", "آيس موكا"),
                    new LocalizedText("Chilled mocha with ice, perfect for hot days", "موكا ساقعة بالتلج، مثالية للأيام الحر"))
                {
                    Price = 60.00m,
                    CatalogTypeId = 2,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    DisplayOrder = 3,
                    PictureFileName = "iced-mocha.webp"
                },

                // ============== HOT DRINKS - مشروبات ساخنة (Category 3) ==============
                new(new LocalizedText("Tea", "شاي"),
                    new LocalizedText("Traditional Egyptian tea, the way you like it", "شاي مصري تقليدي، زي ما بتحبه"))
                {
                    Price = 15.00m,
                    CatalogTypeId = 3,
                    IsAvailable = true,
                    PreparationTimeMinutes = 3,
                    DisplayOrder = 1,
                    PictureFileName = "tea.webp"
                },
                new(new LocalizedText("Green Tea", "شاي اخضر"),
                    new LocalizedText("Healthy green tea for a refreshing experience", "شاي أخضر صحي لتجربة منعشة"))
                {
                    Price = 20.00m,
                    CatalogTypeId = 3,
                    IsAvailable = true,
                    PreparationTimeMinutes = 3,
                    DisplayOrder = 2,
                    PictureFileName = "green-tea.webp"
                },
                new(new LocalizedText("Herbal Tea", "أعشاب"),
                    new LocalizedText("Soothing herbal infusion - mint, anise, hibiscus, cinnamon", "أعشاب مهدئة - نعناع، ينسون، كركديه، قرفة"))
                {
                    Price = 20.00m,
                    CatalogTypeId = 3,
                    IsAvailable = true,
                    PreparationTimeMinutes = 4,
                    DisplayOrder = 3,
                    PictureFileName = "herbal-tea.webp"
                },
                new(new LocalizedText("Hot Lemon", "ليمون ساخن"),
                    new LocalizedText("Warm lemon drink, with optional honey", "ليمون سخن، ممكن بالعسل"))
                {
                    Price = 25.00m,
                    CatalogTypeId = 3,
                    IsAvailable = true,
                    PreparationTimeMinutes = 3,
                    DisplayOrder = 4,
                    PictureFileName = "hot-lemon.webp"
                },
                new(new LocalizedText("Hot Chocolate", "هوت شوكلت"),
                    new LocalizedText("Rich and creamy hot chocolate", "هوت شوكلت غنية وكريمية"))
                {
                    Price = 50.00m,
                    CatalogTypeId = 3,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    DisplayOrder = 5,
                    PictureFileName = "hot-chocolate.webp"
                },
                new(new LocalizedText("Hot Cider", "هوت سيدر"),
                    new LocalizedText("Warm apple cider to warm you up", "سيدر تفاح سخن يدفيك"))
                {
                    Price = 45.00m,
                    CatalogTypeId = 3,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    DisplayOrder = 6,
                    PictureFileName = "hot-cider.webp"
                },
                new(new LocalizedText("Sahlab", "سحلب"),
                    new LocalizedText("Traditional creamy sahlab with your choice of toppings", "سحلب تقليدي كريمي بالإضافات اللي تحبها"))
                {
                    Price = 40.00m,
                    CatalogTypeId = 3,
                    IsAvailable = true,
                    PreparationTimeMinutes = 7,
                    DisplayOrder = 7,
                    PictureFileName = "sahlab.webp"
                },
                new(new LocalizedText("Hummus Al-Sham", "حمص الشام"),
                    new LocalizedText("Traditional Egyptian warm chickpea drink", "حمص الشام المصري الأصيل"))
                {
                    Price = 40.00m,
                    CatalogTypeId = 3,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    DisplayOrder = 8,
                    PictureFileName = "hummus-sham.webp"
                },

                // ============== ICED DRINKS - مشروبات مثلجة (Category 4) ==============
                new(new LocalizedText("Iced Coffee", "آيس كوفي"),
                    new LocalizedText("Chilled coffee over ice, refreshing and energizing", "قهوة ساقعة بالتلج، منعشة ومنشطة"))
                {
                    Price = 60.00m,
                    CatalogTypeId = 4,
                    IsAvailable = true,
                    PreparationTimeMinutes = 4,
                    DisplayOrder = 1,
                    PictureFileName = "iced-latte.webp"
                },
                new(new LocalizedText("Frappuccino", "فرابتشينو"),
                    new LocalizedText("Blended iced coffee drink, smooth and delicious", "فرابتشينو مخفوق، ناعم ولذيذ"))
                {
                    Price = 80.00m,
                    CatalogTypeId = 4,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    DisplayOrder = 2,
                    PictureFileName = "frappuccino.webp"
                },
                new(new LocalizedText("Flat White", "فلات وايت"),
                    new LocalizedText("Iced flat white with velvety milk", "فلات وايت ساقع بحليب ناعم"))
                {
                    Price = 80.00m,
                    CatalogTypeId = 4,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    DisplayOrder = 3,
                    PictureFileName = "flat-white.webp"
                },
                new(new LocalizedText("Iced Chocolate", "ايس شوكلت"),
                    new LocalizedText("Cold chocolate drink over ice", "شوكولاتة ساقعة بالتلج"))
                {
                    Price = 60.00m,
                    CatalogTypeId = 4,
                    IsAvailable = true,
                    PreparationTimeMinutes = 4,
                    DisplayOrder = 4,
                    PictureFileName = "iced-chocolate.webp"
                },
                new(new LocalizedText("Milkshake", "ميلك شيك"),
                    new LocalizedText("Creamy milkshake in your favorite flavor", "ميلك شيك كريمي بنكهتك المفضلة"))
                {
                    Price = 50.00m,
                    CatalogTypeId = 4,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    DisplayOrder = 5,
                    PictureFileName = "milkshake.webp"
                },
                new(new LocalizedText("Oreo Milkshake", "ميلك شيك أوريو"),
                    new LocalizedText("Creamy milkshake with Oreo cookies", "ميلك شيك كريمي ببسكويت أوريو"))
                {
                    Price = 60.00m,
                    CatalogTypeId = 4,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    DisplayOrder = 6,
                    PictureFileName = "oreo-milkshake.webp"
                },
                new(new LocalizedText("Galaxy Milkshake", "ميلك جالاكسي"),
                    new LocalizedText("Rich Galaxy chocolate milkshake", "ميلك شيك شوكولاتة جالاكسي غني"))
                {
                    Price = 80.00m,
                    CatalogTypeId = 4,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    DisplayOrder = 7,
                    PictureFileName = "galaxy-milkshake.webp"
                },
                new(new LocalizedText("Oreo Shake", "اوريو"),
                    new LocalizedText("Oreo cookie blended shake", "شيك أوريو مخفوق"))
                {
                    Price = 60.00m,
                    CatalogTypeId = 4,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    DisplayOrder = 8,
                    PictureFileName = "oreo-shake.webp"
                },
                new(new LocalizedText("Burio Shake", "بوريو"),
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
                    new LocalizedText("Fresh yogurt drink - plain, honey, or fruit", "زبادي طازج - سادة، بالعسل، أو بالفواكه"))
                {
                    Price = 35.00m,
                    CatalogTypeId = 4,
                    IsAvailable = true,
                    PreparationTimeMinutes = 3,
                    DisplayOrder = 10,
                    PictureFileName = "yogurt.webp"
                },
                new(new LocalizedText("Brownies Shake", "براونيز"),
                    new LocalizedText("Chocolate brownies blended shake", "شيك براونيز شوكولاتة"))
                {
                    Price = 45.00m,
                    CatalogTypeId = 4,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    DisplayOrder = 11,
                    PictureFileName = "brownie.webp"
                },
                new(new LocalizedText("Ice Cream Scoop", "بولة ايس كريم"),
                    new LocalizedText("Premium ice cream scoop", "بولة آيس كريم فاخرة"))
                {
                    Price = 20.00m,
                    CatalogTypeId = 4,
                    IsAvailable = true,
                    PreparationTimeMinutes = 2,
                    DisplayOrder = 12,
                    PictureFileName = "ice-cream.webp"
                },
                new(new LocalizedText("Oreo Piece", "قطعه أوريو"),
                    new LocalizedText("Extra Oreo piece for your drink", "قطعة أوريو إضافية لمشروبك"))
                {
                    Price = 15.00m,
                    CatalogTypeId = 4,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    DisplayOrder = 13,
                    PictureFileName = "oreo-piece.webp"
                },

                // ============== JUICES - عصائر (Category 5) ==============
                new(new LocalizedText("Orange Juice", "برتقال"),
                    new LocalizedText("Freshly squeezed orange juice", "عصير برتقال طازج معصور"))
                {
                    Price = 20.00m,
                    CatalogTypeId = 5,
                    IsAvailable = true,
                    PreparationTimeMinutes = 4,
                    DisplayOrder = 1,
                    PictureFileName = "orange-juice.webp"
                },
                new(new LocalizedText("Mango Juice", "مانجو"),
                    new LocalizedText("Fresh mango juice, sweet and tropical", "عصير مانجو طازج، حلو ومنعش"))
                {
                    Price = 50.00m,
                    CatalogTypeId = 5,
                    IsAvailable = true,
                    PreparationTimeMinutes = 4,
                    DisplayOrder = 2,
                    PictureFileName = "mango-smoothie.webp"
                },
                new(new LocalizedText("Strawberry Juice", "فراولة"),
                    new LocalizedText("Fresh strawberry juice, plain or with milk", "عصير فراولة طازج، سادة أو بالحليب"))
                {
                    Price = 50.00m,
                    CatalogTypeId = 5,
                    IsAvailable = true,
                    PreparationTimeMinutes = 4,
                    DisplayOrder = 3,
                    PictureFileName = "strawberry-smoothie.webp"
                },
                new(new LocalizedText("Guava Juice", "جوافة"),
                    new LocalizedText("Fresh guava juice, plain or with milk", "عصير جوافة طازج، سادة أو بالحليب"))
                {
                    Price = 50.00m,
                    CatalogTypeId = 5,
                    IsAvailable = true,
                    PreparationTimeMinutes = 4,
                    DisplayOrder = 4,
                    PictureFileName = "guava-juice.webp"
                },
                new(new LocalizedText("Banana Juice", "موز"),
                    new LocalizedText("Creamy banana juice", "عصير موز كريمي"))
                {
                    Price = 35.00m,
                    CatalogTypeId = 5,
                    IsAvailable = true,
                    PreparationTimeMinutes = 4,
                    DisplayOrder = 5,
                    PictureFileName = "banana-juice.webp"
                },
                new(new LocalizedText("Kiwi Juice", "كيوي"),
                    new LocalizedText("Fresh kiwi juice, tangy and refreshing", "عصير كيوي طازج، منعش"))
                {
                    Price = 50.00m,
                    CatalogTypeId = 5,
                    IsAvailable = true,
                    PreparationTimeMinutes = 4,
                    DisplayOrder = 6,
                    PictureFileName = "kiwi-juice.webp"
                },
                new(new LocalizedText("Lemonade", "ليمون"),
                    new LocalizedText("Fresh lemonade, plain or with mint", "ليمونادة طازجة، سادة أو بالنعناع"))
                {
                    Price = 30.00m,
                    CatalogTypeId = 5,
                    IsAvailable = true,
                    PreparationTimeMinutes = 4,
                    DisplayOrder = 7,
                    PictureFileName = "lemonade.webp"
                },
                new(new LocalizedText("Watermelon Juice", "بطيخ"),
                    new LocalizedText("Refreshing watermelon juice", "عصير بطيخ منعش"))
                {
                    Price = 45.00m,
                    CatalogTypeId = 5,
                    IsAvailable = true,
                    PreparationTimeMinutes = 4,
                    DisplayOrder = 8,
                    PictureFileName = "watermelon-juice.webp"
                },
                new(new LocalizedText("Prickly Pear Juice", "تين شوكي"),
                    new LocalizedText("Fresh prickly pear cactus fruit juice", "عصير تين شوكي طازج"))
                {
                    Price = 45.00m,
                    CatalogTypeId = 5,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    DisplayOrder = 9,
                    PictureFileName = "prickly-pear-juice.webp"
                },
                new(new LocalizedText("Date Shake", "بلح"),
                    new LocalizedText("Sweet date shake, plain or with milk", "شيك بلح حلو، سادة أو بالحليب"))
                {
                    Price = 50.00m,
                    CatalogTypeId = 5,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    DisplayOrder = 10,
                    PictureFileName = "date-shake.webp"
                },
                new(new LocalizedText("Fruit Salad", "فروت سلاط"),
                    new LocalizedText("Mixed fresh fruit salad", "سلطة فواكه طازجة مشكلة"))
                {
                    Price = 40.00m,
                    CatalogTypeId = 5,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    DisplayOrder = 11,
                    PictureFileName = "fruit-salad.webp"
                },
                new(new LocalizedText("Cocktail Juice", "كوكتيل"),
                    new LocalizedText("Mixed fruit cocktail juice", "عصير كوكتيل فواكه مشكل"))
                {
                    Price = 60.00m,
                    CatalogTypeId = 5,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    DisplayOrder = 12,
                    PictureFileName = "cocktail-juice.webp"
                },
                new(new LocalizedText("Sunshine Juice", "صن شاين"),
                    new LocalizedText("Refreshing sunshine blend juice", "عصير صن شاين منعش"))
                {
                    Price = 50.00m,
                    CatalogTypeId = 5,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    DisplayOrder = 13,
                    PictureFileName = "sunshine-juice.webp"
                },
                new(new LocalizedText("Florida Juice", "فلوريدا"),
                    new LocalizedText("Florida-style citrus blend juice", "عصير فلوريدا حمضيات"))
                {
                    Price = 60.00m,
                    CatalogTypeId = 5,
                    IsAvailable = true,
                    PreparationTimeMinutes = 5,
                    DisplayOrder = 14,
                    PictureFileName = "florida-juice.webp"
                },
                new(new LocalizedText("Juice Extras", "إضافات"),
                    new LocalizedText("Extra additions for your juice", "إضافات لعصيرك"))
                {
                    Price = 10.00m,
                    CatalogTypeId = 5,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    DisplayOrder = 15,
                    PictureFileName = "juice-extras.webp"
                },

                // ============== SOFT DRINKS - مشروبات غازية (Category 6) ==============
                new(new LocalizedText("Soft Drink", "مشروب غازي"),
                    new LocalizedText("Chilled soft drink - Pepsi, 7Up, Mirinda, and more", "مشروب غازي ساقع - بيبسي، سفن، ميرندا، وغيرهم"))
                {
                    Price = 25.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    DisplayOrder = 1,
                    PictureFileName = "soft-drink.webp"
                },
                new(new LocalizedText("Mountain Dew", "Dew"),
                    new LocalizedText("Chilled Mountain Dew", "ماونتن ديو ساقع"))
                {
                    Price = 25.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    DisplayOrder = 2,
                    PictureFileName = "soft-drink.webp"
                },
                new(new LocalizedText("Twist", "Twist"),
                    new LocalizedText("Carbonated lemon drink", "تويست ليمون غازي"))
                {
                    Price = 25.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    DisplayOrder = 3,
                    PictureFileName = "soft-drink.webp"
                },
                new(new LocalizedText("V7", "V7"),
                    new LocalizedText("Vegetable juice blend", "عصير خضروات مشكل"))
                {
                    Price = 25.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    DisplayOrder = 4,
                    PictureFileName = "soft-drink.webp"
                },
                new(new LocalizedText("Mineral Water", "مياه معدنية"),
                    new LocalizedText("Bottled mineral water", "مياه معدنية معبأة"))
                {
                    Price = 8.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    DisplayOrder = 5,
                    PictureFileName = "mineral-water.webp"
                },
                new(new LocalizedText("Red Bull", "Red Bull"),
                    new LocalizedText("Red Bull energy drink", "ريد بول مشروب طاقة"))
                {
                    Price = 65.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    DisplayOrder = 6,
                    PictureFileName = "red-bull.webp"
                },
                new(new LocalizedText("Power Horse", "Power Horse"),
                    new LocalizedText("Power Horse energy drink", "باور هورس مشروب طاقة"))
                {
                    Price = 25.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    DisplayOrder = 7,
                    PictureFileName = "soft-drink.webp"
                },
                new(new LocalizedText("Buzz", "Buzz"),
                    new LocalizedText("Buzz energy drink", "بز مشروب طاقة"))
                {
                    Price = 20.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    DisplayOrder = 8,
                    PictureFileName = "soft-drink.webp"
                },
                new(new LocalizedText("Amstel Zero", "Amstel Zero"),
                    new LocalizedText("Non-alcoholic Amstel beer", "أمستل زيرو بدون كحول"))
                {
                    Price = 25.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    DisplayOrder = 9,
                    PictureFileName = "soft-drink.webp"
                },
                new(new LocalizedText("Barbican", "Barbican"),
                    new LocalizedText("Non-alcoholic malt beverage", "باربيكان شعير بدون كحول"))
                {
                    Price = 40.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    DisplayOrder = 10,
                    PictureFileName = "soft-drink.webp"
                },
                new(new LocalizedText("Moussy", "موسي"),
                    new LocalizedText("Non-alcoholic malt beverage", "موسي شعير بدون كحول"))
                {
                    Price = 30.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    DisplayOrder = 11,
                    PictureFileName = "soft-drink.webp"
                },
                new(new LocalizedText("FreeGo", "FreeGo"),
                    new LocalizedText("FreeGo soft drink", "فري جو مشروب غازي"))
                {
                    Price = 20.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    DisplayOrder = 12,
                    PictureFileName = "soft-drink.webp"
                },
                new(new LocalizedText("Snaps", "Snaps"),
                    new LocalizedText("Snaps carbonated drink", "سنابس مشروب غازي"))
                {
                    Price = 20.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    DisplayOrder = 13,
                    PictureFileName = "soft-drink.webp"
                },
                new(new LocalizedText("Spiro Spathis", "سبيرو سباتس"),
                    new LocalizedText("Classic Egyptian lemon soda", "سبيرو سباتس ليمون مصري كلاسيك"))
                {
                    Price = 20.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    DisplayOrder = 14,
                    PictureFileName = "soft-drink.webp"
                },
                new(new LocalizedText("Double Deer", "دبل دير"),
                    new LocalizedText("Double Deer carbonated drink", "دبل دير مشروب غازي"))
                {
                    Price = 20.00m,
                    CatalogTypeId = 6,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    DisplayOrder = 15,
                    PictureFileName = "soft-drink.webp"
                },

                // ============== SNACKS - مقرمشات (Category 7) ==============
                new(new LocalizedText("Chips", "مقرمشات"),
                    new LocalizedText("Assorted potato chips", "شيبسي متنوع"))
                {
                    Price = 15.00m,
                    CatalogTypeId = 7,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    DisplayOrder = 1,
                    PictureFileName = "chips.webp"
                },
                new(new LocalizedText("Peanuts", "سوداني"),
                    new LocalizedText("Roasted peanuts", "فول سوداني محمص"))
                {
                    Price = 20.00m,
                    CatalogTypeId = 7,
                    IsAvailable = true,
                    PreparationTimeMinutes = 1,
                    DisplayOrder = 2,
                    PictureFileName = "peanuts.webp"
                },

                // ============== DESSERTS - حلويات (Category 8) ==============
                new(new LocalizedText("Waffle", "وافل"),
                    new LocalizedText("Belgian waffle with your choice of toppings", "وافل بلجيكي بالإضافات اللي تحبها"))
                {
                    Price = 70.00m,
                    CatalogTypeId = 8,
                    IsAvailable = true,
                    PreparationTimeMinutes = 10,
                    DisplayOrder = 1,
                    PictureFileName = "waffles.webp"
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
                            new(new LocalizedText("Light Roast", "فاتح")) { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 1 },
                            new(new LocalizedText("Medium Roast", "وسط")) { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 2 },
                            new(new LocalizedText("Dark Roast", "غامق")) { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 3 }
                        }
                    },
                    new(new LocalizedText("Sugar Level", "السكر"))
                    {
                        CatalogItemId = turkishCoffee.Id,
                        IsRequired = false,
                        AllowMultiple = false,
                        DisplayOrder = 4,
                        Options = new List<CustomizationOption>
                        {
                            new(new LocalizedText("No Sugar", "سادة")) { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 1 },
                            new(new LocalizedText("Light Sugar", "ع الريحة")) { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 2 },
                            new(new LocalizedText("Medium Sugar", "مظبوط")) { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 3 },
                            new(new LocalizedText("Sweet", "زيادة")) { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 4 }
                        }
                    },
                    new(new LocalizedText("Cup Size", "الفنجان"))
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
                    new(new LocalizedText("Sugar Level", "السكر"))
                    {
                        CatalogItemId = coffee.Id,
                        IsRequired = false,
                        AllowMultiple = false,
                        DisplayOrder = 2,
                        Options = new List<CustomizationOption>
                        {
                            new(new LocalizedText("No Sugar", "من غير سكر")) { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 1 },
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
                            new(new LocalizedText("Black", "بلاك")) { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
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
                            new(new LocalizedText("Tea Bag", "باكيت")) { PriceAdjustment = 5.00m, IsDefault = true, DisplayOrder = 1 },
                            new(new LocalizedText("Lipton", "ليبتون")) { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 2 },
                            new(new LocalizedText("With Lemon", "ليمون")) { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 3 },
                            new(new LocalizedText("With Mint", "نعناع")) { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 4 },
                            new(new LocalizedText("With Milk", "حليب")) { PriceAdjustment = 10.00m, IsDefault = false, DisplayOrder = 5 }
                        }
                    },
                    new(new LocalizedText("Sugar Level", "السكر"))
                    {
                        CatalogItemId = tea.Id,
                        IsRequired = false,
                        AllowMultiple = false,
                        DisplayOrder = 2,
                        Options = new List<CustomizationOption>
                        {
                            new(new LocalizedText("No Sugar", "من غير سكر")) { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 1 },
                            new(new LocalizedText("Light Sugar", "سكر خفيف")) { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 2 },
                            new(new LocalizedText("Regular Sugar", "سكر عادي")) { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 3 },
                            new(new LocalizedText("Extra Sugar", "سكر زيادة")) { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 4 }
                        }
                    },
                    new(new LocalizedText("Cup Size", "الكوباية"))
                    {
                        CatalogItemId = tea.Id,
                        IsRequired = false,
                        AllowMultiple = false,
                        DisplayOrder = 3,
                        Options = new List<CustomizationOption>
                        {
                            new(new LocalizedText("Regular Cup", "كوباية عادية")) { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new(new LocalizedText("Large Cup", "كوباية كبيرة")) { PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 2 }
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
                            new(new LocalizedText("Anise", "ينسون")) { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 2 },
                            new(new LocalizedText("Hibiscus", "كركديه")) { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 3 },
                            new(new LocalizedText("Cinnamon", "قرفة")) { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 4 },
                            new(new LocalizedText("Cinnamon with Milk", "قرفة حليب")) { PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 5 },
                            new(new LocalizedText("Cinnamon Ginger", "قرفة جنزبيل")) { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 6 },
                            new(new LocalizedText("Cocktail Mix", "كوكتيل")) { PriceAdjustment = 10.00m, IsDefault = false, DisplayOrder = 7 }
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
                            new(new LocalizedText("With Chocolate", "شوكولاتة")) { PriceAdjustment = 10.00m, IsDefault = false, DisplayOrder = 2 },
                            new(new LocalizedText("With Nuts", "مكسرات")) { PriceAdjustment = 10.00m, IsDefault = false, DisplayOrder = 3 },
                            new(new LocalizedText("With Oreo", "اوريو")) { PriceAdjustment = 20.00m, IsDefault = false, DisplayOrder = 4 },
                            new(new LocalizedText("With Burio", "بوريو")) { PriceAdjustment = 20.00m, IsDefault = false, DisplayOrder = 5 },
                            new(new LocalizedText("With Fruits", "فواكه")) { PriceAdjustment = 25.00m, IsDefault = false, DisplayOrder = 6 }
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
                            new(new LocalizedText("With Honey", "عسل")) { PriceAdjustment = 10.00m, IsDefault = false, DisplayOrder = 2 }
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
                            new(new LocalizedText("Chocolate", "شيكولاته")) { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
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
                            new(new LocalizedText("With Chunks", "قطع")) { PriceAdjustment = 10.00m, IsDefault = false, DisplayOrder = 2 }
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
                            new(new LocalizedText("With Honey", "عسل")) { PriceAdjustment = 5.00m, IsDefault = false, DisplayOrder = 2 },
                            new(new LocalizedText("With Fruits", "فواكه")) { PriceAdjustment = 30.00m, IsDefault = false, DisplayOrder = 3 }
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
                            new(new LocalizedText("With Milk", "حليب")) { PriceAdjustment = 10.00m, IsDefault = false, DisplayOrder = 2 }
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
                            new(new LocalizedText("With Mint", "نعناع")) { PriceAdjustment = 10.00m, IsDefault = false, DisplayOrder = 2 }
                        }
                    }
                };
                await context.ItemCustomizations.AddRangeAsync(customizations);
            }

            // Add customizations for Soft Drinks
            var softDrink = await context.CatalogItems.FirstOrDefaultAsync(i => i.Name.En == "Soft Drink");
            if (softDrink != null)
            {
                var customizations = new List<ItemCustomization>
                {
                    new(new LocalizedText("Type", "النوع"))
                    {
                        CatalogItemId = softDrink.Id,
                        IsRequired = true,
                        AllowMultiple = false,
                        DisplayOrder = 1,
                        Options = new List<CustomizationOption>
                        {
                            new(new LocalizedText("Pepsi", "بيبسي")) { PriceAdjustment = 0, IsDefault = true, DisplayOrder = 1 },
                            new(new LocalizedText("7Up", "سفن اب")) { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 2 },
                            new(new LocalizedText("Mirinda", "ميرندا")) { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 3 },
                            new(new LocalizedText("Schweppes Lemon", "شويبس ليمون")) { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 4 },
                            new(new LocalizedText("Schweppes Pomegranate", "شويبس رمان")) { PriceAdjustment = -5.00m, IsDefault = false, DisplayOrder = 5 },
                            new(new LocalizedText("Schweppes Gold", "شويبس جولد")) { PriceAdjustment = -5.00m, IsDefault = false, DisplayOrder = 6 },
                            new(new LocalizedText("Schweppes Tangerine", "شويبس يوسفي")) { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 7 },
                            new(new LocalizedText("Birell", "بيريل")) { PriceAdjustment = 0, IsDefault = false, DisplayOrder = 8 }
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
