# Download menu item images from Unsplash
# Run this script from the Pics directory

$images = @{
    # Coffee (Category 1)
    "turkish-coffee.webp" = "https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=400&q=80"
    "hazelnut-coffee.webp" = "https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=400&q=80"
    "french-coffee.webp" = "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=400&q=80"
    "caramel-coffee.webp" = "https://images.unsplash.com/photo-1485808191679-5f86510681a2?w=400&q=80"
    "cappuccino.webp" = "https://images.unsplash.com/photo-1572442388796-11668a67e53d?w=400&q=80"
    "latte.webp" = "https://images.unsplash.com/photo-1570968915860-54d5c301fa9f?w=400&q=80"
    "macchiato.webp" = "https://images.unsplash.com/photo-1485808191679-5f86510681a2?w=400&q=80"
    "nescafe.webp" = "https://images.unsplash.com/photo-1517701550927-30cf4ba1dba5?w=400&q=80"
    "americano.webp" = "https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=400&q=80"

    # Espresso (Category 2)
    "espresso.webp" = "https://images.unsplash.com/photo-1510707577719-ae7c14805e3a?w=400&q=80"
    "mocha.webp" = "https://images.unsplash.com/photo-1578314675249-a6910f80cc4e?w=400&q=80"
    "iced-mocha.webp" = "https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=400&q=80"

    # Hot Drinks (Category 3)
    "tea.webp" = "https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=400&q=80"
    "green-tea.webp" = "https://images.unsplash.com/photo-1627435601361-ec25f5b1d0e5?w=400&q=80"
    "herbal-tea.webp" = "https://images.unsplash.com/photo-1597481499750-3e6b22637e12?w=400&q=80"
    "hot-lemon.webp" = "https://images.unsplash.com/photo-1582793988951-9aed5509eb97?w=400&q=80"
    "hot-chocolate.webp" = "https://images.unsplash.com/photo-1542990253-0d0f5be5f0ed?w=400&q=80"
    "hot-cider.webp" = "https://images.unsplash.com/photo-1606851094655-b3b5e4c00b0f?w=400&q=80"
    "sahlab.webp" = "https://images.unsplash.com/photo-1544787219-7f47ccb76574?w=400&q=80"
    "hummus-sham.webp" = "https://images.unsplash.com/photo-1476718406336-bb5a9690ee2a?w=400&q=80"

    # Iced Drinks (Category 4)
    "iced-latte.webp" = "https://images.unsplash.com/photo-1517701550927-30cf4ba1dba5?w=400&q=80"
    "frappuccino.webp" = "https://images.unsplash.com/photo-1572490122747-3968b75cc699?w=400&q=80"
    "flat-white.webp" = "https://images.unsplash.com/photo-1577968897966-3d4325b36b61?w=400&q=80"
    "iced-chocolate.webp" = "https://images.unsplash.com/photo-1563805042-7684c019e1cb?w=400&q=80"
    "milkshake.webp" = "https://images.unsplash.com/photo-1579954115545-a95591f28bfc?w=400&q=80"
    "oreo-milkshake.webp" = "https://images.unsplash.com/photo-1568901839119-631418a3910d?w=400&q=80"
    "galaxy-milkshake.webp" = "https://images.unsplash.com/photo-1572490122747-3968b75cc699?w=400&q=80"
    "oreo-shake.webp" = "https://images.unsplash.com/photo-1568901839119-631418a3910d?w=400&q=80"
    "burio-shake.webp" = "https://images.unsplash.com/photo-1579954115545-a95591f28bfc?w=400&q=80"
    "yogurt.webp" = "https://images.unsplash.com/photo-1488477181946-6428a0291777?w=400&q=80"
    "brownie.webp" = "https://images.unsplash.com/photo-1564355808539-22fda35bed7e?w=400&q=80"
    "ice-cream.webp" = "https://images.unsplash.com/photo-1497034825429-c343d7c6a68f?w=400&q=80"

    # Juices (Category 5)
    "orange-juice.webp" = "https://images.unsplash.com/photo-1621506289937-a8e4df240d0b?w=400&q=80"
    "mango-smoothie.webp" = "https://images.unsplash.com/photo-1546173159-315724a31696?w=400&q=80"
    "strawberry-smoothie.webp" = "https://images.unsplash.com/photo-1553530666-ba11a7da3888?w=400&q=80"
    "guava-juice.webp" = "https://images.unsplash.com/photo-1600271886742-f049cd451bba?w=400&q=80"
    "banana-juice.webp" = "https://images.unsplash.com/photo-1553530666-ba11a7da3888?w=400&q=80"
    "kiwi-juice.webp" = "https://images.unsplash.com/photo-1638176066666-ffb2f013c7dd?w=400&q=80"
    "lemonade.webp" = "https://images.unsplash.com/photo-1621263764928-df1444c5e859?w=400&q=80"
    "watermelon-juice.webp" = "https://images.unsplash.com/photo-1534353473418-4cfa6c56fd38?w=400&q=80"
    "prickly-pear-juice.webp" = "https://images.unsplash.com/photo-1600271886742-f049cd451bba?w=400&q=80"
    "date-shake.webp" = "https://images.unsplash.com/photo-1553530666-ba11a7da3888?w=400&q=80"
    "fruit-salad.webp" = "https://images.unsplash.com/photo-1564093497595-593b96d80180?w=400&q=80"
    "cocktail-juice.webp" = "https://images.unsplash.com/photo-1546171753-97d7676e4602?w=400&q=80"
    "sunshine-juice.webp" = "https://images.unsplash.com/photo-1622597467836-f3285f2131b8?w=400&q=80"
    "florida-juice.webp" = "https://images.unsplash.com/photo-1621506289937-a8e4df240d0b?w=400&q=80"

    # Soft Drinks (Category 6)
    "soft-drink.webp" = "https://images.unsplash.com/photo-1581636625402-29b2a704ef13?w=400&q=80"
    "mineral-water.webp" = "https://images.unsplash.com/photo-1548839140-29a749e1cf4d?w=400&q=80"
    "red-bull.webp" = "https://images.unsplash.com/photo-1527960471264-932f39eb5846?w=400&q=80"

    # Snacks (Category 7)
    "chips.webp" = "https://images.unsplash.com/photo-1566478989037-eec170784d0b?w=400&q=80"
    "peanuts.webp" = "https://images.unsplash.com/photo-1567892320421-1c657571ea4a?w=400&q=80"

    # Desserts (Category 8)
    "waffles.webp" = "https://images.unsplash.com/photo-1562376552-0d160a2f238d?w=400&q=80"
    "oreo-piece.webp" = "https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=400&q=80"
}

Write-Host "Downloading menu item images..." -ForegroundColor Cyan
Write-Host ""

$total = $images.Count
$current = 0

foreach ($item in $images.GetEnumerator()) {
    $current++
    $filename = $item.Key
    $url = $item.Value

    Write-Host "[$current/$total] Downloading $filename..." -NoNewline

    try {
        # Download as jpg first (Unsplash returns jpg)
        $tempFile = [System.IO.Path]::GetTempFileName()
        Invoke-WebRequest -Uri $url -OutFile $tempFile -TimeoutSec 30

        # Copy to destination (keeping webp extension for compatibility)
        Copy-Item -Path $tempFile -Destination $filename -Force
        Remove-Item -Path $tempFile -Force

        Write-Host " Done" -ForegroundColor Green
    }
    catch {
        Write-Host " Failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Download complete!" -ForegroundColor Green
Write-Host "Note: Images are downloaded as JPEG but saved with .webp extension for compatibility." -ForegroundColor Yellow
Write-Host "For production, consider converting to actual WebP format." -ForegroundColor Yellow
