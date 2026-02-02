using System.ComponentModel;
using Chillax.Rooms.API.Application.Commands;
using Chillax.Rooms.API.Application.Queries;
using Chillax.Rooms.Domain.AggregatesModel.ReservationAggregate;
using Chillax.Rooms.Domain.AggregatesModel.RoomAggregate;
using Chillax.Rooms.Domain.Exceptions;
using Chillax.Rooms.Domain.SeedWork;
using Room = Chillax.Rooms.Domain.AggregatesModel.RoomAggregate.Room;
using MediatR;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RoomsContext = Chillax.Rooms.Infrastructure.RoomsContext;

namespace Chillax.Rooms.API.Apis;

public static class RoomsApi
{
    public static IEndpointRouteBuilder MapRoomsApi(this IEndpointRouteBuilder app)
    {
        var api = app.MapGroup("api/rooms");

        // Room endpoints (queries)
        api.MapGet("/", GetAllRooms)
            .WithName("ListRooms")
            .WithSummary("List all rooms")
            .WithDescription("Get all PlayStation rooms with their current display status")
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

        // Admin room management
        api.MapPost("/", CreateRoom)
            .WithName("CreateRoom")
            .WithSummary("Create a new room")
            .WithDescription("Create a new PlayStation room (Admin only)")
            .WithTags("Rooms")
            .RequireAuthorization();

        api.MapPut("/{id:int}", UpdateRoom)
            .WithName("UpdateRoom")
            .WithSummary("Update room details")
            .WithDescription("Update room name, description, and hourly rate (Admin only)")
            .WithTags("Rooms")
            .RequireAuthorization();

        api.MapDelete("/{id:int}", DeleteRoom)
            .WithName("DeleteRoom")
            .WithSummary("Delete a room")
            .WithDescription("Delete a room (Admin only)")
            .WithTags("Rooms")
            .RequireAuthorization();

        api.MapPut("/{id:int}/status", UpdateRoomStatus)
            .WithName("UpdateRoomStatus")
            .WithSummary("Update room physical status")
            .WithDescription("Update the physical status of a room (Admin only)")
            .WithTags("Rooms")
            .RequireAuthorization();

        // Reservation endpoints (commands)
        api.MapPost("/{roomId:int}/reserve", CreateReservation)
            .WithName("ReserveRoom")
            .WithSummary("Reserve a room")
            .WithDescription("Create an immediate reservation for a room. Customer has 15 minutes to arrive before auto-cancellation.")
            .WithTags("Reservations")
            .RequireAuthorization();

        // Session endpoints (Admin commands)
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

        // Walk-in session endpoints (Admin)
        api.MapPost("/sessions/walk-in/{roomId:int}", StartWalkInSession)
            .WithName("StartWalkInSession")
            .WithSummary("Start a walk-in session")
            .WithDescription("Start a walk-in session without an assigned customer. Returns access code for customers to join.")
            .WithTags("Sessions")
            .RequireAuthorization();

        // Session membership endpoints (Customer)
        api.MapPost("/sessions/join", JoinSession)
            .WithName("JoinSession")
            .WithSummary("Join a session")
            .WithDescription("Join an active session using the 6-digit access code")
            .WithTags("Sessions")
            .RequireAuthorization();

        api.MapPost("/sessions/{sessionId:int}/leave", LeaveSession)
            .WithName("LeaveSession")
            .WithSummary("Leave a session")
            .WithDescription("Leave a session you've joined (cannot leave if you're the owner)")
            .WithTags("Sessions")
            .RequireAuthorization();

        api.MapGet("/sessions/by-code/{code}", GetSessionByCode)
            .WithName("GetSessionByCode")
            .WithSummary("Preview session by access code")
            .WithDescription("Get session preview before joining")
            .WithTags("Sessions")
            .RequireAuthorization();

        // Session query endpoints
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

        api.MapGet("/sessions/{sessionId:int}", GetSessionById)
            .WithName("GetSession")
            .WithSummary("Get session by ID")
            .WithDescription("Get a specific session by its ID")
            .WithTags("Sessions")
            .RequireAuthorization();

        api.MapGet("/{roomId:int}/sessions/history", GetRoomSessionHistory)
            .WithName("GetRoomSessionHistory")
            .WithSummary("Get room session history")
            .WithDescription("Get completed sessions history for a specific room")
            .WithTags("Sessions")
            .RequireAuthorization();

        return app;
    }

