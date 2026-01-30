namespace Chillax.Rooms.API.Application.Queries;

public interface IRoomQueries
{
    /// <summary>
    /// Get all rooms with their current display status
    /// </summary>
    Task<IEnumerable<RoomViewModel>> GetAllRoomsAsync();

    /// <summary>
    /// Get rooms available now (for immediate booking)
    /// </summary>
    Task<IEnumerable<RoomViewModel>> GetAvailableRoomsAsync();

    /// <summary>
    /// Get room by ID
    /// </summary>
    Task<RoomViewModel?> GetRoomByIdAsync(int roomId);

    /// <summary>
    /// Get customer's reservations
    /// </summary>
    Task<IEnumerable<ReservationViewModel>> GetCustomerReservationsAsync(string customerId);

    /// <summary>
    /// Get all active sessions (admin view)
    /// </summary>
    Task<IEnumerable<ReservationViewModel>> GetActiveSessionsAsync();

    /// <summary>
    /// Get reservation by ID
    /// </summary>
    Task<ReservationViewModel?> GetReservationByIdAsync(int reservationId);

    /// <summary>
    /// Get session preview by access code (for joining)
    /// </summary>
    Task<SessionPreviewViewModel?> GetSessionPreviewByCodeAsync(string accessCode);

    /// <summary>
    /// Get completed session history for a room
    /// </summary>
    Task<IEnumerable<ReservationViewModel>> GetRoomSessionHistoryAsync(int roomId, int limit = 20);
}
