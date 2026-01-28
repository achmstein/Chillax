#nullable enable
namespace Chillax.Ordering.API.Application.Queries;

public record Orderitem
{
    public string ProductName { get; init; } = string.Empty;
    public int Units { get; init; }
    public double UnitPrice { get; init; }
    public string PictureUrl { get; init; } = string.Empty;
    public string? CustomizationsDescription { get; init; }
    public string? SpecialInstructions { get; init; }
}

/// <summary>
/// Simplified order view model for cafe orders.
/// No address or payment information needed.
/// </summary>
public record Order
{
    public int OrderNumber { get; init; }
    public DateTime Date { get; init; }
    public string Status { get; init; } = string.Empty;
    public string? Description { get; init; }
    public string? RoomName { get; init; }
    public string? CustomerNote { get; init; }
    public List<Orderitem> OrderItems { get; set; } = new();
    public decimal Total { get; set; }
}

public record OrderSummary
{
    public int OrderNumber { get; init; }
    public DateTime Date { get; init; }
    public string Status { get; init; } = string.Empty;
    public double Total { get; init; }
    public string? RoomName { get; init; }
}
