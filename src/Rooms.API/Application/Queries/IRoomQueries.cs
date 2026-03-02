namespace Chillax.Rooms.API.Application.Queries;

public interface IRoomQueries
{
    /// <summary>
    /// Get all rooms with their current display status for a branch
    /// </summary>
    Task<IEnumerable<RoomViewModel>> GetAllRoomsAsync(int branchId);

    /// <summary>
    /// Get rooms available now (for immediate booking) for a branch
    /// </summary>
    Task<IEnumerable<RoomViewModel>> GetAvailableRoomsAsync(int branchId);

    /// <summary>
    /// Get room by ID
    /// </summary>
    Task<RoomViewModel?> GetRoomByIdAsync(int roomId);

    /// <summary>
    /// Get customer's reservations
    /// </summary>
    Task<IEnumerable<ReservationViewModel>> GetCustomerReservationsAsync(string customerId);

    /// <summary>
    /// Get all active sessions (admin view) for a branch
    /// </summary>
    Task<IEnumerable<ReservationViewModel>> GetActiveSessionsAsync(int branchId);

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
