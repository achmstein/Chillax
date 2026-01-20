using Chillax.Rooms.Domain.AggregatesModel.ReservationAggregate;

namespace Chillax.Rooms.Domain.Events;

/// <summary>
/// Raised when a customer creates a reservation
/// </summary>
public record class RoomReservedDomainEvent(Reservation Reservation) : INotification;
