using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Tokens;

namespace Chillax.ServiceDefaults;

public static class AuthenticationExtensions
{
    /// <summary>
    /// Adds Keycloak JWT Bearer authentication using Aspire service discovery.
    /// Requires Keycloak to have a "User Realm Role" mapper that maps roles to "role" claim.
    /// </summary>
    public static IServiceCollection AddDefaultAuthentication(this IHostApplicationBuilder builder)
    {
        var services = builder.Services;
        var configuration = builder.Configuration;

        // Get Keycloak configuration from environment variables (set by Aspire)
        var keycloakRealmUrl = configuration["Identity__Url"];
        var realm = configuration["Keycloak__Realm"] ?? "chillax";

        // Check if Keycloak is configured
        if (string.IsNullOrEmpty(keycloakRealmUrl))
        {
            // Fallback: check for old Identity section for backwards compatibility
            var identitySection = configuration.GetSection("Identity");
            if (!identitySection.Exists())
            {
                // No authentication configured
                return services;
            }
            keycloakRealmUrl = identitySection["Url"];
        }

        // Prevent mapping "sub" claim to nameidentifier
        JsonWebTokenHandler.DefaultInboundClaimTypeMap.Remove("sub");

        services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
            .AddJwtBearer(options =>
            {
                options.Authority = keycloakRealmUrl;
                options.RequireHttpsMetadata = false;

                // Don't remap claim names - keep original JWT claim names
                options.MapInboundClaims = false;

                // Keycloak issues tokens with external URL but Aspire uses internal service discovery
                options.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidateIssuer = true,
                    ValidIssuers = [
                        $"http://localhost:8080/realms/{realm}",
                        $"http://10.0.2.2:8080/realms/{realm}",  // Android emulator
                        $"http://keycloak:8080/realms/{realm}",  // Docker internal
                        keycloakRealmUrl ?? $"http://localhost:8080/realms/{realm}"
                    ],

                    // Disable audience validation for flexibility
                    // Keycloak uses client_id as audience
                    ValidateAudience = false,

                    // Use "role" claim for roles (requires Keycloak mapper)
                    RoleClaimType = "role"
                };
            });

        services.AddAuthorization(options =>
        {
            // Admin policy requires the "Admin" role
            options.AddPolicy("Admin", policy => policy.RequireRole("Admin"));
        });

        return services;
    }
}
