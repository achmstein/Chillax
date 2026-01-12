using Chillax.Rooms.API.Model;

namespace Chillax.Rooms.API.Dtos;

/// <summary>
/// Extension methods for mapping entities to DTOs
/// </summary>
public static class RoomMappers
{
    public static RoomDto ToDto(this Room room)
    {
        return new RoomDto
        {
            Id = room.Id,
            Name = room.Name,
            Description = room.Description,
            Status = room.Status,
            HourlyRate = room.HourlyRate,
            PictureFileName = room.PictureFileName
        };
    }

    public static List<RoomDto> ToDtoList(this IEnumerable<Room> rooms)
    {
        return rooms.Select(r => r.ToDto()).ToList();
    }

    public static RoomSessionDto ToDto(this RoomSession session)
    {
        return new RoomSessionDto
        {
            Id = session.Id,
            RoomId = session.RoomId,
            RoomName = session.Room?.Name,
            CustomerId = session.CustomerId,
            CustomerName = session.CustomerName,
            ReservationTime = session.ReservationTime,
            StartTime = session.StartTime,
            EndTime = session.EndTime,
            TotalCost = session.TotalCost,
            Status = session.Status,
            Notes = session.Notes
        };
    }

    public static List<RoomSessionDto> ToDtoList(this IEnumerable<RoomSession> sessions)
    {
        return sessions.Select(s => s.ToDto()).ToList();
    }
}
