-- Включаємо QUOTED_IDENTIFIER
SET QUOTED_IDENTIFIER ON;

-- 1. Некластеризований індекс на поле Date
CREATE NONCLUSTERED INDEX IX_Good_orders_Date
ON Good_orders(Date);

-- 2. Унікальний індекс на комбінацію Good_id + Client_id + Date
CREATE UNIQUE INDEX UX_Good_orders_Combination
ON Good_orders(Good_id, Client_id, Date);

-- 3. Індекс з включеними стовпцями (INCLUDE)
CREATE NONCLUSTERED INDEX IX_Good_orders_Client_WithStatus
ON Good_orders(Client_id)
INCLUDE (Status, Amount);

-- 4. Фільтрований індекс (тільки для завершених замовлень)
CREATE NONCLUSTERED INDEX IX_Good_orders_Completed
ON Good_orders(Status)
WHERE Status = 'Completed';

-- Вставка даних для 500 рядків
DECLARE @i INT = 1;
WHILE @i <= 500
BEGIN
    INSERT INTO Good_orders (Good_id, Date, Status, Amount, Client_id)
    VALUES (
        ABS(CHECKSUM(NEWID())) % 10 + 1,                     -- Random Good_id (1-10)
        DATEADD(DAY, -@i, GETDATE()),                        -- Зменшення дати
        CASE WHEN @i % 2 = 0 THEN 'Completed' ELSE 'Pending' END,
        ABS(CHECKSUM(NEWID())) % 50 + 1,                     -- Amount
        ABS(CHECKSUM(NEWID())) % 20 + 1                      -- Client_id
    );
    SET @i = @i + 1;
END;

-- Вставка даних для 1000 рядків
SET @i = 1;
WHILE @i <= 1000
BEGIN
    INSERT INTO Good_orders (Good_id, Date, Status, Amount, Client_id)
    VALUES (
        ABS(CHECKSUM(NEWID())) % 10 + 1,
        DATEADD(DAY, -@i, GETDATE()),
        CASE WHEN @i % 2 = 0 THEN 'Completed' ELSE 'Pending' END,
        ABS(CHECKSUM(NEWID())) % 50 + 1,
        ABS(CHECKSUM(NEWID())) % 20 + 1
    );
    SET @i = @i + 1;
END;

-- Вставка даних для 10 000 рядків
SET @i = 1;
WHILE @i <= 10000
BEGIN
    INSERT INTO Good_orders (Good_id, Date, Status, Amount, Client_id)
    VALUES (
        ABS(CHECKSUM(NEWID())) % 10 + 1,
        DATEADD(DAY, -@i, GETDATE()),
        CASE WHEN @i % 2 = 0 THEN 'Completed' ELSE 'Pending' END,
        ABS(CHECKSUM(NEWID())) % 50 + 1,
        ABS(CHECKSUM(NEWID())) % 20 + 1
    );
    SET @i = @i + 1;
END;


-- Увімкнення статистики часу виконання
SET STATISTICS TIME ON;

-- Запит 1: Пошук завершених замовлень
SELECT * FROM Good_orders WHERE Status = 'Completed';

-- Запит 2: Пошук за Client_id з відображенням включених полів
SELECT Client_id, Status, Amount FROM Good_orders WHERE Client_id = 5;

-- Запит 3: Пошук за датою
SELECT * FROM Good_orders WHERE Date BETWEEN '2024-01-01' AND '2024-12-31';

-- Вимкнення статистики часу виконання
SET STATISTICS TIME OFF;


-- Аудит індексів у базі даних --
DECLARE @TableName NVARCHAR(128);
DECLARE @IndexName NVARCHAR(128);
DECLARE @SQL NVARCHAR(MAX);

DECLARE index_cursor CURSOR FOR
SELECT 
    o.name AS TableName,
    i.name AS IndexName,
    ps.avg_fragmentation_in_percent AS FragPercent
FROM 
    sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ps
JOIN 
    sys.indexes i ON ps.object_id = i.object_id AND ps.index_id = i.index_id
JOIN 
    sys.objects o ON i.object_id = o.object_id
WHERE 
    i.name IS NOT NULL AND o.type = 'U';

OPEN index_cursor;
FETCH NEXT FROM index_cursor INTO @TableName, @IndexName, @SQL;

WHILE @@FETCH_STATUS = 0
BEGIN
    DECLARE @Frag FLOAT;
    SELECT @Frag = avg_fragmentation_in_percent
    FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID(@TableName), NULL, NULL, 'LIMITED')
    WHERE index_id = (SELECT index_id FROM sys.indexes WHERE name = @IndexName AND object_id = OBJECT_ID(@TableName));

    IF @Frag >= 30
        SET @SQL = 'ALTER INDEX [' + @IndexName + '] ON [' + @TableName + '] REBUILD;';
    ELSE IF @Frag >= 5
        SET @SQL = 'ALTER INDEX [' + @IndexName + '] ON [' + @TableName + '] REORGANIZE;';
    ELSE
        SET @SQL = '-- [' + @IndexName + '] on [' + @TableName + '] — фрагментація < 5%, нічого не робимо';

    PRINT @SQL;
    EXEC sp_executesql @SQL;

    FETCH NEXT FROM index_cursor INTO @TableName, @IndexName, @SQL;
END

CLOSE index_cursor;
DEALLOCATE index_cursor;


