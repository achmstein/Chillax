using Chillax.Rooms.Domain.AggregatesModel.RoomAggregate;
using Microsoft.Extensions.Logging;

namespace Chillax.Rooms.Infrastructure;

public class RoomsContextSeed(ILogger<RoomsContextSeed> logger) : IDbSeeder<RoomsContext>
{
    public async Task SeedAsync(RoomsContext context)
    {
        if (!context.Rooms.Any())
        {
            var rooms = new List<Room>
            {
                new("Room 1", 50.00m, "PS5 with 2 controllers and 55\" TV"),
                new("Room 2", 50.00m, "PS5 with 2 controllers and 55\" TV"),
                new("Room 3", 50.00m, "PS5 with 2 controllers and 55\" TV"),
                new("Room 4", 60.00m, "PS5 with 4 controllers and 65\" TV - Great for groups"),
                new("Room 5", 70.00m, "PS5 Pro with VR headset and 65\" TV"),
                new("Room 6", 70.00m, "PS5 Pro with VR headset and 65\" TV"),
                new("Room VIP", 150.00m, "Premium VIP room with 2 PS5 Pro consoles, VR headsets, 75\" OLED TV, premium sound system, and private lounge area - Fits up to 10 people")
            };

            context.Rooms.AddRange(rooms);
            await context.SaveChangesAsync();
            logger.LogInformation("Seeded {NumRooms} rooms", rooms.Count);
        }
    }
}
