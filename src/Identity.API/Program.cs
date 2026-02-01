using System.Net.Http.Headers;
using System.Text.Json;
using Chillax.ServiceDefaults;

var builder = WebApplication.CreateBuilder(args);

builder.AddServiceDefaults();
builder.AddDefaultAuthentication();

// Add HttpClient for Keycloak Admin API
builder.Services.AddHttpClient("KeycloakAdmin", client =>
{
    client.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
});

var app = builder.Build();

app.MapDefaultEndpoints();

app.UseAuthentication();
app.UseAuthorization();

// Registration endpoint
app.MapPost("/api/identity/register", async (RegisterRequest request, IHttpClientFactory httpClientFactory, IConfiguration config) =>
{
    var keycloakUrl = config["Identity:Url"] ?? throw new InvalidOperationException("Identity:Url not configured");
    var realm = config["Keycloak:Realm"] ?? "chillax";
    var adminClientId = config["Keycloak:AdminClientId"] ?? "admin-cli";
    var adminClientSecret = config["Keycloak:AdminClientSecret"];

    var client = httpClientFactory.CreateClient("KeycloakAdmin");

    // Get admin token using client credentials
    var tokenEndpoint = $"{keycloakUrl}/protocol/openid-connect/token";
    var tokenRequest = new FormUrlEncodedContent(new Dictionary<string, string>
    {
        ["grant_type"] = "client_credentials",
        ["client_id"] = adminClientId,
        ["client_secret"] = adminClientSecret ?? ""
    });

    var tokenResponse = await client.PostAsync(tokenEndpoint, tokenRequest);
    if (!tokenResponse.IsSuccessStatusCode)
    {
        return Results.Problem("Failed to authenticate with identity provider", statusCode: 500);
    }

    var tokenJson = await tokenResponse.Content.ReadFromJsonAsync<JsonElement>();
    var accessToken = tokenJson.GetProperty("access_token").GetString();

    // Create user via Admin REST API
    var adminUrl = keycloakUrl.Replace($"/realms/{realm}", "");
    var usersEndpoint = $"{adminUrl}/admin/realms/{realm}/users";

    // Split name into first/last if space present
    var nameParts = request.Name?.Split(' ', 2) ?? [];
    var firstName = nameParts.Length > 0 ? nameParts[0] : request.Name;
    var lastName = nameParts.Length > 1 ? nameParts[1] : null;

    var userPayload = new
    {
        username = request.Email,  // Use email as username
        email = request.Email,
        firstName = firstName,
        lastName = lastName,
        enabled = true,
        emailVerified = true,
        requiredActions = Array.Empty<string>(),
        attributes = new Dictionary<string, string[]>
        {
            ["phoneNumber"] = string.IsNullOrEmpty(request.PhoneNumber) ? [] : [request.PhoneNumber]
        },
        credentials = new[]
        {
            new
            {
                type = "password",
                value = request.Password,
                temporary = false
            }
        }
    };

    client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
    var createResponse = await client.PostAsJsonAsync(usersEndpoint, userPayload);

    if (createResponse.IsSuccessStatusCode || createResponse.StatusCode == System.Net.HttpStatusCode.Created)
    {
        return Results.Ok(new { message = "User registered successfully" });
    }

    if (createResponse.StatusCode == System.Net.HttpStatusCode.Conflict)
    {
        return Results.Conflict(new { message = "Username or email already exists" });
    }

    var errorContent = await createResponse.Content.ReadAsStringAsync();
    return Results.Problem($"Registration failed: {errorContent}", statusCode: (int)createResponse.StatusCode);
});

