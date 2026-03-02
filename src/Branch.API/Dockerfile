# Build stage
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Copy solution files and project files
COPY ["Directory.Build.props", "./"]
COPY ["Directory.Packages.props", "./"]
COPY ["src/Branch.API/Branch.API.csproj", "Branch.API/"]
COPY ["src/Chillax.ServiceDefaults/Chillax.ServiceDefaults.csproj", "Chillax.ServiceDefaults/"]
COPY ["src/Shared/", "Shared/"]

# Restore dependencies
RUN dotnet restore "Branch.API/Branch.API.csproj"

# Copy source code
COPY ["src/Branch.API/", "Branch.API/"]
COPY ["src/Chillax.ServiceDefaults/", "Chillax.ServiceDefaults/"]

# Build
WORKDIR /src/Branch.API
RUN dotnet build -c Release -o /app/build

# Publish
RUN dotnet publish -c Release -o /app/publish /p:UseAppHost=false

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
EXPOSE 8080
EXPOSE 8081

COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "Branch.API.dll"]
