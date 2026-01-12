using System.Net.Http.Headers;
using System.Text.Json;
using Chillax.ServiceDefaults;

var builder = WebApplication.CreateBuilder(args);

builder.AddServiceDefaults();

// Add HttpClient for Keycloak Admin API
builder.Services.AddHttpClient("KeycloakAdmin", client =>
{
    client.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
});

var app = builder.Build();

app.MapDefaultEndpoints();

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
    // Admin API is at the realm level: {keycloak-base}/admin/realms/{realm}/users
    var adminUrl = keycloakUrl.Replace($"/realms/{realm}", "");
    var usersEndpoint = $"{adminUrl}/admin/realms/{realm}/users";

    var userPayload = new
    {
        username = request.Username,
        email = request.Email,
        enabled = true,
        emailVerified = true,
        requiredActions = Array.Empty<string>(),
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

app.Run();

record RegisterRequest(string Username, string Email, string Password);

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