    // Query endpoints
    public static async Task<Ok<IEnumerable<RoomViewModel>>> GetAllRooms(
        [FromServices] IRoomQueries queries)
    {
        var rooms = await queries.GetAllRoomsAsync();
        return TypedResults.Ok(rooms);
    }

    public static async Task<Results<Ok<RoomViewModel>, NotFound>> GetRoomById(
        [FromServices] IRoomQueries queries,
        [Description("The room ID")] int id)
    {
        var room = await queries.GetRoomByIdAsync(id);

        if (room == null)
        {
            return TypedResults.NotFound();
        }

        return TypedResults.Ok(room);
    }

    public static async Task<Ok<IEnumerable<RoomViewModel>>> GetAvailableRooms(
        [FromServices] IRoomQueries queries)
    {
        var rooms = await queries.GetAvailableRoomsAsync();
        return TypedResults.Ok(rooms);
    }

    public static async Task<Created<int>> CreateRoom(
        RoomsContext context,
        CreateRoomRequest request)
    {
        var room = new Room(request.Name, request.HourlyRate, request.Description);
        context.Rooms.Add(room);
        await context.SaveChangesAsync();
        return TypedResults.Created($"/api/rooms/{room.Id}", room.Id);
    }

    public static async Task<Results<Ok, NotFound>> UpdateRoom(
        RoomsContext context,
        [Description("The room ID")] int id,
        UpdateRoomRequest request)
    {
        var room = await context.Rooms.FindAsync(id);
        if (room == null)
        {
            return TypedResults.NotFound();
        }

        room.UpdateDetails(request.Name, request.Description, request.HourlyRate);
        await context.SaveChangesAsync();
        return TypedResults.Ok();
    }

    public static async Task<Results<Ok, NotFound, BadRequest<ProblemDetails>>> DeleteRoom(
        RoomsContext context,
        [Description("The room ID")] int id)
    {
        var room = await context.Rooms.FindAsync(id);
        if (room == null)
        {
            return TypedResults.NotFound();
        }

        // Check if room has active sessions
        var hasActiveSessions = await context.Reservations
            .AnyAsync(r => r.RoomId == id && (r.Status == ReservationStatus.Active || r.Status == ReservationStatus.Reserved));

        if (hasActiveSessions)
        {
            return TypedResults.BadRequest<ProblemDetails>(new() { Detail = "Cannot delete room with active sessions" });
        }

        context.Rooms.Remove(room);
        await context.SaveChangesAsync();
        return TypedResults.Ok();
    }

    public static async Task<Results<Ok, NotFound, BadRequest<ProblemDetails>>> UpdateRoomStatus(
        RoomsContext context,
        [Description("The room ID")] int id,
        [Description("The new physical status")] RoomPhysicalStatus status)
    {
        var room = await context.Rooms.FindAsync(id);

        if (room == null)
        {
            return TypedResults.NotFound();
        }

        try
        {
            switch (status)
            {
                case RoomPhysicalStatus.Available:
                    room.SetAvailable();
                    break;
                case RoomPhysicalStatus.Occupied:
                    room.SetOccupied();
                    break;
                case RoomPhysicalStatus.Maintenance:
                    room.SetMaintenance();
                    break;
            }
            await context.SaveChangesAsync();
            return TypedResults.Ok();
        }
        catch (RoomsDomainException ex)
        {
            return TypedResults.BadRequest<ProblemDetails>(new() { Detail = ex.Message });
        }
    }

