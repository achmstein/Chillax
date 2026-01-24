namespace Chillax.Accounts.Infrastructure.EntityConfigurations;

class AccountTransactionEntityTypeConfiguration : IEntityTypeConfiguration<AccountTransaction>
{
    public void Configure(EntityTypeBuilder<AccountTransaction> builder)
    {
        builder.ToTable("account_transactions");

        builder.HasKey(t => t.Id);

        builder.Property(t => t.Id)
            .UseHiLo("accounttransactionseq", "accounts");

        builder.Ignore(t => t.DomainEvents);

        builder.Property(t => t.CustomerAccountId)
            .IsRequired();

        builder.Property(t => t.Type)
            .HasConversion<int>()
            .IsRequired();

        builder.Property(t => t.Amount)
            .HasPrecision(18, 2)
            .IsRequired();

        builder.Property(t => t.Description)
            .HasMaxLength(500);

        builder.Property(t => t.RecordedBy)
            .HasMaxLength(200)
            .IsRequired();

        builder.Property(t => t.CreatedAt)
            .IsRequired();

        builder.HasIndex(t => t.CustomerAccountId);
        builder.HasIndex(t => t.CreatedAt);
    }
}
