using Chillax.Rooms.Domain.AggregatesModel.ReservationAggregate;

namespace Chillax.Rooms.API.Application.Queries;

/// <summary>
/// Computed display status for UI
/// </summary>
public enum RoomDisplayStatus
{
    Available = 1,      // Can book now
    Occupied = 2,       // Someone is playing
    Reserved = 3,       // Waiting for customer to arrive (15 min window)
    Maintenance = 4     // Out of service
}

public record RoomViewModel
{
    public int Id { get; init; }
    public string Name { get; init; } = string.Empty;
    public string? Description { get; init; }
    public decimal HourlyRate { get; init; }
    public RoomDisplayStatus DisplayStatus { get; init; }
}

public record ReservationViewModel
{
    public int Id { get; init; }
    public int RoomId { get; init; }
    public string RoomName { get; init; } = string.Empty;
    public decimal HourlyRate { get; init; }
    /// <summary>
    /// Customer ID - null for walk-in sessions without assigned customer
    /// </summary>
    public string? CustomerId { get; init; }
    public string? CustomerName { get; init; }
    public DateTime CreatedAt { get; init; }
    public DateTime? ActualStartTime { get; init; }
    public DateTime? EndTime { get; init; }
    public decimal? TotalCost { get; init; }
    public ReservationStatus Status { get; init; }
    public string? Notes { get; init; }
    /// <summary>
    /// 6-digit access code for joining the session
    /// </summary>
    public string? AccessCode { get; init; }
    /// <summary>
    /// When this reservation expires if not started (only for Reserved status)
    /// </summary>
    public DateTime? ExpiresAt { get; init; }
}

/// <summary>
/// Preview information for a session before joining
/// </summary>
public record SessionPreviewViewModel
{
    public int SessionId { get; init; }
    public int RoomId { get; init; }
    public string RoomName { get; init; } = string.Empty;
    public DateTime StartTime { get; init; }
    public int MemberCount { get; init; }
}
