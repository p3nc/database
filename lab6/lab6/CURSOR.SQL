USE ShopDB;
GO

-- Перевірка або створення клієнта і товару
IF NOT EXISTS (SELECT 1 FROM Client WHERE Client_id = 1)
    INSERT INTO Client (Type) VALUES ('Individual');

IF NOT EXISTS (SELECT 1 FROM Good WHERE Good_id = 1)
    INSERT INTO Good (Name, Discription, Price, Available_goods)
    VALUES ('Smartphone', 'Latest model', 800.00, 100);
GO

-- Завдання 3: Транзакція з двома операціями та умовою для ROLLBACK
BEGIN TRAN;
    INSERT INTO Good (Name, Discription, Price, Available_goods)
    VALUES ('Laptop', 'High-performance laptop', 1200.00, 50);
    
    IF (SELECT COUNT(*) FROM Client WHERE Client_id = 1) = 0
    BEGIN
        PRINT 'Error: Client_id 1 does not exist. Transaction is rolled back.';
        ROLLBACK;
    END
    ELSE
    BEGIN
        INSERT INTO Good_orders (Good_id, Date, Status, Amount, Client_id)
        VALUES (SCOPE_IDENTITY(), '2025-05-10', 'Pending', 5, 1);
        COMMIT;
    END;
GO

-- Завдання 4: Перевірка @@ERROR для керування транзакцією
BEGIN TRAN;
    UPDATE Good_orders 
    SET Amount = 10 
    WHERE Good_id = 999;

    IF @@ERROR <> 0
        ROLLBACK;
    ELSE
        COMMIT;
GO

-- Завдання 5: Використання TRY...CATCH у транзакціях
BEGIN TRAN;
BEGIN TRY
    IF EXISTS (SELECT 1 FROM Good_orders WHERE Order_id = 1)
    BEGIN
        DELETE FROM Good_orders WHERE Order_id = 1;
        PRINT 'Removed existing order with Order_id = 1.';
    END;

    SET IDENTITY_INSERT Good_orders ON;
    INSERT INTO Good_orders (Order_id, Good_id, Date, Status, Amount, Client_id)
    VALUES (1, 1, '2025-05-10', 'Pending', 5, 1);
    SET IDENTITY_INSERT Good_orders OFF;
    PRINT 'Inserted order with Order_id = 1 to ensure foreign key violation.';

    IF EXISTS (SELECT 1 FROM Client WHERE Client_id = 999)
    BEGIN
        DELETE FROM Client WHERE Client_id = 999;
        PRINT 'Removed Client_id = 999 to ensure foreign key violation.';
    END;

    PRINT 'Attempting to update Client_id to 999...';
    UPDATE Good_orders 
    SET Client_id = 999
    WHERE Order_id = 1;
    COMMIT;
END TRY
BEGIN CATCH
    ROLLBACK;
    IF @@TRANCOUNT = 0
        SET IDENTITY_INSERT Good_orders OFF;
    PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Завдання 6: Транзакція для вставки 100,000 рядків (масова вставка)
DELETE FROM Good_orders;

IF NOT EXISTS (SELECT 1 FROM Client WHERE Client_id = 1)
    INSERT INTO Client (Type) VALUES ('Individual');

IF NOT EXISTS (SELECT 1 FROM Good WHERE Good_id = 1)
    INSERT INTO Good (Name, Discription, Price, Available_goods)
    VALUES ('Smartphone', 'Latest model', 800.00, 100);

DECLARE @Orders TABLE (
    Good_id INT,
    Date DATE,
    Status VARCHAR(50),
    Amount INT,
    Client_id INT
);

SET NOCOUNT ON; 
DECLARE @i INT = 1;
WHILE @i <= 100000
BEGIN
    INSERT INTO @Orders (Good_id, Date, Status, Amount, Client_id)
    VALUES (1, DATEADD(DAY, @i % 365, '2025-01-01'), 'Pending', (@i % 5) + 1, 1);
    SET @i = @i + 1;
END;
SET NOCOUNT OFF;

BEGIN TRAN;
    INSERT INTO Good_orders (Good_id, Date, Status, Amount, Client_id)
    SELECT Good_id, Date, Status, Amount, Client_id
    FROM @Orders;
