using Chillax.Rooms.Domain.AggregatesModel.ReservationAggregate;

namespace Chillax.Rooms.API.Application.Queries;

/// <summary>
/// Computed display status for UI
/// </summary>
public enum RoomDisplayStatus
{
    Available = 1,      // Can book now
    Occupied = 2,       // Someone is playing
    ReservedSoon = 3,   // Reservation within 15 mins
    Maintenance = 4     // Out of service
}

public record RoomViewModel
{
    public int Id { get; init; }
    public string Name { get; init; } = string.Empty;
    public string? Description { get; init; }
    public decimal HourlyRate { get; init; }
    public RoomDisplayStatus DisplayStatus { get; init; }
    public DateTime? NextReservationTime { get; init; }
}

public record ReservationViewModel
{
    public int Id { get; init; }
    public int RoomId { get; init; }
    public string RoomName { get; init; } = string.Empty;
    public decimal HourlyRate { get; init; }
    public string CustomerId { get; init; } = string.Empty;
    public string? CustomerName { get; init; }
    public DateTime CreatedAt { get; init; }
    public DateTime ScheduledStartTime { get; init; }
    public DateTime? ActualStartTime { get; init; }
    public DateTime? EndTime { get; init; }
    public decimal? TotalCost { get; init; }
    public ReservationStatus Status { get; init; }
    public string? Notes { get; init; }
}
