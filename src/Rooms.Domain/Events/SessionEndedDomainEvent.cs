using Chillax.Rooms.Domain.AggregatesModel.ReservationAggregate;

namespace Chillax.Rooms.Domain.Events;

/// <summary>
/// Raised when admin ends a session (customer stops playing)
/// Used to update room status and potentially trigger billing/loyalty
/// </summary>
public record class SessionEndedDomainEvent(Reservation Reservation) : INotification;
