using Chillax.Rooms.Domain.AggregatesModel.ReservationAggregate;
using Chillax.Rooms.Domain.AggregatesModel.RoomAggregate;
using Chillax.Rooms.Domain.Exceptions;
using MediatR;
using Microsoft.Extensions.Logging;

namespace Chillax.Rooms.API.Application.Commands;

public class CreateReservationCommandHandler : IRequestHandler<CreateReservationCommand, int>
{
    private readonly IRoomRepository _roomRepository;
    private readonly IReservationRepository _reservationRepository;
    private readonly ILogger<CreateReservationCommandHandler> _logger;

    public CreateReservationCommandHandler(
        IRoomRepository roomRepository,
        IReservationRepository reservationRepository,
        ILogger<CreateReservationCommandHandler> logger)
    {
        _roomRepository = roomRepository;
        _reservationRepository = reservationRepository;
        _logger = logger;
    }

    public async Task<int> Handle(CreateReservationCommand request, CancellationToken cancellationToken)
    {
        // Rule 1: One reservation per customer at a time
        var existingReservation = await _reservationRepository
            .GetActiveReservationForCustomerAsync(request.CustomerId);

        if (existingReservation != null)
            throw new RoomsDomainException("You already have an active reservation or session");

        // Rule 2: Room must exist
        var room = await _roomRepository.GetAsync(request.RoomId);
        if (room == null)
            throw new RoomsDomainException($"Room {request.RoomId} not found");

        // Rule 3: Room must be physically available
        if (!room.IsPhysicallyAvailable())
            throw new RoomsDomainException("Room is not available");

        // Rule 4: No conflicting reservations
        var hasConflict = await _reservationRepository
            .HasConflictingReservationAsync(request.RoomId, request.ScheduledStartTime);

        if (hasConflict)
            throw new RoomsDomainException("Room has a conflicting reservation at this time");

        // Create reservation (locks hourly rate at reservation time)
        var reservation = new Reservation(
            request.RoomId,
            request.CustomerId,
            request.CustomerName,
            request.ScheduledStartTime,
            room.HourlyRate,
            request.Notes);

        _reservationRepository.Add(reservation);

        _logger.LogInformation("Creating reservation for room {RoomId} at {Time} for customer {CustomerId}",
            request.RoomId, request.ScheduledStartTime, request.CustomerId);

        await _reservationRepository.UnitOfWork.SaveEntitiesAsync(cancellationToken);

        return reservation.Id;
    }
}
