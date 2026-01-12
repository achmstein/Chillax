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
                new("Room 1")
                {
                    Description = "PS5 with 2 controllers and 55\" TV",
                    HourlyRate = 50.00m,
                    Status = RoomStatus.Available,
                    PictureFileName = "room-1.webp"
                },
                new("Room 2")
                {
                    Description = "PS5 with 2 controllers and 55\" TV",
                    HourlyRate = 50.00m,
                    Status = RoomStatus.Available,
                    PictureFileName = "room-2.webp"
                },
                new("Room 3")
                {
                    Description = "PS5 with 2 controllers and 55\" TV",
                    HourlyRate = 50.00m,
                    Status = RoomStatus.Available,
                    PictureFileName = "room-3.webp"
                },
                new("Room 4")
                {
                    Description = "PS5 with 4 controllers and 65\" TV - Great for groups",
                    HourlyRate = 60.00m,
                    Status = RoomStatus.Available,
                    PictureFileName = "room-4.webp"
                },
                new("Room 5")
                {
                    Description = "PS5 Pro with VR headset and 65\" TV",
                    HourlyRate = 70.00m,
                    Status = RoomStatus.Available,
                    PictureFileName = "room-5.webp"
                },
                new("Room 6")
                {
                    Description = "PS5 Pro with VR headset and 65\" TV",
                    HourlyRate = 70.00m,
                    Status = RoomStatus.Available,
                    PictureFileName = "room-6.webp"
                },
                new("Room VIP")
                {
                    Description = "Premium VIP room with 2 PS5 Pro consoles, VR headsets, 75\" OLED TV, premium sound system, and private lounge area - Fits up to 10 people",
                    HourlyRate = 150.00m,
                    Status = RoomStatus.Available,
                    PictureFileName = "room-vip.webp"
                }
            };

            context.Rooms.AddRange(rooms);
            await context.SaveChangesAsync();
            logger.LogInformation("Seeded {NumRooms} rooms", rooms.Count);
        }
    }
}
