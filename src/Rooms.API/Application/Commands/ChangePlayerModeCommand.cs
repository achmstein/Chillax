using Chillax.Rooms.Domain.AggregatesModel.ReservationAggregate;
using MediatR;

namespace Chillax.Rooms.API.Application.Commands;

public record ChangePlayerModeCommand(int ReservationId, PlayerMode PlayerMode) : IRequest<bool>;
