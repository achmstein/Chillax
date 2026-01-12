using System.ComponentModel.DataAnnotations;

namespace Chillax.Loyalty.API.Model;

/// <summary>
/// Represents a points transaction (earn or redeem)
/// </summary>
public class PointsTransaction
{
    public int Id { get; set; }

    /// <summary>
    /// The loyalty account this transaction belongs to
    /// </summary>
    public int AccountId { get; set; }

    /// <summary>
    /// Navigation property to the account
    /// </summary>
    public LoyaltyAccount? Account { get; set; }

    /// <summary>
    /// Points amount (positive = earned, negative = redeemed)
    /// </summary>
    public int Points { get; set; }

    /// <summary>
    /// Transaction type (order, redemption, bonus, adjustment)
    /// </summary>
    [Required]
    public string Type { get; set; } = "";

    /// <summary>
    /// Optional reference ID (e.g., Order ID)
    /// </summary>
    public string? ReferenceId { get; set; }

    /// <summary>
    /// Description of the transaction
    /// </summary>
    [Required]
    public string Description { get; set; } = "";

    /// <summary>
    /// When the transaction occurred
    /// </summary>
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
