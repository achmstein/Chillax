using System.Runtime.Serialization;
using MediatR;

namespace Chillax.Rooms.API.Application.Commands;

[DataContract]
public class CreateReservationCommand : IRequest<int>
{
    [DataMember]
    public int RoomId { get; private set; }

    [DataMember]
    public string CustomerId { get; private set; } = string.Empty;

    [DataMember]
    public string? CustomerName { get; private set; }

    [DataMember]
    public DateTime ScheduledStartTime { get; private set; }

    [DataMember]
    public string? Notes { get; private set; }

    public CreateReservationCommand(
        int roomId,
        string customerId,
        string? customerName,
        DateTime scheduledStartTime,
        string? notes = null)
    {
        RoomId = roomId;
        CustomerId = customerId;
        CustomerName = customerName;
        ScheduledStartTime = scheduledStartTime;
        Notes = notes;
    }
}
