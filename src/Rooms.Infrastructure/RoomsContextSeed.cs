using Chillax.Rooms.Domain.AggregatesModel.RoomAggregate;
using Microsoft.Extensions.Logging;

namespace Chillax.Rooms.Infrastructure;

public class RoomsContextSeed(ILogger<RoomsContextSeed> logger)
{
    public async Task SeedAsync(RoomsContext context)
    {
        if (!context.Rooms.Any())
        {
            var rooms = new List<Room>
            {
                new("Room 1", 50.00m, "PS5 with 2 controllers and 55\" TV", "اوضة ١", "بلايستيشن 5 مع 2 دراعات وشاشة 55 بوصة"),
                new("Room 2", 50.00m, "PS5 with 2 controllers and 55\" TV", "اوضة ٢", "بلايستيشن 5 مع 2 دراعات وشاشة 55 بوصة"),
                new("Room 3", 50.00m, "PS5 with 2 controllers and 55\" TV", "اوضة ٣", "بلايستيشن 5 مع 2 دراعات وشاشة 55 بوصة"),
                new("Room 4", 60.00m, "PS5 with 4 controllers and 65\" TV - Great for groups", "اوضة ٤", "بلايستيشن 5 مع 4 دراعات وشاشة 65 بوصة - مناسبة للمجموعات"),
                new("Room 5", 70.00m, "PS5 Pro with VR headset and 65\" TV", "اوضة ٥", "بلايستيشن 5 برو مع نظارة VR وشاشة 65 بوصة"),
                new("Room 6", 70.00m, "PS5 Pro with VR headset and 65\" TV", "اوضة ٦", "بلايستيشن 5 برو مع نظارة VR وشاشة 65 بوصة"),
                new("Room VIP", 150.00m, "Premium VIP room with 2 PS5 Pro consoles, VR headsets, 75\" OLED TV, premium sound system, and private lounge area - Fits up to 10 people", "اوضة VIP", "اوضة VIP مميزة مع 2 بلايستيشن 5 برو، نظارات VR، شاشة OLED 75 بوصة، نظام صوت مميز، ومنطقة جلوس خاصة - تتسع حتى 10 أشخاص")
            };

            context.Rooms.AddRange(rooms);
            await context.SaveChangesAsync();
            logger.LogInformation("Seeded {NumRooms} rooms", rooms.Count);
        }
    }
}
