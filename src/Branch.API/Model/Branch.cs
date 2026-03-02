namespace Chillax.Branch.API.Model;

public class Branch
{
    public int Id { get; set; }
    public LocalizedText Name { get; set; } = new();
    public LocalizedText? Address { get; set; }
    public string? Phone { get; set; }
    public bool IsActive { get; set; } = true;
    public int DisplayOrder { get; set; }
}
