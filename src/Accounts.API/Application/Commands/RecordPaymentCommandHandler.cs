using Chillax.Accounts.Domain.AggregatesModel.CustomerAccountAggregate;
using Chillax.Accounts.Domain.Exceptions;
using MediatR;
using Microsoft.Extensions.Logging;

namespace Chillax.Accounts.API.Application.Commands;

public class RecordPaymentCommandHandler : IRequestHandler<RecordPaymentCommand, bool>
{
    private readonly ICustomerAccountRepository _accountRepository;
    private readonly ILogger<RecordPaymentCommandHandler> _logger;

    public RecordPaymentCommandHandler(
        ICustomerAccountRepository accountRepository,
        ILogger<RecordPaymentCommandHandler> logger)
    {
        _accountRepository = accountRepository;
        _logger = logger;
    }

    public async Task<bool> Handle(RecordPaymentCommand request, CancellationToken cancellationToken)
    {
        var account = await _accountRepository.GetWithTransactionsByCustomerIdAsync(request.CustomerId);

        if (account == null)
            throw new AccountsDomainException($"Account not found for customer {request.CustomerId}");

        account.RecordPayment(request.Amount, request.Description, request.RecordedBy);

        _logger.LogInformation("Recording payment of {Amount} for customer {CustomerId} by {RecordedBy}",
            request.Amount, request.CustomerId, request.RecordedBy);

        await _accountRepository.UnitOfWork.SaveEntitiesAsync(cancellationToken);

        return true;
    }
}
