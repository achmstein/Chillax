using Chillax.Rooms.Domain.Exceptions;
using Chillax.Rooms.Domain.SeedWork;

namespace Chillax.Rooms.Domain.AggregatesModel.RoomAggregate;

/// <summary>
/// Room aggregate root - manages physical room state
/// Availability is computed at query time by checking both physical status and reservation conflicts
/// </summary>
public class Room : Entity, IAggregateRoot
{
    public string Name { get; private set; }
    public string? Description { get; private set; }
    public decimal HourlyRate { get; private set; }

    /// <summary>
    /// Physical status of the room (not reservation status)
    /// </summary>
    public RoomPhysicalStatus PhysicalStatus { get; private set; }

    protected Room()
    {
        Name = string.Empty;
    }

    public Room(string name, decimal hourlyRate, string? description = null) : this()
    {
        if (string.IsNullOrWhiteSpace(name))
            throw new RoomsDomainException("Room name is required");

        if (hourlyRate <= 0)
            throw new RoomsDomainException("Hourly rate must be greater than zero");

        Name = name;
        HourlyRate = hourlyRate;
        Description = description;
        PhysicalStatus = RoomPhysicalStatus.Available;
    }

    /// <summary>
    /// Update room details
    /// </summary>
    public void UpdateDetails(string name, string? description, decimal hourlyRate)
    {
        if (string.IsNullOrWhiteSpace(name))
            throw new RoomsDomainException("Room name is required");

        if (hourlyRate <= 0)
            throw new RoomsDomainException("Hourly rate must be greater than zero");

        Name = name;
        Description = description;
        HourlyRate = hourlyRate;
    }

    /// <summary>
    /// Mark room as occupied (when session starts)
    /// </summary>
    public void SetOccupied()
    {
        if (PhysicalStatus == RoomPhysicalStatus.Maintenance)
            throw new RoomsDomainException("Cannot occupy a room under maintenance");

        PhysicalStatus = RoomPhysicalStatus.Occupied;
    }

    /// <summary>
    /// Mark room as available (when session ends)
    /// </summary>
    public void SetAvailable()
    {
        PhysicalStatus = RoomPhysicalStatus.Available;
    }

    /// <summary>
    /// Mark room as under maintenance
    /// </summary>
    public void SetMaintenance()
    {
        if (PhysicalStatus == RoomPhysicalStatus.Occupied)
            throw new RoomsDomainException("Cannot set maintenance on an occupied room. End the session first.");

        PhysicalStatus = RoomPhysicalStatus.Maintenance;
    }

    /// <summary>
    /// Check if room is physically available (not checking reservations)
    /// For full availability check including reservations, use the query service
    /// </summary>
    public bool IsPhysicallyAvailable()
    {
        return PhysicalStatus == RoomPhysicalStatus.Available;
    }
}
