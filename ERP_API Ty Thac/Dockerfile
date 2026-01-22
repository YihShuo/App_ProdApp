FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
WORKDIR /app

COPY ./*.sln .
COPY ./ERP_API/*.csproj .
RUN dotnet restore ERP_API.csproj

COPY . .
RUN dotnet publish -c release -o out

FROM mcr.microsoft.com/dotnet/aspnet:7.0
WORKDIR /app
COPY --from=build /app/out .

EXPOSE 80
EXPOSE 443

RUN sed -i 's/TLSv1.2/TLSv1/g' /etc/ssl/openssl.cnf
RUN sed -i 's/CipherString = DEFAULT@SECLEVEL=2/CipherString = DEFAULT@SECLEVEL=1/g' /etc/ssl/openssl.cnf

ENTRYPOINT ["dotnet", "ERP_API.dll"]