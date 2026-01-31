# Build stage
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Copy solution files and project files
COPY ["Directory.Build.props", "./"]
COPY ["Directory.Packages.props", "./"]
COPY ["src/Rooms.API/Rooms.API.csproj", "Rooms.API/"]
COPY ["src/Rooms.Domain/Rooms.Domain.csproj", "Rooms.Domain/"]
COPY ["src/Rooms.Infrastructure/Rooms.Infrastructure.csproj", "Rooms.Infrastructure/"]
COPY ["src/EventBus/EventBus.csproj", "EventBus/"]
COPY ["src/EventBusRabbitMQ/EventBusRabbitMQ.csproj", "EventBusRabbitMQ/"]
COPY ["src/IntegrationEventLogEF/IntegrationEventLogEF.csproj", "IntegrationEventLogEF/"]
COPY ["src/Chillax.ServiceDefaults/Chillax.ServiceDefaults.csproj", "Chillax.ServiceDefaults/"]
COPY ["src/Shared/", "Shared/"]

# Restore dependencies
RUN dotnet restore "Rooms.API/Rooms.API.csproj"

# Copy source code
COPY ["src/Rooms.API/", "Rooms.API/"]
COPY ["src/Rooms.Domain/", "Rooms.Domain/"]
COPY ["src/Rooms.Infrastructure/", "Rooms.Infrastructure/"]
COPY ["src/EventBus/", "EventBus/"]
COPY ["src/EventBusRabbitMQ/", "EventBusRabbitMQ/"]
COPY ["src/IntegrationEventLogEF/", "IntegrationEventLogEF/"]
COPY ["src/Chillax.ServiceDefaults/", "Chillax.ServiceDefaults/"]

# Build
WORKDIR /src/Rooms.API
RUN dotnet build -c Release -o /app/build

# Publish
RUN dotnet publish -c Release -o /app/publish /p:UseAppHost=false

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
EXPOSE 8080
EXPOSE 8081

COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "Rooms.API.dll"]
