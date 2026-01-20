namespace Chillax.Rooms.Domain.Exceptions;

/// <summary>
/// Exception thrown when a domain rule is violated
/// </summary>
public class RoomsDomainException : Exception
{
    public RoomsDomainException()
    { }

    public RoomsDomainException(string message)
        : base(message)
    { }

    public RoomsDomainException(string message, Exception innerException)
        : base(message, innerException)
    { }
}
