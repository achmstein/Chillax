namespace Chillax.Accounts.API.Application.Queries;

public interface IAccountQueries
{
    Task<AccountViewModel?> GetAccountByCustomerIdAsync(string customerId);
    Task<IEnumerable<TransactionViewModel>> GetTransactionsByCustomerIdAsync(string customerId, int? limit = null);
    Task<IEnumerable<AccountSummaryViewModel>> GetAllAccountsAsync();
    Task<IEnumerable<AccountSummaryViewModel>> SearchAccountsAsync(string? searchTerm);
}
