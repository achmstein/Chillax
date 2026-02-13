using Chillax.Rooms.Domain.AggregatesModel.ReservationAggregate;
using Chillax.Rooms.Domain.AggregatesModel.RoomAggregate;
using Chillax.Rooms.Domain.Exceptions;
using MediatR;
using Microsoft.Extensions.Logging;

namespace Chillax.Rooms.API.Application.Commands;

public class StartSessionCommandHandler : IRequestHandler<StartSessionCommand, bool>
{
    private readonly IReservationRepository _reservationRepository;
    private readonly IRoomRepository _roomRepository;
    private readonly ILogger<StartSessionCommandHandler> _logger;

    public StartSessionCommandHandler(
        IReservationRepository reservationRepository,
        IRoomRepository roomRepository,
        ILogger<StartSessionCommandHandler> logger)
    {
        _reservationRepository = reservationRepository;
        _roomRepository = roomRepository;
        _logger = logger;
    }

    public async Task<bool> Handle(StartSessionCommand request, CancellationToken cancellationToken)
    {
        var reservation = await _reservationRepository.GetWithMembersAsync(request.ReservationId);
        if (reservation == null)
            throw new RoomsDomainException($"Reservation {request.ReservationId} not found");

        var room = await _roomRepository.GetAsync(reservation.RoomId);
        if (room == null)
            throw new RoomsDomainException($"Room {reservation.RoomId} not found");

        // Start session on reservation (raises SessionStartedDomainEvent)
        reservation.StartSession();

        // Ensure unique access code among active sessions
        for (var i = 0; i < 10 && await _reservationRepository.IsAccessCodeInUseAsync(reservation.AccessCode!); i++)
        {
            reservation.GenerateAccessCode();
        }

        // Update room physical status
        room.SetOccupied();

        _logger.LogInformation("Starting session for reservation {ReservationId}", request.ReservationId);

        _reservationRepository.Update(reservation);
        _roomRepository.Update(room);

        return await _reservationRepository.UnitOfWork.SaveEntitiesAsync(cancellationToken);
    }
}
