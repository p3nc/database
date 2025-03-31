FROM mcr.microsoft.com/mssql/server:2022-latest

# Встановлюємо змінні середовища
ENV ACCEPT_EULA=Y
ENV MSSQL_PID=Developer

# Копіюємо SQL скрипти
COPY SETUP.SQL /docker-entrypoint-initdb.d/
COPY INSERT.SQL /docker-entrypoint-initdb.d/
COPY UPDATE.SQL /docker-entrypoint-initdb.d/
COPY QUERY.SQL /docker-entrypoint-initdb.d/

# Встановлюємо робочу директорію
WORKDIR /docker-entrypoint-initdb.d

# Відкриваємо порт
EXPOSE 1433 