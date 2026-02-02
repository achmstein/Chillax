using Chillax.Rooms.API.Model;
using Chillax.Rooms.Domain.SeedWork;

namespace Chillax.Rooms.API.Dtos;

/// <summary>
/// DTO for room
/// </summary>
public record RoomDto
{
    public int Id { get; init; }
    public LocalizedText Name { get; init; } = new();
    public LocalizedText? Description { get; init; }
    public RoomStatus Status { get; init; }
    public decimal HourlyRate { get; init; }
    public string? PictureFileName { get; init; }
}

/// <summary>
/// DTO for room session
/// </summary>
public record RoomSessionDto
{
    public int Id { get; init; }
    public int RoomId { get; init; }
    public LocalizedText? RoomName { get; init; }
    public decimal HourlyRate { get; init; }
    public string CustomerId { get; init; } = string.Empty;
    public string? CustomerName { get; init; }
    public DateTime ReservationTime { get; init; }
    public DateTime? StartTime { get; init; }
    public DateTime? EndTime { get; init; }
    public decimal? TotalCost { get; init; }
    public SessionStatus Status { get; init; }
    public string? Notes { get; init; }
}
