using System.ComponentModel.DataAnnotations;

namespace Chillax.Rooms.API.Model;

/// <summary>
/// Represents a reservation/session for a PlayStation room
/// </summary>
public class RoomSession
{
    public int Id { get; set; }

    public int RoomId { get; set; }

    public Room? Room { get; set; }

    /// <summary>
    /// Customer ID from Identity service
    /// </summary>
    [Required]
    public string CustomerId { get; set; }

    /// <summary>
    /// Customer name for display
    /// </summary>
    public string? CustomerName { get; set; }

    /// <summary>
    /// When the reservation was made
    /// </summary>
    public DateTime ReservationTime { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// When the session actually started (admin clicks start)
    /// </summary>
    public DateTime? StartTime { get; set; }

    /// <summary>
    /// When the session ended (admin clicks end)
    /// </summary>
    public DateTime? EndTime { get; set; }

    /// <summary>
    /// Total cost calculated when session ends
    /// </summary>
    public decimal? TotalCost { get; set; }

    /// <summary>
    /// Current status of the session
    /// </summary>
    public SessionStatus Status { get; set; } = SessionStatus.Reserved;

    /// <summary>
    /// Optional notes about the session
    /// </summary>
    public string? Notes { get; set; }

    public RoomSession(string customerId)
    {
        CustomerId = customerId;
    }

    /// <summary>
    /// Start the session (called by admin)
    /// </summary>
    public void StartSession()
    {
        if (Status != SessionStatus.Reserved)
        {
            throw new InvalidOperationException("Can only start a reserved session");
        }

        StartTime = DateTime.UtcNow;
        Status = SessionStatus.Active;
    }

    /// <summary>
    /// End the session and calculate cost (called by admin)
    /// </summary>
    public void EndSession(decimal hourlyRate)
    {
        if (Status != SessionStatus.Active)
        {
            throw new InvalidOperationException("Can only end an active session");
        }

        EndTime = DateTime.UtcNow;
        TotalCost = CalculateCost(hourlyRate);
        Status = SessionStatus.Completed;
    }

    /// <summary>
    /// Cancel the session
    /// </summary>
    public void CancelSession()
    {
        if (Status == SessionStatus.Completed)
        {
            throw new InvalidOperationException("Cannot cancel a completed session");
        }

        Status = SessionStatus.Cancelled;
    }

    /// <summary>
    /// Calculate cost based on duration and hourly rate
    /// Rounds up to nearest 30 minutes
    /// </summary>
    private decimal CalculateCost(decimal hourlyRate)
    {
        if (StartTime == null || EndTime == null)
        {
            return 0;
        }

        var duration = EndTime.Value - StartTime.Value;
        var totalMinutes = duration.TotalMinutes;

        // Round up to nearest 30 minutes
        var halfHours = Math.Ceiling(totalMinutes / 30);
        var hours = (decimal)halfHours / 2;

        return hours * hourlyRate;
    }

    /// <summary>
    /// Get current duration if session is active
    /// </summary>
    public TimeSpan? GetCurrentDuration()
    {
        if (Status != SessionStatus.Active || StartTime == null)
        {
            return null;
        }

        return DateTime.UtcNow - StartTime.Value;
    }
}

public enum SessionStatus
{
    Reserved = 1,
    Active = 2,
    Completed = 3,
    Cancelled = 4
}
