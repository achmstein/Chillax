using Chillax.Rooms.Domain.AggregatesModel.ReservationAggregate;
using Chillax.Rooms.Domain.AggregatesModel.RoomAggregate;
using Chillax.Rooms.Domain.Exceptions;
using MediatR;
using Microsoft.Extensions.Logging;

namespace Chillax.Rooms.API.Application.Commands;

public class StartWalkInSessionCommandHandler : IRequestHandler<StartWalkInSessionCommand, StartWalkInSessionResult>
{
    private readonly IReservationRepository _reservationRepository;
    private readonly IRoomRepository _roomRepository;
    private readonly ILogger<StartWalkInSessionCommandHandler> _logger;

    public StartWalkInSessionCommandHandler(
        IReservationRepository reservationRepository,
        IRoomRepository roomRepository,
        ILogger<StartWalkInSessionCommandHandler> logger)
    {
        _reservationRepository = reservationRepository;
        _roomRepository = roomRepository;
        _logger = logger;
    }

    public async Task<StartWalkInSessionResult> Handle(StartWalkInSessionCommand request, CancellationToken cancellationToken)
    {
        var room = await _roomRepository.GetAsync(request.RoomId);
        if (room == null)
            throw new RoomsDomainException($"Room {request.RoomId} not found");

        if (!room.IsPhysicallyAvailable())
            throw new RoomsDomainException("Room is not available");

        // Check for any active sessions on this room
        var hasActiveReservation = await _reservationRepository.HasActiveReservationAsync(request.RoomId);
        if (hasActiveReservation)
            throw new RoomsDomainException("Room already has an active session");

        // Create walk-in session without owner
        var reservation = Reservation.CreateWalkInWithoutOwner(
            request.RoomId,
            room.HourlyRate,
            request.Notes);

        _reservationRepository.Add(reservation);

        // Update room physical status
        room.SetOccupied();
        _roomRepository.Update(room);

        _logger.LogInformation("Starting walk-in session for room {RoomId} with access code {AccessCode}",
            request.RoomId, reservation.AccessCode);

        await _reservationRepository.UnitOfWork.SaveEntitiesAsync(cancellationToken);

        return new StartWalkInSessionResult(reservation.Id, reservation.AccessCode!);
    }
}
