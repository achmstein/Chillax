using Chillax.Accounts.Domain.Exceptions;
using Chillax.Accounts.Domain.SeedWork;

namespace Chillax.Accounts.Domain.AggregatesModel.CustomerAccountAggregate;

public class AccountTransaction : Entity
{
    public int CustomerAccountId { get; private set; }
    public TransactionType Type { get; private set; }
    public decimal Amount { get; private set; }
    public string? Description { get; private set; }
    public string RecordedBy { get; private set; }
    public DateTime CreatedAt { get; private set; }

    protected AccountTransaction()
    {
        RecordedBy = string.Empty;
    }

    internal AccountTransaction(
        int customerAccountId,
        TransactionType type,
        decimal amount,
        string? description,
        string recordedBy) : this()
    {
        if (amount <= 0)
            throw new AccountsDomainException("Transaction amount must be greater than zero");

        if (string.IsNullOrWhiteSpace(recordedBy))
            throw new AccountsDomainException("RecordedBy is required");

        CustomerAccountId = customerAccountId;
        Type = type;
        Amount = amount;
        Description = description;
        RecordedBy = recordedBy;
        CreatedAt = DateTime.UtcNow;
    }
}