// List users endpoint (admin only)
app.MapGet("/api/identity/users", async (IHttpClientFactory httpClientFactory, IConfiguration config, int? first, int? max, string? search) =>
{
    var keycloakUrl = config["Identity:Url"] ?? throw new InvalidOperationException("Identity:Url not configured");
    var realm = config["Keycloak:Realm"] ?? "chillax";
    var adminClientId = config["Keycloak:AdminClientId"] ?? "admin-cli";
    var adminClientSecret = config["Keycloak:AdminClientSecret"];

    var client = httpClientFactory.CreateClient("KeycloakAdmin");

    // Get admin token
    var tokenEndpoint = $"{keycloakUrl}/protocol/openid-connect/token";
    var tokenRequest = new FormUrlEncodedContent(new Dictionary<string, string>
    {
        ["grant_type"] = "client_credentials",
        ["client_id"] = adminClientId,
        ["client_secret"] = adminClientSecret ?? ""
    });

    var tokenResponse = await client.PostAsync(tokenEndpoint, tokenRequest);
    if (!tokenResponse.IsSuccessStatusCode)
    {
        return Results.Problem("Failed to authenticate with identity provider", statusCode: 500);
    }

    var tokenJson = await tokenResponse.Content.ReadFromJsonAsync<JsonElement>();
    var accessToken = tokenJson.GetProperty("access_token").GetString();

    // Fetch users from Keycloak Admin API
    var adminUrl = keycloakUrl.Replace($"/realms/{realm}", "");
    var usersEndpoint = $"{adminUrl}/admin/realms/{realm}/users";

    // Build query parameters
    var queryParams = new List<string>();
    if (first.HasValue) queryParams.Add($"first={first.Value}");
    if (max.HasValue) queryParams.Add($"max={max.Value}");
    else queryParams.Add("max=50"); // Default limit
    if (!string.IsNullOrEmpty(search)) queryParams.Add($"search={Uri.EscapeDataString(search)}");

    if (queryParams.Count > 0)
    {
        usersEndpoint += "?" + string.Join("&", queryParams);
    }

    client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
    var usersResponse = await client.GetAsync(usersEndpoint);

    if (!usersResponse.IsSuccessStatusCode)
    {
        return Results.Problem("Failed to fetch users", statusCode: (int)usersResponse.StatusCode);
    }

    var users = await usersResponse.Content.ReadFromJsonAsync<List<KeycloakUser>>();
    var result = users?.Select(u => new UserDto(
        u.Id,
        u.Username,
        u.Email,
        u.FirstName,
        u.LastName,
        u.Enabled,
        u.CreatedTimestamp
    )).ToList() ?? [];

    return Results.Ok(result);
}).RequireAuthorization();

// Get user by ID endpoint (admin only)
app.MapGet("/api/identity/users/{userId}", async (string userId, IHttpClientFactory httpClientFactory, IConfiguration config) =>
{
    var keycloakUrl = config["Identity:Url"] ?? throw new InvalidOperationException("Identity:Url not configured");
    var realm = config["Keycloak:Realm"] ?? "chillax";
    var adminClientId = config["Keycloak:AdminClientId"] ?? "admin-cli";
    var adminClientSecret = config["Keycloak:AdminClientSecret"];

    var client = httpClientFactory.CreateClient("KeycloakAdmin");

    // Get admin token
    var tokenEndpoint = $"{keycloakUrl}/protocol/openid-connect/token";
    var tokenRequest = new FormUrlEncodedContent(new Dictionary<string, string>
    {
        ["grant_type"] = "client_credentials",
        ["client_id"] = adminClientId,
        ["client_secret"] = adminClientSecret ?? ""
    });

    var tokenResponse = await client.PostAsync(tokenEndpoint, tokenRequest);
    if (!tokenResponse.IsSuccessStatusCode)
    {
        return Results.Problem("Failed to authenticate with identity provider", statusCode: 500);
    }

    var tokenJson = await tokenResponse.Content.ReadFromJsonAsync<JsonElement>();
    var accessToken = tokenJson.GetProperty("access_token").GetString();

    // Fetch user from Keycloak Admin API
    var adminUrl = keycloakUrl.Replace($"/realms/{realm}", "");
    var userEndpoint = $"{adminUrl}/admin/realms/{realm}/users/{userId}";

    client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
    var userResponse = await client.GetAsync(userEndpoint);

    if (userResponse.StatusCode == System.Net.HttpStatusCode.NotFound)
    {
        return Results.NotFound();
    }

    if (!userResponse.IsSuccessStatusCode)
    {
        return Results.Problem("Failed to fetch user", statusCode: (int)userResponse.StatusCode);
    }

    var user = await userResponse.Content.ReadFromJsonAsync<KeycloakUser>();
    if (user == null)
    {
        return Results.NotFound();
    }

    return Results.Ok(new UserDto(
        user.Id,
        user.Username,
        user.Email,
        user.FirstName,
        user.LastName,
        user.Enabled,
        user.CreatedTimestamp
    ));
}).RequireAuthorization();

