# Stage 1: Build the application
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build

# Set the working directory
WORKDIR /src

# Copy csproj and restore dependencies (this is done to leverage Docker cache)
COPY *.csproj ./
RUN dotnet restore

# Copy the rest of the source code
COPY . .

# Build the application
RUN dotnet publish -c Release -o /app/publish --no-restore

# Stage 2: Create the runtime image
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime

# Install curl for health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Create a non-root user to run the application
RUN useradd -m -u 1000 -s /bin/bash dotnetuser

# Set the working directory
WORKDIR /app

# Copy the published application from the build stage
COPY --from=build /app/publish .

# Change ownership of the application files
RUN chown -R dotnetuser:dotnetuser /app

# Switch to the non-root user
USER dotnetuser

# Configure ASP.NET Core to listen on the PORT environment variable
ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production
ENV PORT=8080
EXPOSE $PORT

# Enable .NET 8 performance features
ENV DOTNET_EnableDiagnostics=0
ENV DOTNET_gcServer=1

# Run the application
ENTRYPOINT ["dotnet", "YourApp.dll"]
