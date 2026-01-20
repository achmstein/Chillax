using System.ComponentModel;
using Chillax.Rooms.API.Application.Commands;
using Chillax.Rooms.API.Application.Queries;
using Chillax.Rooms.Domain.AggregatesModel.RoomAggregate;
using Chillax.Rooms.Domain.Exceptions;
using Chillax.Rooms.Infrastructure;
using Chillax.ServiceDefaults;
using MediatR;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

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
            .WithDescription("Create a reservation for a room (same day only)")
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

        var customerName = httpContext.User.GetUserName() ?? request?.CustomerName;
        var scheduledTime = request?.ScheduledStartTime ?? DateTime.UtcNow;

        try
        {
            var command = new CreateReservationCommand(
                roomId,
                customerId,
                customerName,
                scheduledTime,
                request?.Notes);

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
}

public record ReserveRoomRequest(
    DateTime? ScheduledStartTime = null,
    string? CustomerName = null,
    string? Notes = null
);
