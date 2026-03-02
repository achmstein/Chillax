using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Accounts.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.EnsureSchema(
                name: "accounts");

            migrationBuilder.CreateSequence(
                name: "accounttransactionseq",
                schema: "accounts",
                incrementBy: 10);

            migrationBuilder.CreateSequence(
                name: "customeraccountseq",
                schema: "accounts",
                incrementBy: 10);

            migrationBuilder.CreateTable(
                name: "customer_accounts",
                schema: "accounts",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false),
                    CustomerId = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    CustomerName = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    Balance = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_customer_accounts", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "account_transactions",
                schema: "accounts",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false),
                    CustomerAccountId = table.Column<int>(type: "integer", nullable: false),
                    Type = table.Column<int>(type: "integer", nullable: false),
                    Amount = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false),
                    Description = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    RecordedBy = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_account_transactions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_account_transactions_customer_accounts_CustomerAccountId",
                        column: x => x.CustomerAccountId,
                        principalSchema: "accounts",
                        principalTable: "customer_accounts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_account_transactions_CreatedAt",
                schema: "accounts",
                table: "account_transactions",
                column: "CreatedAt");

            migrationBuilder.CreateIndex(
                name: "IX_account_transactions_CustomerAccountId",
                schema: "accounts",
                table: "account_transactions",
                column: "CustomerAccountId");

            migrationBuilder.CreateIndex(
                name: "IX_customer_accounts_Balance",
                schema: "accounts",
                table: "customer_accounts",
                column: "Balance");

            migrationBuilder.CreateIndex(
                name: "IX_customer_accounts_CustomerId",
                schema: "accounts",
                table: "customer_accounts",
                column: "CustomerId",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "account_transactions",
                schema: "accounts");

            migrationBuilder.DropTable(
                name: "customer_accounts",
                schema: "accounts");

            migrationBuilder.DropSequence(
                name: "accounttransactionseq",
                schema: "accounts");

            migrationBuilder.DropSequence(
                name: "customeraccountseq",
                schema: "accounts");
        }
    }
}
