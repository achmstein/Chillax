using System.ComponentModel.DataAnnotations;
using Chillax.Rooms.Domain.SeedWork;

namespace Chillax.Rooms.API.Model;

/// <summary>
/// Represents a PlayStation room available for reservation
/// </summary>
public class Room
{
    public int Id { get; set; }

    /// <summary>
    /// Localized name of the room (e.g., "PlayStation Room 1", "Party Room A")
    /// </summary>
    [Required]
    public LocalizedText Name { get; set; } = new();

    /// <summary>
    /// Localized description of the room and its features
    /// </summary>
    public LocalizedText? Description { get; set; }

    /// <summary>
    /// Current status of the room
    /// </summary>
    public RoomStatus Status { get; set; } = RoomStatus.Available;

    /// <summary>
    /// Hourly rate for the room
    /// </summary>
    public decimal HourlyRate { get; set; }

    /// <summary>
    /// Picture of the room
    /// </summary>
    public string? PictureFileName { get; set; }

    /// <summary>
    /// All sessions (past and present) for this room
    /// </summary>
    public ICollection<RoomSession> Sessions { get; set; } = new List<RoomSession>();

    protected Room() { }

    public Room(LocalizedText name)
    {
        Name = name;
    }

    public Room(string name, string? nameAr = null)
    {
        Name = new LocalizedText(name, nameAr);
    }
}

public enum RoomStatus
{
    Available = 1,
    Occupied = 2,
    Reserved = 3,
    Maintenance = 4
}
