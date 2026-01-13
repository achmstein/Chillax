using System.ComponentModel;
using Chillax.EventBus.Abstractions;
using Chillax.Rooms.API.Dtos;
using Chillax.Rooms.API.Infrastructure;
using Chillax.Rooms.API.IntegrationEvents.Events;
using Chillax.Rooms.API.Model;
using Chillax.ServiceDefaults;
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

        api.MapGet("/{id:int}/pic", GetRoomPictureById)
            .WithName("GetRoomPicture")
            .WithSummary("Get room picture")
            .WithDescription("Get the picture for a room")
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

        api.MapPost("/", CreateRoom)
            .WithName("CreateRoom")
            .WithSummary("Create a room")
            .WithDescription("Create a new PlayStation room (Admin only)")
            .WithTags("Rooms")
            .RequireAuthorization();

        api.MapPut("/{id:int}", UpdateRoom)
            .WithName("UpdateRoom")
            .WithSummary("Update a room")
            .WithDescription("Update an existing room's details (Admin only)")
            .WithTags("Rooms")
            .RequireAuthorization();

        api.MapDelete("/{id:int}", DeleteRoom)
            .WithName("DeleteRoom")
            .WithSummary("Delete a room")
            .WithDescription("Delete a room (Admin only). Cannot delete rooms with active sessions.")
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

        api.MapGet("/sessions/my", GetMySessions)
            .WithName("GetMySessions")
            .WithSummary("Get my sessions")
            .WithDescription("Get all sessions for the current authenticated user")
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
    public static async Task<Ok<List<RoomDto>>> GetAllRooms(RoomsContext context)
    {
        var rooms = await context.Rooms
            .OrderBy(r => r.Name)
            .ToListAsync();
        return TypedResults.Ok(rooms.ToDtoList());
    }

    public static async Task<Results<Ok<RoomDto>, NotFound>> GetRoomById(
        RoomsContext context,
        [Description("The room ID")] int id)
    {
        var room = await context.Rooms.FindAsync(id);

        if (room == null)
        {
            return TypedResults.NotFound();
        }

        return TypedResults.Ok(room.ToDto());
    }

    [ProducesResponseType<byte[]>(StatusCodes.Status200OK, "image/webp",
        ["image/png", "image/gif", "image/jpeg", "image/bmp", "image/tiff",
          "image/wmf", "image/jp2", "image/svg+xml", "image/webp"])]
    public static async Task<Results<PhysicalFileHttpResult, NotFound>> GetRoomPictureById(
        RoomsContext context,
        IWebHostEnvironment environment,
        [Description("The room id")] int id)
    {
        var room = await context.Rooms.FindAsync(id);

        if (room is null || room.PictureFileName is null)
        {
            return TypedResults.NotFound();
        }

        var path = RoomsApiHelpers.GetFullPath(environment.ContentRootPath, room.PictureFileName);

        if (!File.Exists(path))
        {
            return TypedResults.NotFound();
        }

        string imageFileExtension = Path.GetExtension(room.PictureFileName) ?? string.Empty;
        string mimetype = RoomsApiHelpers.GetImageMimeTypeFromImageFileExtension(imageFileExtension);
        DateTime lastModified = File.GetLastWriteTimeUtc(path);

        return TypedResults.PhysicalFile(path, mimetype, lastModified: lastModified);
    }

    public static async Task<Ok<List<RoomDto>>> GetAvailableRooms(RoomsContext context)
    {
        var rooms = await context.Rooms
            .Where(r => r.Status == RoomStatus.Available)
            .OrderBy(r => r.Name)
            .ToListAsync();
        return TypedResults.Ok(rooms.ToDtoList());
    }

    public static async Task<Results<Ok<RoomDto>, NotFound>> UpdateRoomStatus(
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

        return TypedResults.Ok(room.ToDto());
    }

    public static async Task<Created<RoomDto>> CreateRoom(
        RoomsContext context,
        CreateRoomRequest request)
    {
        var room = new Room(request.Name)
        {
            Description = request.Description,
            HourlyRate = request.HourlyRate,
            Status = RoomStatus.Available,
            PictureFileName = request.PictureFileName
        };

        context.Rooms.Add(room);
        await context.SaveChangesAsync();

        return TypedResults.Created($"/api/rooms/{room.Id}", room.ToDto());
    }

    public static async Task<Results<Ok<RoomDto>, NotFound>> UpdateRoom(
        RoomsContext context,
        [Description("The room ID")] int id,
        UpdateRoomRequest request)
    {
        var room = await context.Rooms.FindAsync(id);

        if (room == null)
        {
            return TypedResults.NotFound();
        }

        room.Name = request.Name;
        room.Description = request.Description;
        room.HourlyRate = request.HourlyRate;
        if (request.PictureFileName != null)
        {
            room.PictureFileName = request.PictureFileName;
        }

        await context.SaveChangesAsync();

        return TypedResults.Ok(room.ToDto());
    }

    public static async Task<Results<NoContent, NotFound, BadRequest<ProblemDetails>>> DeleteRoom(
        RoomsContext context,
        [Description("The room ID")] int id)
    {
        var room = await context.Rooms
            .Include(r => r.Sessions)
            .FirstOrDefaultAsync(r => r.Id == id);

        if (room == null)
        {
            return TypedResults.NotFound();
        }

        // Check for active sessions
        var hasActiveSessions = room.Sessions.Any(s =>
            s.Status == SessionStatus.Active || s.Status == SessionStatus.Reserved);

        if (hasActiveSessions)
        {
            return TypedResults.BadRequest<ProblemDetails>(new()
            {
                Detail = "Cannot delete room with active or reserved sessions"
            });
        }

        context.Rooms.Remove(room);
        await context.SaveChangesAsync();

        return TypedResults.NoContent();
    }

    // Reservation endpoints
    public static async Task<Results<Created<RoomSessionDto>, NotFound, BadRequest<ProblemDetails>>> ReserveRoom(
        RoomsContext context,
        HttpContext httpContext,
        [Description("The room ID to reserve")] int roomId,
        ReserveRoomRequest? request = null)
    {
        var customerId = httpContext.User.GetUserId();
        if (string.IsNullOrEmpty(customerId))
        {
            return TypedResults.BadRequest<ProblemDetails>(new()
            {
                Detail = "User ID not found in token"
            });
        }

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

        var customerName = httpContext.User.GetUserName() ?? request?.CustomerName;

        var session = new RoomSession(customerId)
        {
            RoomId = roomId,
            Room = room,
            CustomerName = customerName,
            Notes = request?.Notes,
            Status = SessionStatus.Reserved
        };

        room.Status = RoomStatus.Reserved;

        context.RoomSessions.Add(session);
        await context.SaveChangesAsync();

        return TypedResults.Created($"/api/rooms/sessions/{session.Id}", session.ToDto());
    }

    // Session endpoints
    public static async Task<Results<Ok<RoomSessionDto>, NotFound, BadRequest<ProblemDetails>>> StartSession(
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
            return TypedResults.Ok(session.ToDto());
        }
        catch (InvalidOperationException ex)
        {
            return TypedResults.BadRequest<ProblemDetails>(new()
            {
                Detail = ex.Message
            });
        }
    }

    public static async Task<Results<Ok<RoomSessionDto>, NotFound, BadRequest<ProblemDetails>>> EndSession(
        RoomsContext context,
        IEventBus eventBus,
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
                await context.SaveChangesAsync();

                // Publish event to notify subscribers that a room is available
                await eventBus.PublishAsync(new RoomBecameAvailableIntegrationEvent(
                    session.Room.Id, session.Room.Name));
            }
            else
            {
                await context.SaveChangesAsync();
            }
            return TypedResults.Ok(session.ToDto());
        }
        catch (InvalidOperationException ex)
        {
            return TypedResults.BadRequest<ProblemDetails>(new()
            {
                Detail = ex.Message
            });
        }
    }

    public static async Task<Results<Ok<RoomSessionDto>, NotFound, BadRequest<ProblemDetails>>> CancelSession(
        RoomsContext context,
        IEventBus eventBus,
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
                await context.SaveChangesAsync();

                // Publish event to notify subscribers that a room is available
                await eventBus.PublishAsync(new RoomBecameAvailableIntegrationEvent(
                    session.Room.Id, session.Room.Name));
            }
            else
            {
                await context.SaveChangesAsync();
            }
            return TypedResults.Ok(session.ToDto());
        }
        catch (InvalidOperationException ex)
        {
            return TypedResults.BadRequest<ProblemDetails>(new()
            {
                Detail = ex.Message
            });
        }
    }

    public static async Task<Ok<List<RoomSessionDto>>> GetMySessions(
        RoomsContext context,
        HttpContext httpContext)
    {
        var customerId = httpContext.User.GetUserId();
        var sessions = await context.RoomSessions
            .Include(s => s.Room)
            .Where(s => s.CustomerId == customerId)
            .OrderByDescending(s => s.ReservationTime)
            .ToListAsync();
        return TypedResults.Ok(sessions.ToDtoList());
    }

    public static async Task<Ok<List<RoomSessionDto>>> GetActiveSessions(RoomsContext context)
    {
        var sessions = await context.RoomSessions
            .Include(s => s.Room)
            .Where(s => s.Status == SessionStatus.Active || s.Status == SessionStatus.Reserved)
            .OrderBy(s => s.ReservationTime)
            .ToListAsync();
        return TypedResults.Ok(sessions.ToDtoList());
    }

    public static async Task<Ok<List<RoomSessionDto>>> GetCustomerSessions(
        RoomsContext context,
        [Description("The customer ID")] string customerId)
    {
        var sessions = await context.RoomSessions
            .Include(s => s.Room)
            .Where(s => s.CustomerId == customerId)
            .OrderByDescending(s => s.ReservationTime)
            .ToListAsync();
        return TypedResults.Ok(sessions.ToDtoList());
    }

    public static async Task<Results<Ok<RoomSessionDto>, NotFound>> GetSessionById(
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

        return TypedResults.Ok(session.ToDto());
    }
}

public record ReserveRoomRequest(
    string? CustomerName = null,
    string? Notes = null
);

public record CreateRoomRequest(
    string Name,
    string? Description = null,
    decimal HourlyRate = 0,
    string? PictureFileName = null
);

public record UpdateRoomRequest(
    string Name,
    string? Description = null,
    decimal HourlyRate = 0,
    string? PictureFileName = null
);

public static partial class RoomsApiHelpers
{
    public static string GetImageMimeTypeFromImageFileExtension(string extension) => extension switch
    {
        ".png" => "image/png",
        ".gif" => "image/gif",
        ".jpg" or ".jpeg" => "image/jpeg",
        ".bmp" => "image/bmp",
        ".tiff" => "image/tiff",
        ".wmf" => "image/wmf",
        ".jp2" => "image/jp2",
        ".svg" => "image/svg+xml",
        ".webp" => "image/webp",
        _ => "application/octet-stream",
    };

    public static string GetFullPath(string contentRootPath, string pictureFileName) =>
        Path.Combine(contentRootPath, "Pics", pictureFileName);
}