    // Command endpoints
    public static async Task<Results<Created<int>, BadRequest<ProblemDetails>>> CreateReservation(
        [FromServices] IMediator mediator,
        [FromServices] ILoggerFactory loggerFactory,
        HttpContext httpContext,
        [Description("The room ID to reserve")] int roomId,
        ReserveRoomRequest? request = null)
    {
        var logger = loggerFactory.CreateLogger("RoomsApi");

        var customerId = httpContext.User.GetUserId();
        if (string.IsNullOrEmpty(customerId))
        {
            return TypedResults.BadRequest<ProblemDetails>(new()
            {
                Detail = "User ID not found in token"
            });
        }

        var customerName = httpContext.User.GetUserName() ?? request?.CustomerName;
        var roles = httpContext.User.GetRoles().ToList();
        var isAdmin = roles.Contains("Admin", StringComparer.OrdinalIgnoreCase);

        logger.LogInformation("CreateReservation API: CustomerId={CustomerId}, Roles=[{Roles}], IsAdmin={IsAdmin}",
            customerId, string.Join(", ", roles), isAdmin);

        try
        {
            var command = new CreateReservationCommand(
                roomId,
                customerId,
                customerName,
                request?.Notes,
                isAdmin);

            var reservationId = await mediator.Send(command);
            return TypedResults.Created($"/api/rooms/sessions/{reservationId}", reservationId);
        }
        catch (RoomsDomainException ex)
        {
            return TypedResults.BadRequest<ProblemDetails>(new() { Detail = ex.Message });
        }
    }

    public static async Task<Results<Ok, NotFound, BadRequest<ProblemDetails>>> StartSession(
        [FromServices] IMediator mediator,
        [Description("The session ID")] int sessionId)
    {
        try
        {
            var command = new StartSessionCommand(sessionId);
            var result = await mediator.Send(command);
            return result ? TypedResults.Ok() : TypedResults.NotFound();
        }
        catch (RoomsDomainException ex)
        {
            return TypedResults.BadRequest<ProblemDetails>(new() { Detail = ex.Message });
        }
    }

    public static async Task<Results<Ok, NotFound, BadRequest<ProblemDetails>>> EndSession(
        [FromServices] IMediator mediator,
        [Description("The session ID")] int sessionId)
    {
        try
        {
            var command = new EndSessionCommand(sessionId);
            var result = await mediator.Send(command);
            return result ? TypedResults.Ok() : TypedResults.NotFound();
        }
        catch (RoomsDomainException ex)
        {
            return TypedResults.BadRequest<ProblemDetails>(new() { Detail = ex.Message });
        }
    }

    public static async Task<Results<Ok, NotFound, BadRequest<ProblemDetails>>> CancelSession(
        [FromServices] IMediator mediator,
        [Description("The session ID")] int sessionId)
    {
        try
        {
            var command = new CancelReservationCommand(sessionId);
            var result = await mediator.Send(command);
            return result ? TypedResults.Ok() : TypedResults.NotFound();
        }
        catch (RoomsDomainException ex)
        {
            return TypedResults.BadRequest<ProblemDetails>(new() { Detail = ex.Message });
        }
    }

    public static async Task<Ok<IEnumerable<ReservationViewModel>>> GetMySessions(
        [FromServices] IRoomQueries queries,
        HttpContext httpContext)
    {
        var customerId = httpContext.User.GetUserId();
        var sessions = await queries.GetCustomerReservationsAsync(customerId ?? string.Empty);
        return TypedResults.Ok(sessions);
    }

    public static async Task<Ok<IEnumerable<ReservationViewModel>>> GetActiveSessions(
        [FromServices] IRoomQueries queries)
    {
        var sessions = await queries.GetActiveSessionsAsync();
        return TypedResults.Ok(sessions);
    }

