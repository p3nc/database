-- Видалення всіх зовнішніх ключів (якщо є)
DECLARE @sql NVARCHAR(MAX) = '';

-- Генерація запитів для видалення зовнішніх ключів
SELECT @sql = @sql + 'ALTER TABLE ' + QUOTENAME(fk.name) + ' DROP CONSTRAINT ' + QUOTENAME(fk.name) + ';'
FROM sys.foreign_keys AS fk;

-- Виконання запитів для видалення зовнішніх ключів
EXEC sp_executesql @sql;

-- Тепер можна видаляти таблиці
DECLARE @dropTables NVARCHAR(MAX) = '';

-- Генерація запитів для видалення всіх таблиць
SELECT @dropTables = @dropTables + 'DROP TABLE IF EXISTS ' + QUOTENAME(name) + ';'
FROM sys.tables;

-- Виконання запитів для видалення таблиць
EXEC sp_executesql @dropTables;
