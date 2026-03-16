namespace Chillax.Branch.API.Model;

public class Branch
{
    public int Id { get; set; }
    public LocalizedText Name { get; set; } = new();
    public LocalizedText? Address { get; set; }
    public string? Phone { get; set; }
    public bool IsActive { get; set; } = true;
    public int DisplayOrder { get; set; }
    public TimeOnly DayStartTime { get; set; } = new(17, 0);
    public TimeOnly DayEndTime { get; set; } = new(5, 0);
    public bool IsOrderingEnabled { get; set; } = true;
    public bool IsReservationsEnabled { get; set; } = true;
}
