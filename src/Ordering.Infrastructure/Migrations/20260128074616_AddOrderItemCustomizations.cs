using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Ordering.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddOrderItemCustomizations : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<string>(
                name: "PictureUrl",
                schema: "ordering",
                table: "orderItems",
                type: "text",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "text",
                oldNullable: true);

            migrationBuilder.AddColumn<string>(
                name: "CustomizationsDescription",
                schema: "ordering",
                table: "orderItems",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "SpecialInstructions",
                schema: "ordering",
                table: "orderItems",
                type: "text",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "CustomizationsDescription",
                schema: "ordering",
                table: "orderItems");

            migrationBuilder.DropColumn(
                name: "SpecialInstructions",
                schema: "ordering",
                table: "orderItems");

            migrationBuilder.AlterColumn<string>(
                name: "PictureUrl",
                schema: "ordering",
                table: "orderItems",
                type: "text",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "text");
        }
    }
}
