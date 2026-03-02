namespace Chillax.Notification.API.Model;

public class ServiceRequest
{
    public int Id { get; set; }
    public string UserId { get; set; } = string.Empty;
    public string UserName { get; set; } = string.Empty;
    public int SessionId { get; set; }
    public int RoomId { get; set; }
    public int BranchId { get; set; }
    public LocalizedText RoomName { get; set; } = new LocalizedText(string.Empty);
    public ServiceRequestType RequestType { get; set; }
    public ServiceRequestStatus Status { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? AcknowledgedAt { get; set; }
    public string? AcknowledgedBy { get; set; }
}

public enum ServiceRequestType
{
    CallWaiter = 1,
    ControllerChange = 2,
    ReceiptToPay = 3
}

public enum ServiceRequestStatus
{
    Pending = 1,
    Acknowledged = 2,
    Completed = 3
}