COMMIT;
SET NOCOUNT OFF;
PRINT 'Inserted 100,000 rows into Good_orders.';
GO

-- Завдання 7: Модифікація процедури з фіксацією часу виконання
CREATE OR ALTER PROCEDURE GetOrdersByClient
    @ClientId INT
AS
BEGIN
    DECLARE @StartTime DATETIME = GETDATE();
    PRINT 'Start time: ' + CONVERT(VARCHAR, @StartTime, 121);

    SELECT o.Order_id, o.Date, o.Status, o.Amount, g.Name
    FROM Good_orders o
    JOIN Good g ON o.Good_id = g.Good_id
    WHERE o.Client_id = @ClientId;

    DECLARE @EndTime DATETIME = GETDATE();
    PRINT 'End time: ' + CONVERT(VARCHAR, @EndTime, 121);
    PRINT 'Execution time (ms): ' + CAST(DATEDIFF(MILLISECOND, @StartTime, @EndTime) AS VARCHAR);
END;

EXEC GetOrdersByClient @ClientId = 1;
GO

-- Завдання 8: Виконання складного запиту без індексу
PRINT 'Starting Task 8: Query without index...';
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;
DECLARE @StartTime DATETIME = GETDATE();

SELECT c.Client_id, c.Type, COUNT(o.Order_id) AS OrderCount, SUM(CAST(o.Amount * g.Price AS NUMERIC(15,2))) AS TotalCost
FROM Client c
JOIN Good_orders o ON c.Client_id = o.Client_id
JOIN Good g ON o.Good_id = g.Good_id
WHERE o.Date >= '2025-01-01' AND o.Status = 'Pending'
GROUP BY c.Client_id, c.Type
ORDER BY TotalCost DESC;

DECLARE @EndTime DATETIME = GETDATE();
PRINT 'Execution time without index (ms): ' + CAST(DATEDIFF(MILLISECOND, @StartTime, @EndTime) AS VARCHAR);
PRINT 'Completed Task 8.';
GO

-- Завдання 9: Виконання складного запиту з індексом
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Good_orders_Date_Status')
    CREATE NONCLUSTERED INDEX IX_Good_orders_Date_Status
    ON Good_orders (Date, Status)
    INCLUDE (Client_id, Good_id, Amount);

PRINT 'Starting Task 9: Query with index...';
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;
DECLARE @StartTime DATETIME = GETDATE();

SELECT c.Client_id, c.Type, COUNT(o.Order_id) AS OrderCount, SUM(CAST(o.Amount * g.Price AS NUMERIC(15,2))) AS TotalCost
FROM Client c
JOIN Good_orders o ON c.Client_id = o.Client_id
JOIN Good g ON o.Good_id = g.Good_id
WHERE o.Date >= '2025-01-01' AND o.Status = 'Pending'
GROUP BY c.Client_id, c.Type
ORDER BY TotalCost DESC;

DECLARE @EndTime DATETIME = GETDATE();
PRINT 'Execution time with index (ms): ' + CAST(DATEDIFF(MILLISECOND, @StartTime, @EndTime) AS VARCHAR);
PRINT 'Completed Task 9.';
GO

-- Завдання 10: Виконання складного запиту з курсором
DECLARE @ClientId INT, @Type VARCHAR(50), @OrderCount INT, @TotalCost NUMERIC(15,2);
DECLARE @StartTime DATETIME = GETDATE();
DECLARE @ErrorMsg NVARCHAR(4000);

