using System.ComponentModel;
using Chillax.Rooms.API.Infrastructure;
using Chillax.Rooms.API.Model;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Chillax.Rooms.API.Apis;

public static class RoomsApi
{
    public static IEndpointRouteBuilder MapRoomsApi(this IEndpointRouteBuilder app)
    {
        var api = app.MapGroup("api/rooms");

        // Room endpoints
        api.MapGet("/", GetAllRooms)
            .WithName("ListRooms")
            .WithSummary("List all rooms")
            .WithDescription("Get all PlayStation rooms with their current status")
            .WithTags("Rooms");

        api.MapGet("/{id:int}", GetRoomById)
            .WithName("GetRoom")
            .WithSummary("Get room by ID")
            .WithDescription("Get a specific room by its ID")
            .WithTags("Rooms");

        api.MapGet("/available", GetAvailableRooms)
            .WithName("GetAvailableRooms")
            .WithSummary("Get available rooms")
            .WithDescription("Get only rooms that are currently available for reservation")
            .WithTags("Rooms");

        api.MapPut("/{id:int}/status", UpdateRoomStatus)
            .WithName("UpdateRoomStatus")
            .WithSummary("Update room status")
            .WithDescription("Update the status of a room (Admin only)")
            .WithTags("Rooms")
            .RequireAuthorization();

        // Reservation endpoints
        api.MapPost("/{roomId:int}/reserve", ReserveRoom)
            .WithName("ReserveRoom")
            .WithSummary("Reserve a room")
            .WithDescription("Create a reservation for a room")
            .WithTags("Reservations")
            .RequireAuthorization();

        // Session endpoints (Admin)
        api.MapPost("/sessions/{sessionId:int}/start", StartSession)
            .WithName("StartSession")
            .WithSummary("Start a session")
            .WithDescription("Start the timer for a reserved session (Admin only)")
            .WithTags("Sessions")
            .RequireAuthorization();

        api.MapPost("/sessions/{sessionId:int}/end", EndSession)
            .WithName("EndSession")
            .WithSummary("End a session")
            .WithDescription("End the session and calculate cost (Admin only)")
            .WithTags("Sessions")
            .RequireAuthorization();

        api.MapPost("/sessions/{sessionId:int}/cancel", CancelSession)
            .WithName("CancelSession")
            .WithSummary("Cancel a session")
            .WithDescription("Cancel a reservation or active session")
            .WithTags("Sessions")
            .RequireAuthorization();

        api.MapGet("/sessions/active", GetActiveSessions)
            .WithName("GetActiveSessions")
            .WithSummary("Get active sessions")
            .WithDescription("Get all currently active sessions (Admin only)")
            .WithTags("Sessions")
            .RequireAuthorization();

        api.MapGet("/sessions/customer/{customerId}", GetCustomerSessions)
            .WithName("GetCustomerSessions")
            .WithSummary("Get customer sessions")
            .WithDescription("Get all sessions for a specific customer")
            .WithTags("Sessions")
            .RequireAuthorization();

        api.MapGet("/sessions/{sessionId:int}", GetSessionById)
            .WithName("GetSession")
            .WithSummary("Get session by ID")
            .WithDescription("Get a specific session by its ID")
            .WithTags("Sessions")
            .RequireAuthorization();

        return app;
    }

    // Room endpoints
    public static async Task<Ok<List<Room>>> GetAllRooms(RoomsContext context)
    {
        var rooms = await context.Rooms
            .OrderBy(r => r.Name)
            .ToListAsync();
        return TypedResults.Ok(rooms);
    }

    public static async Task<Results<Ok<Room>, NotFound>> GetRoomById(
        RoomsContext context,
        [Description("The room ID")] int id)
    {
        var room = await context.Rooms.FindAsync(id);

        if (room == null)
        {
            return TypedResults.NotFound();
        }

        return TypedResults.Ok(room);
    }

    public static async Task<Ok<List<Room>>> GetAvailableRooms(RoomsContext context)
    {
        var rooms = await context.Rooms
            .Where(r => r.Status == RoomStatus.Available)
            .OrderBy(r => r.Name)
            .ToListAsync();
        return TypedResults.Ok(rooms);
    }

    public static async Task<Results<Ok<Room>, NotFound>> UpdateRoomStatus(
        RoomsContext context,
        [Description("The room ID")] int id,
        [Description("The new status")] RoomStatus status)
    {
        var room = await context.Rooms.FindAsync(id);

        if (room == null)
        {
            return TypedResults.NotFound();
        }

        room.Status = status;
        await context.SaveChangesAsync();

        return TypedResults.Ok(room);
    }

