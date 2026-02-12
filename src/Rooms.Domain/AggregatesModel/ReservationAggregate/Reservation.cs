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
    /// Time in minutes before a reservation expires if not started
    /// </summary>
    public const int ReservationExpirationMinutes = 15;

    public int RoomId { get; private set; }

    /// <summary>
    /// Navigation property to Room (loaded when needed)
    /// </summary>
    public Room? Room { get; private set; }

    /// <summary>
    /// Customer ID - nullable for walk-ins that have no owner initially
    /// </summary>
    public string? CustomerId { get; private set; }
    public string? CustomerName { get; private set; }

    /// <summary>
    /// 4-digit access code for joining the session
    /// </summary>
    public string? AccessCode { get; private set; }

    /// <summary>
    /// When the access code was generated
    /// </summary>
    public DateTime? AccessCodeGeneratedAt { get; private set; }

    private readonly List<SessionMember> _sessionMembers = new();
    public IReadOnlyCollection<SessionMember> SessionMembers => _sessionMembers.AsReadOnly();

    /// <summary>
    /// When the reservation was created (customer has 15 min to arrive from this time)
    /// </summary>
    public DateTime CreatedAt { get; private set; }

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
    }

    /// <summary>
    /// Create a new immediate reservation (customer has 15 minutes to arrive)
    /// </summary>
    public Reservation(
        int roomId,
        string customerId,
        string? customerName,
        decimal hourlyRate,
        string? notes = null) : this()
    {
        if (string.IsNullOrWhiteSpace(customerId))
            throw new RoomsDomainException("Customer ID is required");

        if (hourlyRate <= 0)
            throw new RoomsDomainException("Hourly rate must be greater than zero");

        RoomId = roomId;
        CustomerId = customerId;
        CustomerName = customerName;
        HourlyRate = hourlyRate;
        Notes = notes;
        CreatedAt = DateTime.UtcNow;
        Status = ReservationStatus.Reserved;

        AddDomainEvent(new RoomReservedDomainEvent(this));
    }

    /// <summary>
    /// Create an immediate session (walk-in, starts now) with an assigned customer
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
            ActualStartTime = DateTime.UtcNow,
            HourlyRate = hourlyRate,
            Notes = notes,
            CreatedAt = DateTime.UtcNow,
            Status = ReservationStatus.Active
        };

        reservation.GenerateAccessCode();
        reservation.AddDomainEvent(new SessionStartedDomainEvent(reservation));
        return reservation;
    }

    /// <summary>
    /// Create an immediate session (walk-in, starts now) without an assigned customer.
    /// The first customer to join via access code becomes the owner.
    /// </summary>
    public static Reservation CreateWalkInWithoutOwner(
        int roomId,
        decimal hourlyRate,
        string? notes = null)
    {
        if (hourlyRate <= 0)
            throw new RoomsDomainException("Hourly rate must be greater than zero");

        var reservation = new Reservation
        {
            RoomId = roomId,
            CustomerId = null,
            CustomerName = null,
            ActualStartTime = DateTime.UtcNow,
            HourlyRate = hourlyRate,
            Notes = notes,
            CreatedAt = DateTime.UtcNow,
            Status = ReservationStatus.Active
        };

        reservation.GenerateAccessCode();
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

        GenerateAccessCode();

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
    /// Calculate cost based on duration (rounds to nearest quarter hour)
    /// </summary>
    private decimal CalculateCost()
    {
        if (ActualStartTime == null || EndTime == null)
            return 0;

        var duration = EndTime.Value - ActualStartTime.Value;
        var totalMinutes = duration.TotalMinutes;

        // Round to nearest quarter hour (15 minutes)
        var quarters = Math.Round(totalMinutes / 15, MidpointRounding.AwayFromZero);
        var hours = (decimal)quarters * 0.25m;

        return hours * HourlyRate;
    }

    /// <summary>
    /// Get duration rounded to nearest quarter hour (e.g. 2.25, 3.5) for POS billing
    /// Returns null if session hasn't started or ended
    /// </summary>
    public decimal? GetRoundedHours()
    {
        if (ActualStartTime == null || EndTime == null)
            return null;

        var totalMinutes = (EndTime.Value - ActualStartTime.Value).TotalMinutes;
        var quarters = Math.Round(totalMinutes / 15, MidpointRounding.AwayFromZero);
        return (decimal)quarters * 0.25m;
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
    /// Check if reservation is for active/reserved status (not completed/cancelled)
    /// </summary>
    public bool IsActiveOrReserved()
    {
        return Status == ReservationStatus.Active || Status == ReservationStatus.Reserved;
    }

    /// <summary>
    /// Check if this reservation has expired (reserved but not started within timeout)
    /// </summary>
    public bool IsExpired()
    {
        if (Status != ReservationStatus.Reserved)
            return false;

        return DateTime.UtcNow > CreatedAt.AddMinutes(ReservationExpirationMinutes);
    }

    /// <summary>
    /// Get the expiration time for this reservation
    /// </summary>
    public DateTime? GetExpirationTime()
    {
        if (Status != ReservationStatus.Reserved)
            return null;

        return CreatedAt.AddMinutes(ReservationExpirationMinutes);
    }

    /// <summary>
    /// Get remaining time before expiration (null if not reserved or already expired)
    /// </summary>
    public TimeSpan? GetTimeUntilExpiration()
    {
        if (Status != ReservationStatus.Reserved)
            return null;

        var expiresAt = CreatedAt.AddMinutes(ReservationExpirationMinutes);
        var remaining = expiresAt - DateTime.UtcNow;

        return remaining > TimeSpan.Zero ? remaining : TimeSpan.Zero;
    }

    /// <summary>
    /// Cancel reservation due to expiration (no-show)
    /// </summary>
    public void CancelDueToExpiration()
    {
        if (Status != ReservationStatus.Reserved)
            throw new RoomsDomainException("Only reserved sessions can be cancelled due to expiration");

        Status = ReservationStatus.Cancelled;
        EndTime = DateTime.UtcNow;
    }

    /// <summary>
    /// Generate a new access code in AABB format (paired digits, e.g. "1133")
    /// </summary>
    public void GenerateAccessCode()
    {
        var a = Random.Shared.Next(0, 10);
        var b = Random.Shared.Next(0, 10);
        AccessCode = $"{a}{a}{b}{b}";
        AccessCodeGeneratedAt = DateTime.UtcNow;
    }

    /// <summary>
    /// Regenerate the access code (e.g., if compromised)
    /// </summary>
    public void RegenerateAccessCode()
    {
        if (Status != ReservationStatus.Active)
            throw new RoomsDomainException("Can only regenerate access code for active sessions");

        GenerateAccessCode();
    }

    /// <summary>
    /// Add a member to the session. First joiner of a walk-in session becomes the owner.
    /// </summary>
    public void AddMember(string customerId, string? customerName)
    {
        if (string.IsNullOrWhiteSpace(customerId))
            throw new RoomsDomainException("Customer ID is required");

        if (Status != ReservationStatus.Active)
            throw new RoomsDomainException("Can only join active sessions");

        if (HasMember(customerId))
            throw new RoomsDomainException("Customer is already a member of this session");

        // Determine role: first joiner of walk-in (no owner) becomes owner
        var role = SessionMemberRole.Member;
        if (CustomerId == null && !_sessionMembers.Any())
        {
            role = SessionMemberRole.Owner;
            // Also set as the primary customer
            CustomerId = customerId;
            CustomerName = customerName;
        }

        var member = new SessionMember(Id, customerId, customerName, role);
        _sessionMembers.Add(member);
    }

    /// <summary>
    /// Remove a member from the session
    /// </summary>
    public void RemoveMember(string customerId)
    {
        if (string.IsNullOrWhiteSpace(customerId))
            throw new RoomsDomainException("Customer ID is required");

        var member = _sessionMembers.FirstOrDefault(m => m.CustomerId == customerId);
        if (member == null)
            throw new RoomsDomainException("Customer is not a member of this session");

        if (member.Role == SessionMemberRole.Owner)
            throw new RoomsDomainException("Cannot remove the session owner");

        _sessionMembers.Remove(member);
    }

    /// <summary>
    /// Check if a customer is a member (owner or member) of this session
    /// </summary>
    public bool HasMember(string customerId)
    {
        if (string.IsNullOrWhiteSpace(customerId))
            return false;

        // Check if they're the primary customer
        if (CustomerId == customerId)
            return true;

        // Check session members list
        return _sessionMembers.Any(m => m.CustomerId == customerId);
    }

    /// <summary>
    /// Get the role of a customer in this session
    /// </summary>
    public SessionMemberRole? GetMemberRole(string customerId)
    {
        if (string.IsNullOrWhiteSpace(customerId))
            return null;

        // Primary customer is always owner
        if (CustomerId == customerId)
            return SessionMemberRole.Owner;

        return _sessionMembers
            .FirstOrDefault(m => m.CustomerId == customerId)
            ?.Role;
    }

    /// <summary>
    /// Assign a customer to a walk-in session (admin action)
    /// </summary>
    public void AssignCustomer(string customerId, string? customerName)
    {
        if (string.IsNullOrWhiteSpace(customerId))
            throw new RoomsDomainException("Customer ID is required");

        if (Status != ReservationStatus.Active)
            throw new RoomsDomainException("Can only assign customers to active sessions");

        if (CustomerId != null)
            throw new RoomsDomainException("Session already has an assigned customer");

        CustomerId = customerId;
        CustomerName = customerName;

        // Also add as owner member
        var member = new SessionMember(Id, customerId, customerName, SessionMemberRole.Owner);
        _sessionMembers.Add(member);
    }
}

