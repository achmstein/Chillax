using System.Runtime.Serialization;
using Chillax.Rooms.Domain.AggregatesModel.ReservationAggregate;
using MediatR;

namespace Chillax.Rooms.API.Application.Commands;

[DataContract]
public class StartSessionCommand : IRequest<bool>
{
    [DataMember]
    public int ReservationId { get; private set; }

    [DataMember]
    public PlayerMode InitialMode { get; private set; }

    public StartSessionCommand(int reservationId, PlayerMode initialMode = PlayerMode.Single)
    {
        ReservationId = reservationId;
        InitialMode = initialMode;
    }
}
