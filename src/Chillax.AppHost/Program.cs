using Chillax.AppHost;

var builder = DistributedApplication.CreateBuilder(args);

builder.AddForwardedHeaders();

var rabbitMq = builder.AddRabbitMQ("eventbus")
    .WithLifetime(ContainerLifetime.Persistent);
var postgres = builder.AddPostgres("postgres")
    .WithImage("ankane/pgvector")
    .WithImageTag("latest")
    .WithLifetime(ContainerLifetime.Persistent);

var accountsDb = postgres.AddDatabase("accountsdb");
var catalogDb = postgres.AddDatabase("catalogdb");
var orderDb = postgres.AddDatabase("orderingdb");
var roomsDb = postgres.AddDatabase("roomsdb");
var loyaltyDb = postgres.AddDatabase("loyaltydb");
var notificationDb = postgres.AddDatabase("notificationdb");

var launchProfileName = ShouldUseHttpForEndpoints() ? "http" : "https";

// Keycloak for identity
var keycloak = builder.AddKeycloak("keycloak", port: 8080)
    .WithDataVolume()
    .WithLifetime(ContainerLifetime.Persistent)
    .WithRealmImport("./KeycloakConfiguration/chillax-realm.json");

// Build Keycloak realm URL for services
var keycloakEndpoint = keycloak.GetEndpoint("http");
var keycloakRealmUrl = ReferenceExpression.Create($"{keycloakEndpoint}/realms/chillax");

var catalogApi = builder.AddProject<Projects.Catalog_API>("catalog-api")
    .WithReference(rabbitMq).WaitFor(rabbitMq)
    .WithReference(catalogDb)
    .WithReference(keycloak)
    .WithEnvironment("Identity__Url", keycloakRealmUrl)
    .WithEnvironment("Keycloak__Realm", "chillax");

var orderingApi = builder.AddProject<Projects.Ordering_API>("ordering-api")
    .WithReference(rabbitMq).WaitFor(rabbitMq)
    .WithReference(orderDb).WaitFor(orderDb)
    .WithHttpHealthCheck("/health")
    .WithReference(keycloak)
    .WithEnvironment("Identity__Url", keycloakRealmUrl)
    .WithEnvironment("Keycloak__Realm", "chillax");

var roomsApi = builder.AddProject<Projects.Rooms_API>("rooms-api")
    .WithReference(roomsDb).WaitFor(roomsDb)
    .WithReference(rabbitMq).WaitFor(rabbitMq)
    .WithReference(keycloak)
    .WithEnvironment("Identity__Url", keycloakRealmUrl)
    .WithEnvironment("Keycloak__Realm", "chillax");

var identityApi = builder.AddProject<Projects.Identity_API>("identity-api")
    .WithReference(keycloak).WaitFor(keycloak)
    .WithHttpHealthCheck("/health")
    .WithEnvironment("Identity__Url", keycloakRealmUrl)
    .WithEnvironment("Keycloak__Realm", "chillax")
    .WithEnvironment("Keycloak__AdminClientId", "identity-api-service")
    .WithEnvironment("Keycloak__AdminClientSecret", "identity-api-secret");

var loyaltyApi = builder.AddProject<Projects.Loyalty_API>("loyalty-api")
    .WithReference(loyaltyDb).WaitFor(loyaltyDb)
    .WithReference(rabbitMq).WaitFor(rabbitMq)
    .WithReference(keycloak)
    .WithEnvironment("Identity__Url", keycloakRealmUrl)
    .WithEnvironment("Keycloak__Realm", "chillax");

var notificationApi = builder.AddProject<Projects.Notification_API>("notification-api")
    .WithReference(notificationDb).WaitFor(notificationDb)
    .WithReference(rabbitMq).WaitFor(rabbitMq)
    .WithReference(keycloak)
    .WithEnvironment("Identity__Url", keycloakRealmUrl)
    .WithEnvironment("Keycloak__Realm", "chillax");

var accountsApi = builder.AddProject<Projects.Accounts_API>("accounts-api")
    .WithReference(accountsDb).WaitFor(accountsDb)
    .WithReference(keycloak)
    .WithEnvironment("Identity__Url", keycloakRealmUrl)
    .WithEnvironment("Keycloak__Realm", "chillax");

// Reverse proxy - BFF for Flutter apps (fixed port 27748 for adb reverse)
// Used by both mobile app and admin app
builder.AddYarp("mobile-bff")
    .WithEndpoint("http", endpoint =>
    {
        endpoint.Port = 27748;
        endpoint.UriScheme = "http";
        endpoint.IsExternal = true;
    })
    .ConfigureMobileBffRoutes(catalogApi, orderingApi, roomsApi, identityApi, loyaltyApi, notificationApi, accountsApi, keycloak);

builder.Build().Run();

// For test use only.
// Looks for an environment variable that forces the use of HTTP for all the endpoints. We
// are doing this for ease of running the Playwright tests in CI.
static bool ShouldUseHttpForEndpoints()
{
    const string EnvVarName = "CHILLAX_USE_HTTP_ENDPOINTS";
    var envValue = Environment.GetEnvironmentVariable(EnvVarName);

    // Attempt to parse the environment variable value; return true if it's exactly "1".
    return int.TryParse(envValue, out int result) && result == 1;
}
