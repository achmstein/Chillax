using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace Catalog.API.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddUserItemPreferences : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "UserItemPreferences",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    UserId = table.Column<string>(type: "character varying(256)", maxLength: 256, nullable: false),
                    CatalogItemId = table.Column<int>(type: "integer", nullable: false),
                    LastUpdated = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserItemPreferences", x => x.Id);
                    table.ForeignKey(
                        name: "FK_UserItemPreferences_Catalog_CatalogItemId",
                        column: x => x.CatalogItemId,
                        principalTable: "Catalog",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "UserPreferenceOptions",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    UserItemPreferenceId = table.Column<int>(type: "integer", nullable: false),
                    CustomizationId = table.Column<int>(type: "integer", nullable: false),
                    OptionId = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserPreferenceOptions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_UserPreferenceOptions_UserItemPreferences_UserItemPreferenc~",
                        column: x => x.UserItemPreferenceId,
                        principalTable: "UserItemPreferences",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_UserItemPreferences_CatalogItemId",
                table: "UserItemPreferences",
                column: "CatalogItemId");

            migrationBuilder.CreateIndex(
                name: "IX_UserItemPreferences_UserId_CatalogItemId",
                table: "UserItemPreferences",
                columns: new[] { "UserId", "CatalogItemId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_UserPreferenceOptions_UserItemPreferenceId_CustomizationId_~",
                table: "UserPreferenceOptions",
                columns: new[] { "UserItemPreferenceId", "CustomizationId", "OptionId" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "UserPreferenceOptions");

            migrationBuilder.DropTable(
                name: "UserItemPreferences");
        }
    }
}
