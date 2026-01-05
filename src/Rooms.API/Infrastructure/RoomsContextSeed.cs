using Chillax.Rooms.API.Model;

namespace Chillax.Rooms.API.Infrastructure;

public class RoomsContextSeed(ILogger<RoomsContextSeed> logger) : IDbSeeder<RoomsContext>
{
    public async Task SeedAsync(RoomsContext context)
    {
        if (!context.Rooms.Any())
        {
            var rooms = new List<Room>
            {
                new("PlayStation Room 1")
                {
                    Description = "PS5 with 2 controllers and 55\" TV",
                    HourlyRate = 50.00m,
                    Status = RoomStatus.Available
                },
                new("PlayStation Room 2")
                {
                    Description = "PS5 with 2 controllers and 55\" TV",
                    HourlyRate = 50.00m,
                    Status = RoomStatus.Available
                },
                new("PlayStation Room 3")
                {
                    Description = "PS5 with 4 controllers and 65\" TV - Great for groups",
                    HourlyRate = 60.00m,
                    Status = RoomStatus.Available
                },
                new("PlayStation Room 4")
                {
                    Description = "PS5 Pro with VR headset and 65\" TV",
                    HourlyRate = 70.00m,
                    Status = RoomStatus.Available
                },
                new("PlayStation Room 5")
                {
                    Description = "PS5 Pro with VR headset and 65\" TV",
                    HourlyRate = 70.00m,
                    Status = RoomStatus.Available
                },
                new("Party Room 1")
                {
                    Description = "Large room with 2 PS5 consoles, perfect for parties - Fits up to 10 people",
                    HourlyRate = 100.00m,
                    Status = RoomStatus.Available
                },
                new("Party Room 2")
                {
                    Description = "Premium party room with 2 PS5 Pro consoles, VR, and premium sound system - Fits up to 12 people",
                    HourlyRate = 120.00m,
                    Status = RoomStatus.Available
                }
            };

            context.Rooms.AddRange(rooms);
            await context.SaveChangesAsync();
            logger.LogInformation("Seeded {NumRooms} rooms", rooms.Count);
        }
    }
}
