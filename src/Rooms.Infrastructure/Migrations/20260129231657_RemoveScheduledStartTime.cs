using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Rooms.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class RemoveScheduledStartTime : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_reservations_ScheduledStartTime",
                schema: "rooms",
                table: "reservations");

            migrationBuilder.DropColumn(
                name: "ScheduledStartTime",
                schema: "rooms",
                table: "reservations");

            migrationBuilder.CreateIndex(
                name: "IX_reservations_CreatedAt",
                schema: "rooms",
                table: "reservations",
                column: "CreatedAt");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_reservations_CreatedAt",
                schema: "rooms",
                table: "reservations");

            migrationBuilder.AddColumn<DateTime>(
                name: "ScheduledStartTime",
                schema: "rooms",
                table: "reservations",
                type: "timestamp with time zone",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.CreateIndex(
                name: "IX_reservations_ScheduledStartTime",
                schema: "rooms",
                table: "reservations",
                column: "ScheduledStartTime");
        }
    }
}
