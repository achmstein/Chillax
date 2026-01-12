# Download menu images from Unsplash (free to use)
# Run this script from the Pics folder: .\download-images.ps1

$images = @{
    # Drinks - Hot Coffee
    "espresso.webp" = "https://images.unsplash.com/photo-1510707577719-ae7c14805e3a?w=400&q=80"
    "cappuccino.webp" = "https://images.unsplash.com/photo-1572442388796-11668a67e53d?w=400&q=80"
    "latte.webp" = "https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=400&q=80"
    "mocha.webp" = "https://images.unsplash.com/photo-1578314675249-a6910f80cc4e?w=400&q=80"
    "americano.webp" = "https://images.unsplash.com/photo-1521302080334-4bebac2763a6?w=400&q=80"
    "flat-white.webp" = "https://images.unsplash.com/photo-1577968897966-3d4325b36b61?w=400&q=80"

    # Drinks - Cold
    "iced-latte.webp" = "https://images.unsplash.com/photo-1517701550927-30cf4ba1dba5?w=400&q=80"
    "orange-juice.webp" = "https://images.unsplash.com/photo-1621506289937-a8e4df240d0b?w=400&q=80"
    "mango-smoothie.webp" = "https://images.unsplash.com/photo-1623065422902-30a2d299bbe4?w=400&q=80"
    "strawberry-smoothie.webp" = "https://images.unsplash.com/photo-1553530666-ba11a7da3888?w=400&q=80"
    "milkshake.webp" = "https://images.unsplash.com/photo-1572490122747-3968b75cc699?w=400&q=80"
    "soft-drink.webp" = "https://images.unsplash.com/photo-1581006852262-e4307cf6283a?w=400&q=80"

    # Food - Main Dishes
    "club-sandwich.webp" = "https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=400&q=80"
    "chicken-burger.webp" = "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400&q=80"
    "beef-burger.webp" = "https://images.unsplash.com/photo-1550547660-d9450f859349?w=400&q=80"
    "pasta-alfredo.webp" = "https://images.unsplash.com/photo-1645112411341-6c4fd023714a?w=400&q=80"
    "margherita-pizza.webp" = "https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=400&q=80"
    "pepperoni-pizza.webp" = "https://images.unsplash.com/photo-1628840042765-356cda07504e?w=400&q=80"
    "caesar-salad.webp" = "https://images.unsplash.com/photo-1550304943-4f24f54ddde9?w=400&q=80"

    # Snacks
    "french-fries.webp" = "https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=400&q=80"
    "chicken-wings.webp" = "https://images.unsplash.com/photo-1608039755401-742074f0548d?w=400&q=80"
    "nachos.webp" = "https://images.unsplash.com/photo-1513456852971-30c0b8199d4d?w=400&q=80"
    "mozzarella-sticks.webp" = "https://images.unsplash.com/photo-1531749668029-2db88e4276c7?w=400&q=80"
    "onion-rings.webp" = "https://images.unsplash.com/photo-1639024471283-03518883512d?w=400&q=80"
    "chicken-nuggets.webp" = "https://images.unsplash.com/photo-1562967914-608f82629710?w=400&q=80"

    # Desserts
    "chocolate-cake.webp" = "https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=400&q=80"
    "cheesecake.webp" = "https://images.unsplash.com/photo-1533134242443-d4fd215305ad?w=400&q=80"
    "ice-cream.webp" = "https://images.unsplash.com/photo-1497034825429-c343d7c6a68f?w=400&q=80"
    "brownie.webp" = "https://images.unsplash.com/photo-1564355808539-22fda35bed7e?w=400&q=80"
    "waffles.webp" = "https://images.unsplash.com/photo-1562376552-0d160a2f238d?w=400&q=80"
    "pancakes.webp" = "https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=400&q=80"
}

Write-Host "Downloading menu images..." -ForegroundColor Cyan

foreach ($image in $images.GetEnumerator()) {
    $filename = $image.Key
    $url = $image.Value

    Write-Host "Downloading $filename..." -NoNewline

    try {
        # Download as jpg first (Unsplash returns jpg)
        $tempFile = [System.IO.Path]::GetTempFileName()
        Invoke-WebRequest -Uri $url -OutFile $tempFile -UseBasicParsing

        # Move to final location (keeping as webp extension but it's actually jpg - browsers handle this)
        Move-Item -Path $tempFile -Destination $filename -Force

        Write-Host " Done!" -ForegroundColor Green
    }
    catch {
        Write-Host " Failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nAll images downloaded!" -ForegroundColor Cyan
Write-Host "Note: Images are from Unsplash and are free to use." -ForegroundColor Yellow
