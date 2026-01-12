using System.Security.Claims;

namespace Chillax.ServiceDefaults;

public static class ClaimsPrincipalExtensions
{
    public static string? GetUserId(this ClaimsPrincipal principal)
        => principal.FindFirst("sub")?.Value
           ?? principal.FindFirst(ClaimTypes.NameIdentifier)?.Value;

    public static string? GetUserName(this ClaimsPrincipal principal) =>
        principal.FindFirst("preferred_username")?.Value
        ?? principal.FindFirst(ClaimTypes.Name)?.Value;

    public static string? GetEmail(this ClaimsPrincipal principal) =>
        principal.FindFirst("email")?.Value
        ?? principal.FindFirst(ClaimTypes.Email)?.Value;

    public static IEnumerable<string> GetRoles(this ClaimsPrincipal principal) =>
        principal.FindAll("role").Select(c => c.Value)
        .Concat(principal.FindAll(ClaimTypes.Role).Select(c => c.Value))
        .Distinct();

    public static bool IsInRole(this ClaimsPrincipal principal, string role) =>
        principal.GetRoles().Contains(role);
}
