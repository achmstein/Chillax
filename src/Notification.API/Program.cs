using Chillax.Notification.API.Apis;
using Chillax.Notification.API.Extensions;
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

app.MapNotificationApi();

app.Run();