    // Reservation endpoints
    public static async Task<Results<Created<RoomSession>, NotFound, BadRequest<ProblemDetails>>> ReserveRoom(
        RoomsContext context,
        [Description("The room ID to reserve")] int roomId,
        ReserveRoomRequest request)
    {
        var room = await context.Rooms.FindAsync(roomId);

        if (room == null)
        {
            return TypedResults.NotFound();
        }

        if (room.Status != RoomStatus.Available)
        {
            return TypedResults.BadRequest<ProblemDetails>(new()
            {
                Detail = "Room is not available for reservation"
            });
        }

        var session = new RoomSession(request.CustomerId)
        {
            RoomId = roomId,
            CustomerName = request.CustomerName,
            Notes = request.Notes,
            Status = SessionStatus.Reserved
        };

        room.Status = RoomStatus.Reserved;

        context.RoomSessions.Add(session);
        await context.SaveChangesAsync();

        return TypedResults.Created($"/api/rooms/sessions/{session.Id}", session);
    }

    // Session endpoints
    public static async Task<Results<Ok<RoomSession>, NotFound, BadRequest<ProblemDetails>>> StartSession(
        RoomsContext context,
        [Description("The session ID")] int sessionId)
    {
        var session = await context.RoomSessions
            .Include(s => s.Room)
            .FirstOrDefaultAsync(s => s.Id == sessionId);

        if (session == null)
        {
            return TypedResults.NotFound();
        }

        try
        {
            session.StartSession();
            if (session.Room != null)
            {
                session.Room.Status = RoomStatus.Occupied;
            }
            await context.SaveChangesAsync();
            return TypedResults.Ok(session);
        }
        catch (InvalidOperationException ex)
        {
            return TypedResults.BadRequest<ProblemDetails>(new()
            {
                Detail = ex.Message
            });
        }
    }

    public static async Task<Results<Ok<RoomSession>, NotFound, BadRequest<ProblemDetails>>> EndSession(
        RoomsContext context,
        [Description("The session ID")] int sessionId)
    {
        var session = await context.RoomSessions
            .Include(s => s.Room)
            .FirstOrDefaultAsync(s => s.Id == sessionId);

        if (session == null)
        {
            return TypedResults.NotFound();
        }

        try
        {
            var hourlyRate = session.Room?.HourlyRate ?? 0;
            session.EndSession(hourlyRate);
            if (session.Room != null)
            {
                session.Room.Status = RoomStatus.Available;
            }
            await context.SaveChangesAsync();
            return TypedResults.Ok(session);
        }
        catch (InvalidOperationException ex)
        {
            return TypedResults.BadRequest<ProblemDetails>(new()
            {
                Detail = ex.Message
            });
        }
    }

    public static async Task<Results<Ok<RoomSession>, NotFound, BadRequest<ProblemDetails>>> CancelSession(
        RoomsContext context,
        [Description("The session ID")] int sessionId)
    {
        var session = await context.RoomSessions
            .Include(s => s.Room)
            .FirstOrDefaultAsync(s => s.Id == sessionId);

        if (session == null)
        {
            return TypedResults.NotFound();
        }

        try
        {
            session.CancelSession();
            if (session.Room != null)
            {
                session.Room.Status = RoomStatus.Available;
            }
            await context.SaveChangesAsync();
            return TypedResults.Ok(session);
        }
        catch (InvalidOperationException ex)
        {
            return TypedResults.BadRequest<ProblemDetails>(new()
            {
                Detail = ex.Message
            });
        }
    }

    public static async Task<Ok<List<RoomSession>>> GetActiveSessions(RoomsContext context)
    {
        var sessions = await context.RoomSessions
            .Include(s => s.Room)
            .Where(s => s.Status == SessionStatus.Active || s.Status == SessionStatus.Reserved)
            .OrderBy(s => s.ReservationTime)
            .ToListAsync();
        return TypedResults.Ok(sessions);
    }

    public static async Task<Ok<List<RoomSession>>> GetCustomerSessions(
        RoomsContext context,
        [Description("The customer ID")] string customerId)
    {
        var sessions = await context.RoomSessions
            .Include(s => s.Room)
            .Where(s => s.CustomerId == customerId)
            .OrderByDescending(s => s.ReservationTime)
            .ToListAsync();
        return TypedResults.Ok(sessions);
    }

    public static async Task<Results<Ok<RoomSession>, NotFound>> GetSessionById(
        RoomsContext context,
        [Description("The session ID")] int sessionId)
    {
        var session = await context.RoomSessions
            .Include(s => s.Room)
            .FirstOrDefaultAsync(s => s.Id == sessionId);

        if (session == null)
        {
            return TypedResults.NotFound();
        }

        return TypedResults.Ok(session);
    }
}

public record ReserveRoomRequest(
    string CustomerId,
    string? CustomerName = null,
    string? Notes = null
);
