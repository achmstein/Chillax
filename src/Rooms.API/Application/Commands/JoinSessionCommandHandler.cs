using Chillax.Rooms.Domain.AggregatesModel.ReservationAggregate;
using Chillax.Rooms.Domain.Exceptions;
using MediatR;
using Microsoft.Extensions.Logging;

namespace Chillax.Rooms.API.Application.Commands;

public class JoinSessionCommandHandler : IRequestHandler<JoinSessionCommand, JoinSessionResult>
{
    private readonly IReservationRepository _reservationRepository;
    private readonly ILogger<JoinSessionCommandHandler> _logger;

    public JoinSessionCommandHandler(
        IReservationRepository reservationRepository,
        ILogger<JoinSessionCommandHandler> logger)
    {
        _reservationRepository = reservationRepository;
        _logger = logger;
    }

    public async Task<JoinSessionResult> Handle(JoinSessionCommand request, CancellationToken cancellationToken)
    {
        // Find active session by access code
        var reservation = await _reservationRepository.GetByAccessCodeAsync(request.AccessCode);
        if (reservation == null)
            throw new RoomsDomainException("Invalid access code or session has ended");

        // Check if customer already has an active session
        var existingReservation = await _reservationRepository
            .GetActiveReservationForCustomerAsync(request.CustomerId);

        if (existingReservation != null && existingReservation.Id != reservation.Id)
            throw new RoomsDomainException("You already have an active session in another room");

        // Add customer as member (will throw if already member)
        reservation.AddMember(request.CustomerId, request.CustomerName);

        _reservationRepository.Update(reservation);

        var role = reservation.GetMemberRole(request.CustomerId);
        var isOwner = role == SessionMemberRole.Owner;

        _logger.LogInformation("Customer {CustomerId} joined session {ReservationId} as {Role}",
            request.CustomerId, reservation.Id, role);

        await _reservationRepository.UnitOfWork.SaveEntitiesAsync(cancellationToken);

        return new JoinSessionResult(
            reservation.Id,
            reservation.RoomId,
            reservation.Room?.Name ?? $"Room {reservation.RoomId}",
            isOwner,
            reservation.ActualStartTime ?? DateTime.UtcNow);
    }
}
