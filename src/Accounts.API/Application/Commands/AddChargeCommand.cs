using System.Runtime.Serialization;
using MediatR;

namespace Chillax.Accounts.API.Application.Commands;

[DataContract]
public class AddChargeCommand : IRequest<bool>
{
    [DataMember]
    public string CustomerId { get; private set; } = string.Empty;

    [DataMember]
    public string? CustomerName { get; private set; }

    [DataMember]
    public decimal Amount { get; private set; }

    [DataMember]
    public string? Description { get; private set; }

    [DataMember]
    public string AddedBy { get; private set; } = string.Empty;

    public AddChargeCommand(
        string customerId,
        string? customerName,
        decimal amount,
        string? description,
        string addedBy)
    {
        CustomerId = customerId;
        CustomerName = customerName;
        Amount = amount;
        Description = description;
        AddedBy = addedBy;
    }
}
