using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Loyalty.API.Migrations
{
    /// <inheritdoc />
    public partial class RefactorTransactionType : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // First, update existing data to use PascalCase type names
            migrationBuilder.Sql(@"
                UPDATE ""PointsTransactions""
                SET ""Type"" = CASE ""Type""
                    WHEN 'purchase' THEN 'Purchase'
                    WHEN 'redemption' THEN 'Redemption'
                    WHEN 'bonus' THEN 'Bonus'
                    WHEN 'referral' THEN 'Referral'
                    WHEN 'promotion' THEN 'Promotion'
                    WHEN 'adjustment' THEN 'Adjustment'
                    ELSE ""Type""
                END
            ");

            migrationBuilder.AlterColumn<string>(
                name: "Type",
                table: "PointsTransactions",
                type: "character varying(20)",
                maxLength: 20,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "text");

            migrationBuilder.AlterColumn<string>(
                name: "Description",
                table: "PointsTransactions",
                type: "text",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "text");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<string>(
                name: "Type",
                table: "PointsTransactions",
                type: "text",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "character varying(20)",
                oldMaxLength: 20);

            migrationBuilder.AlterColumn<string>(
                name: "Description",
                table: "PointsTransactions",
                type: "text",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "text",
                oldNullable: true);
        }
    }
}
