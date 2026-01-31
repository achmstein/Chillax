using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Rooms.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddArabicLocalization : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "DescriptionAr",
                schema: "rooms",
                table: "rooms",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "NameAr",
                schema: "rooms",
                table: "rooms",
                type: "text",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "DescriptionAr",
                schema: "rooms",
                table: "rooms");

            migrationBuilder.DropColumn(
                name: "NameAr",
                schema: "rooms",
                table: "rooms");
        }
    }
}