    public static async Task<Results<Ok<ReservationViewModel>, NotFound>> GetSessionById(
        [FromServices] IRoomQueries queries,
        [Description("The session ID")] int sessionId)
    {
        var session = await queries.GetReservationByIdAsync(sessionId);

        if (session == null)
        {
            return TypedResults.NotFound();
        }

        return TypedResults.Ok(session);
    }

    public static async Task<Results<Created<StartWalkInSessionResult>, BadRequest<ProblemDetails>>> StartWalkInSession(
        [FromServices] IMediator mediator,
        [Description("The room ID")] int roomId,
        WalkInSessionRequest? request = null)
    {
        try
        {
            var command = new StartWalkInSessionCommand(roomId, request?.Notes);
            var result = await mediator.Send(command);
            return TypedResults.Created($"/api/rooms/sessions/{result.ReservationId}", result);
        }
        catch (RoomsDomainException ex)
        {
            return TypedResults.BadRequest<ProblemDetails>(new() { Detail = ex.Message });
        }
    }

    public static async Task<Results<Ok<JoinSessionResult>, BadRequest<ProblemDetails>>> JoinSession(
        [FromServices] IMediator mediator,
        HttpContext httpContext,
        JoinSessionRequest request)
    {
        var customerId = httpContext.User.GetUserId();
        if (string.IsNullOrEmpty(customerId))
        {
            return TypedResults.BadRequest<ProblemDetails>(new()
            {
                Detail = "User ID not found in token"
            });
        }

        var customerName = httpContext.User.GetUserName();

        try
        {
            var command = new JoinSessionCommand(request.AccessCode, customerId, customerName);
            var result = await mediator.Send(command);
            return TypedResults.Ok(result);
        }
        catch (RoomsDomainException ex)
        {
            return TypedResults.BadRequest<ProblemDetails>(new() { Detail = ex.Message });
        }
    }

    public static async Task<Results<Ok, NotFound, BadRequest<ProblemDetails>>> LeaveSession(
        [FromServices] IMediator mediator,
        HttpContext httpContext,
        [Description("The session ID")] int sessionId)
    {
        var customerId = httpContext.User.GetUserId();
        if (string.IsNullOrEmpty(customerId))
        {
            return TypedResults.BadRequest<ProblemDetails>(new()
            {
                Detail = "User ID not found in token"
            });
        }

        try
        {
            var command = new LeaveSessionCommand(sessionId, customerId);
            var result = await mediator.Send(command);
            return result ? TypedResults.Ok() : TypedResults.NotFound();
        }
        catch (RoomsDomainException ex)
        {
            return TypedResults.BadRequest<ProblemDetails>(new() { Detail = ex.Message });
        }
    }

    public static async Task<Results<Ok<SessionPreviewViewModel>, NotFound>> GetSessionByCode(
        [FromServices] IRoomQueries queries,
        [Description("The 6-digit access code")] string code)
    {
        var preview = await queries.GetSessionPreviewByCodeAsync(code);
        if (preview == null)
        {
            return TypedResults.NotFound();
        }
        return TypedResults.Ok(preview);
    }

    public static async Task<Ok<IEnumerable<ReservationViewModel>>> GetRoomSessionHistory(
        [FromServices] IRoomQueries queries,
        [Description("The room ID")] int roomId,
        [Description("Maximum number of sessions to return")] int limit = 20)
    {
        var sessions = await queries.GetRoomSessionHistoryAsync(roomId, limit);
        return TypedResults.Ok(sessions);
    }
}

public record ReserveRoomRequest(
    string? CustomerName = null,
    string? Notes = null
);

public record WalkInSessionRequest(string? Notes = null);

public record JoinSessionRequest(string AccessCode);

public record CreateRoomRequest(string Name, string? Description, decimal HourlyRate);

public record UpdateRoomRequest(string Name, string? Description, decimal HourlyRate);
