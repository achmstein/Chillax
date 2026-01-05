using System.ComponentModel.DataAnnotations;

namespace Chillax.Rooms.API.Model;

/// <summary>
/// Represents a PlayStation room available for reservation
/// </summary>
public class Room
{
    public int Id { get; set; }

    /// <summary>
    /// Name of the room (e.g., "PlayStation Room 1", "Party Room A")
    /// </summary>
    [Required]
    public string Name { get; set; }

    /// <summary>
    /// Description of the room and its features
    /// </summary>
    public string? Description { get; set; }

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

    public Room(string name)
    {
        Name = name;
    }
}

public enum RoomStatus
{
    Available = 1,
    Occupied = 2,
    Reserved = 3,
    Maintenance = 4
}