// Get user count endpoint
app.MapGet("/api/identity/users/count", async (IHttpClientFactory httpClientFactory, IConfiguration config) =>
{
    var keycloakUrl = config["Identity:Url"] ?? throw new InvalidOperationException("Identity:Url not configured");
    var realm = config["Keycloak:Realm"] ?? "chillax";
    var adminClientId = config["Keycloak:AdminClientId"] ?? "admin-cli";
    var adminClientSecret = config["Keycloak:AdminClientSecret"];

    var client = httpClientFactory.CreateClient("KeycloakAdmin");

    // Get admin token
    var tokenEndpoint = $"{keycloakUrl}/protocol/openid-connect/token";
    var tokenRequest = new FormUrlEncodedContent(new Dictionary<string, string>
    {
        ["grant_type"] = "client_credentials",
        ["client_id"] = adminClientId,
        ["client_secret"] = adminClientSecret ?? ""
    });

    var tokenResponse = await client.PostAsync(tokenEndpoint, tokenRequest);
    if (!tokenResponse.IsSuccessStatusCode)
    {
        return Results.Problem("Failed to authenticate with identity provider", statusCode: 500);
    }

    var tokenJson = await tokenResponse.Content.ReadFromJsonAsync<JsonElement>();
    var accessToken = tokenJson.GetProperty("access_token").GetString();

    // Fetch user count from Keycloak Admin API
    var adminUrl = keycloakUrl.Replace($"/realms/{realm}", "");
    var countEndpoint = $"{adminUrl}/admin/realms/{realm}/users/count";

    client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
    var countResponse = await client.GetAsync(countEndpoint);

    if (!countResponse.IsSuccessStatusCode)
    {
        return Results.Problem("Failed to fetch user count", statusCode: (int)countResponse.StatusCode);
    }

    var count = await countResponse.Content.ReadFromJsonAsync<int>();
    return Results.Ok(new { count });
}).RequireAuthorization();

// Change password endpoint (authenticated user)
app.MapPost("/api/identity/change-password", async (ChangePasswordRequest request, HttpContext httpContext, IHttpClientFactory httpClientFactory, IConfiguration config) =>
{
    var userId = httpContext.User.GetUserId();
    if (string.IsNullOrEmpty(userId))
    {
        return Results.Unauthorized();
    }

    var keycloakUrl = config["Identity:Url"] ?? throw new InvalidOperationException("Identity:Url not configured");
    var realm = config["Keycloak:Realm"] ?? "chillax";
    var adminClientId = config["Keycloak:AdminClientId"] ?? "admin-cli";
    var adminClientSecret = config["Keycloak:AdminClientSecret"];

    var client = httpClientFactory.CreateClient("KeycloakAdmin");

    // Get admin token
    var tokenEndpoint = $"{keycloakUrl}/protocol/openid-connect/token";
    var tokenRequest = new FormUrlEncodedContent(new Dictionary<string, string>
    {
        ["grant_type"] = "client_credentials",
        ["client_id"] = adminClientId,
        ["client_secret"] = adminClientSecret ?? ""
    });

    var tokenResponse = await client.PostAsync(tokenEndpoint, tokenRequest);
    if (!tokenResponse.IsSuccessStatusCode)
    {
        return Results.Problem("Failed to authenticate with identity provider", statusCode: 500);
    }

    var tokenJson = await tokenResponse.Content.ReadFromJsonAsync<JsonElement>();
    var accessToken = tokenJson.GetProperty("access_token").GetString();

    // Reset password via Admin API
    var adminUrl = keycloakUrl.Replace($"/realms/{realm}", "");
    var passwordEndpoint = $"{adminUrl}/admin/realms/{realm}/users/{userId}/reset-password";

    var passwordPayload = new
    {
        type = "password",
        value = request.NewPassword,
        temporary = false
    };

    client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
    var resetResponse = await client.PutAsJsonAsync(passwordEndpoint, passwordPayload);

    if (resetResponse.IsSuccessStatusCode || resetResponse.StatusCode == System.Net.HttpStatusCode.NoContent)
    {
        return Results.Ok(new { message = "Password changed successfully" });
    }

    if (resetResponse.StatusCode == System.Net.HttpStatusCode.NotFound)
    {
        return Results.NotFound(new { message = "User not found" });
    }

    var errorContent = await resetResponse.Content.ReadAsStringAsync();
    return Results.Problem($"Failed to change password: {errorContent}", statusCode: (int)resetResponse.StatusCode);
}).RequireAuthorization();

