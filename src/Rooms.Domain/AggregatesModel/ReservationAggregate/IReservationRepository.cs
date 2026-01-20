using Chillax.Rooms.Domain.SeedWork;

namespace Chillax.Rooms.Domain.AggregatesModel.ReservationAggregate;

/// <summary>
/// Repository interface for Reservation aggregate
/// </summary>
public interface IReservationRepository : IRepository<Reservation>
{
    Reservation Add(Reservation reservation);
    void Update(Reservation reservation);
    Task<Reservation?> GetAsync(int reservationId);
    Task<Reservation?> GetWithRoomAsync(int reservationId);

    /// <summary>
    /// Get customer's active or reserved session (for one-at-a-time rule)
    /// </summary>
    Task<Reservation?> GetActiveReservationForCustomerAsync(string customerId);

    /// <summary>
    /// Get all active and reserved sessions for a room today
    /// </summary>
    Task<List<Reservation>> GetTodayReservationsForRoomAsync(int roomId);

    /// <summary>
    /// Get all active sessions (for admin view)
    /// </summary>
    Task<List<Reservation>> GetActiveSessionsAsync();

    /// <summary>
    /// Get customer's reservation history
    /// </summary>
    Task<List<Reservation>> GetCustomerReservationsAsync(string customerId, int? limit = null);

    /// <summary>
    /// Check if room has any conflicting reservations at a specific time
    /// </summary>
    Task<bool> HasConflictingReservationAsync(int roomId, DateTime scheduledTime, int bufferMinutes = 15);
}
