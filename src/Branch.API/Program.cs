using Chillax.Branch.API.Apis;
using Chillax.Branch.API.Extensions;
using Chillax.ServiceDefaults;

var builder = WebApplication.CreateBuilder(args);

builder.AddServiceDefaults();
builder.AddDefaultOpenApi();
builder.AddDefaultAuthentication();
builder.AddApplicationServices();

var app = builder.Build();

app.UseDefaultOpenApi();
app.MapDefaultEndpoints();

app.UseAuthentication();
app.UseAuthorization();

app.MapBranchApi();

app.Run();
