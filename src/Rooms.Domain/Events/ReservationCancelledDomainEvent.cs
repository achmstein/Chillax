using Chillax.Rooms.Domain.AggregatesModel.ReservationAggregate;

namespace Chillax.Rooms.Domain.Events;

/// <summary>
/// Raised when a reservation is cancelled
/// </summary>
public record class ReservationCancelledDomainEvent(
    Reservation Reservation,
    ReservationStatus PreviousStatus) : INotification;
