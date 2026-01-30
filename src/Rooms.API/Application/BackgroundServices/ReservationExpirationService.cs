using Chillax.Rooms.Domain.AggregatesModel.ReservationAggregate;
using Microsoft.EntityFrameworkCore;
using RoomsContext = Chillax.Rooms.Infrastructure.RoomsContext;

namespace Chillax.Rooms.API.Application.BackgroundServices;

/// <summary>
/// Background service that automatically cancels expired reservations (no-shows)
/// </summary>
public class ReservationExpirationService : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<ReservationExpirationService> _logger;
    private readonly TimeSpan _checkInterval = TimeSpan.FromMinutes(1);

    public ReservationExpirationService(
        IServiceProvider serviceProvider,
        ILogger<ReservationExpirationService> logger)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Reservation expiration service started");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await CancelExpiredReservationsAsync(stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error cancelling expired reservations");
            }

            await Task.Delay(_checkInterval, stoppingToken);
        }

        _logger.LogInformation("Reservation expiration service stopped");
    }

    private async Task CancelExpiredReservationsAsync(CancellationToken cancellationToken)
    {
        using var scope = _serviceProvider.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<RoomsContext>();

        var expirationThreshold = DateTime.UtcNow.AddMinutes(-Reservation.ReservationExpirationMinutes);

        // Find all reserved (not started) reservations that have exceeded the timeout
        var expiredReservations = await context.Reservations
            .Where(r => r.Status == ReservationStatus.Reserved)
            .Where(r => r.CreatedAt <= expirationThreshold)
            .ToListAsync(cancellationToken);

        if (expiredReservations.Count == 0)
            return;

        foreach (var reservation in expiredReservations)
        {
            reservation.CancelDueToExpiration();
            _logger.LogInformation(
                "Auto-cancelled expired reservation {ReservationId} for room {RoomId} (customer: {CustomerId})",
                reservation.Id, reservation.RoomId, reservation.CustomerId);
        }

        await context.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Cancelled {Count} expired reservations", expiredReservations.Count);
    }
}
