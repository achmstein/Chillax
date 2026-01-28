using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Ordering.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class RenameTableNumberToRoomName : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "TableNumber",
                schema: "ordering",
                table: "orders");

            migrationBuilder.AddColumn<string>(
                name: "RoomName",
                schema: "ordering",
                table: "orders",
                type: "text",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "RoomName",
                schema: "ordering",
                table: "orders");

            migrationBuilder.AddColumn<int>(
                name: "TableNumber",
                schema: "ordering",
                table: "orders",
                type: "integer",
                nullable: true);
        }
    }
}
