using System.Runtime.Serialization;
using MediatR;

namespace Chillax.Rooms.API.Application.Commands;

/// <summary>
/// Command to start a walk-in session without an assigned customer.
/// The first customer to join via access code becomes the owner.
/// </summary>
[DataContract]
public class StartWalkInSessionCommand : IRequest<StartWalkInSessionResult>
{
    [DataMember]
    public int RoomId { get; private set; }

    [DataMember]
    public string? Notes { get; private set; }

    public StartWalkInSessionCommand(int roomId, string? notes = null)
    {
        RoomId = roomId;
        Notes = notes;
    }
}

public record StartWalkInSessionResult(int ReservationId, string AccessCode);
