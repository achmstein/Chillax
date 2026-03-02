namespace Chillax.Branch.API.Model;

public class AdminBranchAssignment
{
    public int Id { get; set; }
    public string AdminUserId { get; set; } = string.Empty;
    public int BranchId { get; set; }
    public Branch Branch { get; set; } = null!;
}
