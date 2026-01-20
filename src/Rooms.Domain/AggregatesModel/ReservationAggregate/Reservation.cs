using Chillax.Rooms.Domain.AggregatesModel.RoomAggregate;
using Chillax.Rooms.Domain.Events;
using Chillax.Rooms.Domain.Exceptions;
using Chillax.Rooms.Domain.SeedWork;

namespace Chillax.Rooms.Domain.AggregatesModel.ReservationAggregate;

/// <summary>
/// Reservation aggregate - handles both reservations and active sessions
/// This is the primary aggregate for customer interactions
/// </summary>
public class Reservation : Entity, IAggregateRoot
{
    /// <summary>
    /// Default buffer in minutes for determining if a reservation is imminent
    /// </summary>
    public const int DefaultImminentBufferMinutes = 30;

    public int RoomId { get; private set; }

    /// <summary>
    /// Navigation property to Room (loaded when needed)
    /// </summary>
    public Room? Room { get; private set; }

    public string CustomerId { get; private set; }
    public string? CustomerName { get; private set; }

    /// <summary>
    /// When the reservation was created
    /// </summary>
    public DateTime CreatedAt { get; private set; }

    /// <summary>
    /// Scheduled start time (when customer wants to start)
    /// </summary>
    public DateTime ScheduledStartTime { get; private set; }

    /// <summary>
    /// Actual session start time (when admin clicks start)
    /// </summary>
    public DateTime? ActualStartTime { get; private set; }

    /// <summary>
    /// Session end time (when admin clicks end)
    /// </summary>
    public DateTime? EndTime { get; private set; }

    /// <summary>
    /// Hourly rate locked at reservation time
    /// </summary>
    public decimal HourlyRate { get; private set; }

    /// <summary>
    /// Calculated total cost when session ends
    /// </summary>
    public decimal? TotalCost { get; private set; }

    public ReservationStatus Status { get; private set; }

    public string? Notes { get; private set; }

    protected Reservation()
    {
        CustomerId = string.Empty;
    }

    /// <summary>
    /// Create a new reservation for a future time slot (same day only)
    /// </summary>
    public Reservation(
        int roomId,
        string customerId,
        string? customerName,
        DateTime scheduledStartTime,
        decimal hourlyRate,
        string? notes = null) : this()
    {
        if (string.IsNullOrWhiteSpace(customerId))
            throw new RoomsDomainException("Customer ID is required");

        // Validate same-day only booking
        if (scheduledStartTime.Date != DateTime.UtcNow.Date)
            throw new RoomsDomainException("Reservations can only be made for today");

        // Validate not in the past (allow 5 minute grace period)
        if (scheduledStartTime < DateTime.UtcNow.AddMinutes(-5))
            throw new RoomsDomainException("Cannot reserve for a time in the past");

        if (hourlyRate <= 0)
            throw new RoomsDomainException("Hourly rate must be greater than zero");

        RoomId = roomId;
        CustomerId = customerId;
        CustomerName = customerName;
        ScheduledStartTime = scheduledStartTime;
        HourlyRate = hourlyRate;
        Notes = notes;
        CreatedAt = DateTime.UtcNow;
        Status = ReservationStatus.Reserved;

        AddDomainEvent(new RoomReservedDomainEvent(this));
    }

    /// <summary>
    /// Create an immediate session (walk-in, starts now)
    /// </summary>
    public static Reservation CreateWalkIn(
        int roomId,
        string customerId,
        string? customerName,
        decimal hourlyRate,
        string? notes = null)
    {
        if (string.IsNullOrWhiteSpace(customerId))
            throw new RoomsDomainException("Customer ID is required");

        if (hourlyRate <= 0)
            throw new RoomsDomainException("Hourly rate must be greater than zero");

        var reservation = new Reservation
        {
            RoomId = roomId,
            CustomerId = customerId,
            CustomerName = customerName,
            ScheduledStartTime = DateTime.UtcNow,
            ActualStartTime = DateTime.UtcNow,
            HourlyRate = hourlyRate,
            Notes = notes,
            CreatedAt = DateTime.UtcNow,
            Status = ReservationStatus.Active
        };

        reservation.AddDomainEvent(new SessionStartedDomainEvent(reservation));
        return reservation;
    }

    /// <summary>
    /// Start the session (admin action)
    /// </summary>
    public void StartSession()
    {
        if (Status != ReservationStatus.Reserved)
            throw new RoomsDomainException($"Cannot start session from status {Status}. Only reserved sessions can be started.");

        ActualStartTime = DateTime.UtcNow;
        Status = ReservationStatus.Active;

        AddDomainEvent(new SessionStartedDomainEvent(this));
    }

    /// <summary>
    /// End the session and calculate cost (admin action)
    /// </summary>
    public void EndSession()
    {
        if (Status != ReservationStatus.Active)
            throw new RoomsDomainException($"Cannot end session from status {Status}. Only active sessions can be ended.");

        if (ActualStartTime == null)
            throw new RoomsDomainException("Session was never started");

        EndTime = DateTime.UtcNow;
        TotalCost = CalculateCost();
        Status = ReservationStatus.Completed;

        AddDomainEvent(new SessionEndedDomainEvent(this));
    }

    /// <summary>
    /// Cancel the reservation
    /// </summary>
    public void Cancel()
    {
        if (Status == ReservationStatus.Completed)
            throw new RoomsDomainException("Cannot cancel a completed session");

        if (Status == ReservationStatus.Cancelled)
            throw new RoomsDomainException("Reservation is already cancelled");

        var previousStatus = Status;
        Status = ReservationStatus.Cancelled;

        AddDomainEvent(new ReservationCancelledDomainEvent(this, previousStatus));
    }

    /// <summary>
    /// Calculate cost based on duration (rounds up to nearest 30 minutes)
    /// </summary>
    private decimal CalculateCost()
    {
        if (ActualStartTime == null || EndTime == null)
            return 0;

        var duration = EndTime.Value - ActualStartTime.Value;
        var totalMinutes = duration.TotalMinutes;

        // Round up to nearest 30 minutes
        var halfHours = Math.Ceiling(totalMinutes / 30);
        var hours = (decimal)halfHours / 2;

        return hours * HourlyRate;
    }

    /// <summary>
    /// Get current session duration if active
    /// </summary>
    public TimeSpan? GetCurrentDuration()
    {
        if (Status != ReservationStatus.Active || ActualStartTime == null)
            return null;

        return DateTime.UtcNow - ActualStartTime.Value;
    }

    /// <summary>
    /// Get the formatted duration string (HH:MM:SS)
    /// </summary>
    public string GetFormattedDuration()
    {
        var duration = GetCurrentDuration();
        if (duration == null)
            return "00:00:00";

        return duration.Value.ToString(@"hh\:mm\:ss");
    }

    /// <summary>
    /// Check if this reservation is imminent (within buffer window)
    /// </summary>
    public bool IsImminent(int bufferMinutes = 15)
    {
        if (Status != ReservationStatus.Reserved)
            return false;

        var now = DateTime.UtcNow;
        return ScheduledStartTime <= now.AddMinutes(bufferMinutes) &&
               ScheduledStartTime >= now.AddMinutes(-bufferMinutes);
    }

    /// <summary>
    /// Check if reservation is for active/reserved status (not completed/cancelled)
    /// </summary>
    public bool IsActiveOrReserved()
    {
        return Status == ReservationStatus.Active || Status == ReservationStatus.Reserved;
    }
}
