using System.Runtime.Serialization;
using MediatR;

namespace Chillax.Rooms.API.Application.Commands;

[DataContract]
public class StartSessionCommand : IRequest<bool>
{
    [DataMember]
    public int ReservationId { get; private set; }

    public StartSessionCommand(int reservationId)
    {
        ReservationId = reservationId;
    }
}
