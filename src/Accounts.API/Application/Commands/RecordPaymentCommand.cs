using System.Runtime.Serialization;
using MediatR;

namespace Chillax.Accounts.API.Application.Commands;

[DataContract]
public class RecordPaymentCommand : IRequest<bool>
{
    [DataMember]
    public string CustomerId { get; private set; } = string.Empty;

    [DataMember]
    public decimal Amount { get; private set; }

    [DataMember]
    public string? Description { get; private set; }

    [DataMember]
    public string RecordedBy { get; private set; } = string.Empty;

    public RecordPaymentCommand(
        string customerId,
        decimal amount,
        string? description,
        string recordedBy)
    {
        CustomerId = customerId;
        Amount = amount;
        Description = description;
        RecordedBy = recordedBy;
    }
}
