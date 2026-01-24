using Chillax.Rooms.Domain.AggregatesModel.ReservationAggregate;
using Chillax.Rooms.Domain.AggregatesModel.RoomAggregate;
using Microsoft.EntityFrameworkCore;
using Room = Chillax.Rooms.Domain.AggregatesModel.RoomAggregate.Room;
using RoomsContext = Chillax.Rooms.Infrastructure.RoomsContext;

namespace Chillax.Rooms.API.Application.Queries;

public class RoomQueries : IRoomQueries
{
    private readonly RoomsContext _context;

    public RoomQueries(RoomsContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<RoomViewModel>> GetAllRoomsAsync()
    {
        var rooms = await _context.Rooms
            .OrderBy(r => r.Name)
            .ToListAsync();

        var today = DateTime.UtcNow.Date;
        var tomorrow = today.AddDays(1);

        // Get all today's reservations for computing display status
        var todayReservations = await _context.Reservations
            .Where(r => r.ScheduledStartTime >= today && r.ScheduledStartTime < tomorrow)
            .Where(r => r.Status == ReservationStatus.Reserved || r.Status == ReservationStatus.Active)
            .ToListAsync();

        return rooms.Select(room =>
        {
            var roomReservations = todayReservations.Where(r => r.RoomId == room.Id).ToList();
            return MapToViewModel(room, roomReservations);
        });
    }

    public async Task<IEnumerable<RoomViewModel>> GetAvailableRoomsAsync()
    {
        var allRooms = await GetAllRoomsAsync();
        return allRooms.Where(r => r.DisplayStatus == RoomDisplayStatus.Available);
    }

    public async Task<RoomViewModel?> GetRoomByIdAsync(int roomId)
    {
        var room = await _context.Rooms.FindAsync(roomId);
        if (room == null) return null;

        var today = DateTime.UtcNow.Date;
        var tomorrow = today.AddDays(1);

        var roomReservations = await _context.Reservations
            .Where(r => r.RoomId == roomId)
            .Where(r => r.ScheduledStartTime >= today && r.ScheduledStartTime < tomorrow)
            .Where(r => r.Status == ReservationStatus.Reserved || r.Status == ReservationStatus.Active)
            .ToListAsync();

        return MapToViewModel(room, roomReservations);
    }

    public async Task<IEnumerable<ReservationViewModel>> GetCustomerReservationsAsync(string customerId)
    {
        // Include sessions where customer is owner OR a session member
        var reservations = await _context.Reservations
            .Include(r => r.Room)
            .Include(r => r.SessionMembers)
            .Where(r => r.CustomerId == customerId ||
                        r.SessionMembers.Any(m => m.CustomerId == customerId))
            .OrderByDescending(r => r.CreatedAt)
            .ToListAsync();

        return reservations.Select(MapToViewModel);
    }

    public async Task<IEnumerable<ReservationViewModel>> GetActiveSessionsAsync()
    {
        var reservations = await _context.Reservations
            .Include(r => r.Room)
            .Where(r => r.Status == ReservationStatus.Active || r.Status == ReservationStatus.Reserved)
            .OrderBy(r => r.ScheduledStartTime)
            .ToListAsync();

        return reservations.Select(MapToViewModel);
    }

    public async Task<ReservationViewModel?> GetReservationByIdAsync(int reservationId)
    {
        var reservation = await _context.Reservations
            .Include(r => r.Room)
            .FirstOrDefaultAsync(r => r.Id == reservationId);

        return reservation == null ? null : MapToViewModel(reservation);
    }

    private static RoomViewModel MapToViewModel(Room room, List<Reservation> reservations)
    {
        var displayStatus = ComputeDisplayStatus(room, reservations);
        var nextReservation = reservations
            .Where(r => r.Status == ReservationStatus.Reserved)
            .OrderBy(r => r.ScheduledStartTime)
            .FirstOrDefault();

        return new RoomViewModel
        {
            Id = room.Id,
            Name = room.Name,
            Description = room.Description,
            HourlyRate = room.HourlyRate,
            DisplayStatus = displayStatus,
            NextReservationTime = nextReservation?.ScheduledStartTime
        };
    }

    private static RoomDisplayStatus ComputeDisplayStatus(Room room, List<Reservation> reservations)
    {
        // Check physical status first
        if (room.PhysicalStatus == RoomPhysicalStatus.Maintenance)
            return RoomDisplayStatus.Maintenance;

        if (room.PhysicalStatus == RoomPhysicalStatus.Occupied)
            return RoomDisplayStatus.Occupied;

        // Check for active sessions
        if (reservations.Any(r => r.Status == ReservationStatus.Active))
            return RoomDisplayStatus.Occupied;

        // Check for imminent reservations using domain logic
        if (reservations.Any(r => r.IsImminent()))
            return RoomDisplayStatus.ReservedSoon;

        return RoomDisplayStatus.Available;
    }

    public async Task<SessionPreviewViewModel?> GetSessionPreviewByCodeAsync(string accessCode)
    {
        var reservation = await _context.Reservations
            .Include(r => r.Room)
            .Include(r => r.SessionMembers)
            .Where(r => r.AccessCode == accessCode)
            .Where(r => r.Status == ReservationStatus.Active)
            .FirstOrDefaultAsync();

        if (reservation == null)
            return null;

        return new SessionPreviewViewModel
        {
            SessionId = reservation.Id,
            RoomId = reservation.RoomId,
            RoomName = reservation.Room?.Name ?? $"Room {reservation.RoomId}",
            StartTime = reservation.ActualStartTime ?? reservation.CreatedAt,
            MemberCount = reservation.SessionMembers.Count
        };
    }

    private static ReservationViewModel MapToViewModel(Reservation reservation)
    {
        return new ReservationViewModel
        {
            Id = reservation.Id,
            RoomId = reservation.RoomId,
            RoomName = reservation.Room?.Name ?? $"Room {reservation.RoomId}",
            HourlyRate = reservation.HourlyRate,
            CustomerId = reservation.CustomerId,
            CustomerName = reservation.CustomerName,
            CreatedAt = reservation.CreatedAt,
            ScheduledStartTime = reservation.ScheduledStartTime,
            ActualStartTime = reservation.ActualStartTime,
            EndTime = reservation.EndTime,
            TotalCost = reservation.TotalCost,
            Status = reservation.Status,
            Notes = reservation.Notes,
            AccessCode = reservation.AccessCode
        };
    }
}
