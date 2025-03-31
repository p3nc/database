-- Створюємо базу даних
CREATE DATABASE LR3;
GO

USE LR3;
GO

-- Виконуємо скрипти налаштування та вставки даних
:r /docker-entrypoint-initdb.d/SETUP.SQL
:r /docker-entrypoint-initdb.d/INSERT.SQL
:r /docker-entrypoint-initdb.d/QUERY.SQL 