BEGIN TRY
    PRINT 'Starting Task 10: Query with cursor...';
    DECLARE client_cursor CURSOR FOR
    SELECT c.Client_id, c.Type, COUNT(o.Order_id) AS OrderCount, SUM(CAST(o.Amount * g.Price AS NUMERIC(15,2))) AS TotalCost
    FROM Client c
    JOIN Good_orders o ON c.Client_id = o.Client_id
    JOIN Good g ON o.Good_id = g.Good_id
    WHERE o.Date >= '2025-01-01' AND o.Status = 'Pending'
    GROUP BY c.Client_id, c.Type;

    OPEN client_cursor;
    FETCH NEXT FROM client_cursor INTO @ClientId, @Type, @OrderCount, @TotalCost;

    PRINT 'Client_id | Type | OrderCount | TotalCost';
    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT CAST(@ClientId AS VARCHAR) + ' | ' + @Type + ' | ' + CAST(@OrderCount AS VARCHAR) + ' | ' + CAST(@TotalCost AS VARCHAR);
        FETCH NEXT FROM client_cursor INTO @ClientId, @Type, @OrderCount, @TotalCost;
    END;

    CLOSE client_cursor;
    DEALLOCATE client_cursor;
    PRINT 'Completed Task 10.';
END TRY
BEGIN CATCH
    SET @ErrorMsg = ERROR_MESSAGE();
    IF CURSOR_STATUS('global', 'client_cursor') >= 0
    BEGIN
        CLOSE client_cursor;
        DEALLOCATE client_cursor;
    END;
    PRINT 'Error in cursor: ' + @ErrorMsg;
END CATCH;

DECLARE @EndTime DATETIME = GETDATE();
PRINT 'Execution time with cursor (ms): ' + CAST(DATEDIFF(MILLISECOND, @StartTime, @EndTime) AS VARCHAR);
GO

-- Завдання 11: Модифікація запиту з курсором без DEALLOCATE між виконаннями
DECLARE @ClientId INT, @Type VARCHAR(50), @OrderCount INT, @TotalCost NUMERIC(15,2);
DECLARE @StartTime DATETIME = GETDATE();
DECLARE @ErrorMsg NVARCHAR(4000);

BEGIN TRY
    PRINT 'Starting Task 11: Query with cursor (two runs)...';
    DECLARE client_cursor CURSOR FOR
    SELECT c.Client_id, c.Type, COUNT(o.Order_id) AS OrderCount, SUM(CAST(o.Amount * g.Price AS NUMERIC(15,2))) AS TotalCost
    FROM Client c
    JOIN Good_orders o ON c.Client_id = o.Client_id
    JOIN Good g ON o.Good_id = g.Good_id
    WHERE o.Date >= '2025-01-01' AND o.Status = 'Pending'
    GROUP BY c.Client_id, c.Type;

    OPEN client_cursor;
    FETCH NEXT FROM client_cursor INTO @ClientId, @Type, @OrderCount, @TotalCost;

    PRINT 'First execution:';
    PRINT 'Client_id | Type | OrderCount | TotalCost';
    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT CAST(@ClientId AS VARCHAR) + ' | ' + @Type + ' | ' + CAST(@OrderCount AS VARCHAR) + ' | ' + CAST(@TotalCost AS VARCHAR);
        FETCH NEXT FROM client_cursor INTO @ClientId, @Type, @OrderCount, @TotalCost;
    END;

    CLOSE client_cursor;
    OPEN client_cursor;
    FETCH NEXT FROM client_cursor INTO @ClientId, @Type, @OrderCount, @TotalCost;

    PRINT 'Second execution:';
    PRINT 'Client_id | Type | OrderCount | TotalCost';
    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT CAST(@ClientId AS VARCHAR) + ' | ' + @Type + ' | ' + CAST(@OrderCount AS VARCHAR) + ' | ' + CAST(@TotalCost AS VARCHAR);
        FETCH NEXT FROM client_cursor INTO @ClientId, @Type, @OrderCount, @TotalCost;
    END;

    CLOSE client_cursor;
    DEALLOCATE client_cursor;
    PRINT 'Completed Task 11.';
END TRY
BEGIN CATCH
    SET @ErrorMsg = ERROR_MESSAGE();
    IF CURSOR_STATUS('global', 'client_cursor') >= 0
    BEGIN
        CLOSE client_cursor;
        DEALLOCATE client_cursor;
    END;
    PRINT 'Error in cursor: ' + @ErrorMsg;
END CATCH;

DECLARE @EndTime DATETIME = GETDATE();
PRINT 'Execution time with cursor (two runs, ms): ' + CAST(DATEDIFF(MILLISECOND, @StartTime, @EndTime) AS VARCHAR);
GO