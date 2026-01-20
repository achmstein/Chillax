using Chillax.Rooms.Domain.AggregatesModel.ReservationAggregate;

namespace Chillax.Rooms.Domain.Events;

/// <summary>
/// Raised when admin starts a session (customer begins playing)
/// </summary>
public record class SessionStartedDomainEvent(Reservation Reservation) : INotification;
