namespace Chillax.Rooms.Domain.AggregatesModel.ReservationAggregate;

/// <summary>
/// Role of a session member
/// </summary>
public enum SessionMemberRole
{
    /// <summary>
    /// Original reservation customer or first walk-in joiner
    /// </summary>
    Owner = 1,

    /// <summary>
    /// Joined via access code
    /// </summary>
    Member = 2
}
