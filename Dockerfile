FROM mcr.microsoft.com/dotnet/core/aspnet:3.1 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/core/sdk:3.1 AS build
WORKDIR /src
COPY ["ContainersForDevs.csproj", "./"]
RUN dotnet restore "./ContainersForDevs.csproj"
COPY . .
WORKDIR "/src/."
RUN dotnet build "ContainersForDevs.csproj" -c Debug -o /app/build

FROM build AS publish
RUN dotnet publish "ContainersForDevs.csproj" -c Debug -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "ContainersForDevs.dll"]
