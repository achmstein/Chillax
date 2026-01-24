using Chillax.Rooms.Domain.SeedWork;

namespace Chillax.Rooms.Domain.AggregatesModel.ReservationAggregate;

/// <summary>
/// Represents a member of a session (owner or member who joined via access code)
/// </summary>
public class SessionMember : Entity
{
    public int ReservationId { get; private set; }

    public string CustomerId { get; private set; }

    public string? CustomerName { get; private set; }

    public DateTime JoinedAt { get; private set; }

    public SessionMemberRole Role { get; private set; }

    protected SessionMember()
    {
        CustomerId = string.Empty;
    }

    internal SessionMember(
        int reservationId,
        string customerId,
        string? customerName,
        SessionMemberRole role) : this()
    {
        ReservationId = reservationId;
        CustomerId = customerId;
        CustomerName = customerName;
        JoinedAt = DateTime.UtcNow;
        Role = role;
    }
}
