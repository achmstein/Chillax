using System.ComponentModel;
using System.Security.Claims;
using Chillax.Branch.API.Model;
using Microsoft.AspNetCore.Http.HttpResults;

namespace Chillax.Branch.API.Apis;

public static class BranchApi
{
    public static IEndpointRouteBuilder MapBranchApi(this IEndpointRouteBuilder app)
    {
        var api = app.MapGroup("api/branches");

        // Public endpoints
        api.MapGet("/", GetActiveBranches)
            .WithName("GetBranches")
            .WithSummary("List active branches")
            .WithTags("Branches");

        // Admin endpoints
        api.MapPost("/", CreateBranch)
            .WithName("CreateBranch")
            .WithSummary("Create a branch")
            .WithTags("Branches")
            .RequireAuthorization("Admin");

        api.MapPut("/{id:int}", UpdateBranch)
            .WithName("UpdateBranch")
            .WithSummary("Update a branch")
            .WithTags("Branches")
            .RequireAuthorization("Admin");

        // Admin branch assignment
        api.MapGet("/admin/{adminUserId}", GetBranchesByAdmin)
            .WithName("GetBranchesByAdmin")
            .WithSummary("Get branches assigned to an admin")
            .WithTags("Admin Assignments")
            .RequireAuthorization("Admin");

        api.MapPost("/{id:int}/admins", AssignAdmin)
            .WithName("AssignAdmin")
            .WithSummary("Assign admin to branch")
            .WithTags("Admin Assignments")
            .RequireAuthorization("Admin");

        api.MapDelete("/{id:int}/admins/{userId}", RemoveAdmin)
            .WithName("RemoveAdmin")
            .WithSummary("Remove admin from branch")
            .WithTags("Admin Assignments")
            .RequireAuthorization("Admin");

        return app;
    }

    public static async Task<Ok<List<BranchResponse>>> GetActiveBranches(BranchContext context)
    {
        var branches = await context.Branches
            .AsNoTracking()
            .Where(b => b.IsActive)
            .OrderBy(b => b.DisplayOrder)
            .Select(b => new BranchResponse(b.Id, b.Name, b.Address, b.Phone, b.IsActive, b.DisplayOrder))
            .ToListAsync();

        return TypedResults.Ok(branches);
    }

    public static async Task<Created<BranchResponse>> CreateBranch(
        BranchContext context,
        CreateBranchRequest request)
    {
        var branch = new Model.Branch
        {
            Name = request.Name,
            Address = request.Address,
            Phone = request.Phone,
            IsActive = true,
            DisplayOrder = request.DisplayOrder
        };

        context.Branches.Add(branch);
        await context.SaveChangesAsync();

        var response = new BranchResponse(branch.Id, branch.Name, branch.Address, branch.Phone, branch.IsActive, branch.DisplayOrder);
        return TypedResults.Created($"/api/branches/{branch.Id}", response);
    }

    public static async Task<Results<Ok<BranchResponse>, NotFound>> UpdateBranch(
        BranchContext context,
        [Description("The branch ID")] int id,
        UpdateBranchRequest request)
    {
        var branch = await context.Branches.FindAsync(id);
        if (branch == null)
            return TypedResults.NotFound();

        branch.Name = request.Name;
        branch.Address = request.Address;
        branch.Phone = request.Phone;
        branch.IsActive = request.IsActive;
        branch.DisplayOrder = request.DisplayOrder;

        await context.SaveChangesAsync();

        var response = new BranchResponse(branch.Id, branch.Name, branch.Address, branch.Phone, branch.IsActive, branch.DisplayOrder);
        return TypedResults.Ok(response);
    }

    public static async Task<Ok<List<BranchResponse>>> GetBranchesByAdmin(
        BranchContext context,
        [Description("The admin user ID")] string adminUserId)
    {
        var branches = await context.AdminBranchAssignments
            .AsNoTracking()
            .Where(a => a.AdminUserId == adminUserId)
            .Include(a => a.Branch)
            .Where(a => a.Branch.IsActive)
            .OrderBy(a => a.Branch.DisplayOrder)
            .Select(a => new BranchResponse(a.Branch.Id, a.Branch.Name, a.Branch.Address, a.Branch.Phone, a.Branch.IsActive, a.Branch.DisplayOrder))
            .ToListAsync();

        return TypedResults.Ok(branches);
    }

    public static async Task<Results<Created, Conflict<string>, NotFound>> AssignAdmin(
        BranchContext context,
        [Description("The branch ID")] int id,
        AssignAdminRequest request)
    {
        var branch = await context.Branches.FindAsync(id);
        if (branch == null)
            return TypedResults.NotFound();

        var exists = await context.AdminBranchAssignments
            .AnyAsync(a => a.AdminUserId == request.AdminUserId && a.BranchId == id);

        if (exists)
            return TypedResults.Conflict("Admin is already assigned to this branch");

        context.AdminBranchAssignments.Add(new AdminBranchAssignment
        {
            AdminUserId = request.AdminUserId,
            BranchId = id
        });

        await context.SaveChangesAsync();
        return TypedResults.Created($"/api/branches/{id}/admins/{request.AdminUserId}");
    }

    public static async Task<Results<NoContent, NotFound>> RemoveAdmin(
        BranchContext context,
        [Description("The branch ID")] int id,
        [Description("The admin user ID")] string userId)
    {
        var assignment = await context.AdminBranchAssignments
            .FirstOrDefaultAsync(a => a.AdminUserId == userId && a.BranchId == id);

        if (assignment == null)
            return TypedResults.NotFound();

        context.AdminBranchAssignments.Remove(assignment);
        await context.SaveChangesAsync();

        return TypedResults.NoContent();
    }
}

public record BranchResponse(int Id, LocalizedText Name, LocalizedText? Address, string? Phone, bool IsActive, int DisplayOrder);

public record CreateBranchRequest(LocalizedText Name, LocalizedText? Address, string? Phone, int DisplayOrder = 0);

public record UpdateBranchRequest(LocalizedText Name, LocalizedText? Address, string? Phone, bool IsActive, int DisplayOrder);

public record AssignAdminRequest(string AdminUserId);