// Update email endpoint (authenticated user)
app.MapPost("/api/identity/update-email", async (UpdateEmailRequest request, HttpContext httpContext, IHttpClientFactory httpClientFactory, IConfiguration config) =>
{
    var userId = httpContext.User.GetUserId();
    if (string.IsNullOrEmpty(userId))
    {
        return Results.Unauthorized();
    }

    var keycloakUrl = config["Identity:Url"] ?? throw new InvalidOperationException("Identity:Url not configured");
    var realm = config["Keycloak:Realm"] ?? "chillax";
    var adminClientId = config["Keycloak:AdminClientId"] ?? "admin-cli";
    var adminClientSecret = config["Keycloak:AdminClientSecret"];

    var client = httpClientFactory.CreateClient("KeycloakAdmin");

    // Get admin token
    var tokenEndpoint = $"{keycloakUrl}/protocol/openid-connect/token";
    var tokenRequest = new FormUrlEncodedContent(new Dictionary<string, string>
    {
        ["grant_type"] = "client_credentials",
        ["client_id"] = adminClientId,
        ["client_secret"] = adminClientSecret ?? ""
    });

    var tokenResponse = await client.PostAsync(tokenEndpoint, tokenRequest);
    if (!tokenResponse.IsSuccessStatusCode)
    {
        return Results.Problem("Failed to authenticate with identity provider", statusCode: 500);
    }

    var tokenJson = await tokenResponse.Content.ReadFromJsonAsync<JsonElement>();
    var accessToken = tokenJson.GetProperty("access_token").GetString();

    // Update user email via Admin API
    var adminUrl = keycloakUrl.Replace($"/realms/{realm}", "");
    var userEndpoint = $"{adminUrl}/admin/realms/{realm}/users/{userId}";

    var emailPayload = new
    {
        email = request.NewEmail,
        emailVerified = false
    };

    client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
    var updateResponse = await client.PutAsJsonAsync(userEndpoint, emailPayload);

    if (updateResponse.IsSuccessStatusCode || updateResponse.StatusCode == System.Net.HttpStatusCode.NoContent)
    {
        return Results.Ok(new { message = "Email updated successfully" });
    }

    if (updateResponse.StatusCode == System.Net.HttpStatusCode.NotFound)
    {
        return Results.NotFound(new { message = "User not found" });
    }

    if (updateResponse.StatusCode == System.Net.HttpStatusCode.Conflict)
    {
        return Results.Conflict(new { message = "Email already in use" });
    }

    var errorContent = await updateResponse.Content.ReadAsStringAsync();
    return Results.Problem($"Failed to update email: {errorContent}", statusCode: (int)updateResponse.StatusCode);
}).RequireAuthorization();

// Delete account endpoint (authenticated user - soft delete by disabling)
app.MapDelete("/api/identity/delete-account", async (HttpContext httpContext, IHttpClientFactory httpClientFactory, IConfiguration config) =>
{
    var userId = httpContext.User.GetUserId();
    if (string.IsNullOrEmpty(userId))
    {
        return Results.Unauthorized();
    }

    var keycloakUrl = config["Identity:Url"] ?? throw new InvalidOperationException("Identity:Url not configured");
    var realm = config["Keycloak:Realm"] ?? "chillax";
    var adminClientId = config["Keycloak:AdminClientId"] ?? "admin-cli";
    var adminClientSecret = config["Keycloak:AdminClientSecret"];

    var client = httpClientFactory.CreateClient("KeycloakAdmin");

    // Get admin token
    var tokenEndpoint = $"{keycloakUrl}/protocol/openid-connect/token";
    var tokenRequest = new FormUrlEncodedContent(new Dictionary<string, string>
    {
        ["grant_type"] = "client_credentials",
        ["client_id"] = adminClientId,
        ["client_secret"] = adminClientSecret ?? ""
    });

    var tokenResponse = await client.PostAsync(tokenEndpoint, tokenRequest);
    if (!tokenResponse.IsSuccessStatusCode)
    {
        return Results.Problem("Failed to authenticate with identity provider", statusCode: 500);
    }

    var tokenJson = await tokenResponse.Content.ReadFromJsonAsync<JsonElement>();
    var accessToken = tokenJson.GetProperty("access_token").GetString();

    // Disable user via Admin API (soft delete)
    var adminUrl = keycloakUrl.Replace($"/realms/{realm}", "");
    var userEndpoint = $"{adminUrl}/admin/realms/{realm}/users/{userId}";

    var disablePayload = new
    {
        enabled = false
    };

    client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
    var updateResponse = await client.PutAsJsonAsync(userEndpoint, disablePayload);

    if (updateResponse.IsSuccessStatusCode || updateResponse.StatusCode == System.Net.HttpStatusCode.NoContent)
    {
        return Results.Ok(new { message = "Account deleted successfully" });
    }

    if (updateResponse.StatusCode == System.Net.HttpStatusCode.NotFound)
    {
        return Results.NotFound(new { message = "User not found" });
    }

    var errorContent = await updateResponse.Content.ReadAsStringAsync();
    return Results.Problem($"Failed to delete account: {errorContent}", statusCode: (int)updateResponse.StatusCode);
}).RequireAuthorization();

app.Run();

record RegisterRequest(string? Name, string Email, string Password, string? PhoneNumber);
record ChangePasswordRequest(string NewPassword);
record UpdateEmailRequest(string NewEmail);

record UserDto(
    string Id,
    string? Username,
    string? Email,
    string? FirstName,
    string? LastName,
    bool Enabled,
    long? CreatedTimestamp
);

// Keycloak user model for deserialization
class KeycloakUser
{
    public string Id { get; set; } = "";
    public string? Username { get; set; }
    public string? Email { get; set; }
    public string? FirstName { get; set; }
    public string? LastName { get; set; }
    public bool Enabled { get; set; }
    public long? CreatedTimestamp { get; set; }
}
