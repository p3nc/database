FROM mcr.microsoft.com/mssql/server:2022-latest

# Встановлюємо змінні середовища
ENV ACCEPT_EULA=Y
ENV MSSQL_PID=Developer

# Встановлюємо робочу директорію
WORKDIR /docker-entrypoint-initdb.d

# Відкриваємо порт
EXPOSE 1433 