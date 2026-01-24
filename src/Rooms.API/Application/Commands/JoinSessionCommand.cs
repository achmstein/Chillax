using System.Runtime.Serialization;
using MediatR;

namespace Chillax.Rooms.API.Application.Commands;

/// <summary>
/// Command for a customer to join an active session via access code.
/// </summary>
[DataContract]
public class JoinSessionCommand : IRequest<JoinSessionResult>
{
    [DataMember]
    public string AccessCode { get; private set; }

    [DataMember]
    public string CustomerId { get; private set; }

    [DataMember]
    public string? CustomerName { get; private set; }

    public JoinSessionCommand(string accessCode, string customerId, string? customerName)
    {
        AccessCode = accessCode;
        CustomerId = customerId;
        CustomerName = customerName;
    }
}

public record JoinSessionResult(
    int ReservationId,
    int RoomId,
    string RoomName,
    bool IsOwner,
    DateTime StartTime);
