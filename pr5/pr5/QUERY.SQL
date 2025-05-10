-- Task 1: Create recommended indexes for query support
PRINT '=== Task 1: Creating recommended indexes for queries ===';

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Good_Price' AND object_id = OBJECT_ID('Good'))
    CREATE NONCLUSTERED INDEX IX_Good_Price ON Good(Price);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Good_Good_id' AND object_id = OBJECT_ID('Good'))
    CREATE NONCLUSTERED INDEX IX_Good_Good_id ON Good(Good_id);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Client_Client_id' AND object_id = OBJECT_ID('Client'))
    CREATE NONCLUSTERED INDEX IX_Client_Client_id ON Client(Client_id);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Client_Type' AND object_id = OBJECT_ID('Client'))
    CREATE NONCLUSTERED INDEX IX_Client_Type ON Client(Type);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Natural_person_Client_id' AND object_id = OBJECT_ID('Natural_person'))
    CREATE NONCLUSTERED INDEX IX_Natural_person_Client_id ON Natural_person(Client_id);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Legal_entity_Client_id' AND object_id = OBJECT_ID('Legal_entity'))
    CREATE NONCLUSTERED INDEX IX_Legal_entity_Client_id ON Legal_entity(Client_id);
GO

-- Example query with filtering
PRINT '=== Example query with filtering ===';
SELECT 
    go.Order_id,
    g.Name AS Good_name,
    g.Price,
    go.Amount,
    go.Date,
    c.Type AS Client_type
FROM 
    Good_orders go
    INNER JOIN Good g ON go.Good_id = g.Good_id
    INNER JOIN Client c ON go.Client_id = c.Client_id
WHERE 
    go.Status = 'Completed'
    AND g.Price > 50
ORDER BY 
    go.Date DESC;
GO

-- Task 2: Create clustered index
PRINT '=== Task 2: Creating clustered index ===';
-- Check if a clustered index exists
IF EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('Good_orders') AND type = 1)
BEGIN
    PRINT 'Clustered index already exists on Good_orders. Skipping creation.';
END
ELSE
BEGIN
    -- Drop primary key if it exists and recreate as nonclustered
    IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'PK__Good_ord__F1FF8453E7822164' AND object_id = OBJECT_ID('Good_orders'))
    BEGIN
        ALTER TABLE Good_orders DROP CONSTRAINT PK__Good_ord__F1FF8453E7822164;
        ALTER TABLE Good_orders ADD CONSTRAINT PK__Good_ord__F1FF8453E7822164 PRIMARY KEY NONCLUSTERED (Order_id);
    END
    -- Create clustered index
    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Good_orders_Date' AND object_id = OBJECT_ID('Good_orders'))
        CREATE CLUSTERED INDEX IX_Good_orders_Date ON Good_orders(Date);
END
GO

-- Task 3: Create nonclustered index
PRINT '=== Task 3: Creating nonclustered index ===';
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Good_orders_Status_Client_id' AND object_id = OBJECT_ID('Good_orders'))
    CREATE NONCLUSTERED INDEX IX_Good_orders_Status_Client_id ON Good_orders(Status, Client_id);
GO

-- Task 4: Create unique index
PRINT '=== Task 4: Creating unique index ===';
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Natural_person_Email_Unique' AND object_id = OBJECT_ID('Natural_person'))
    CREATE UNIQUE NONCLUSTERED INDEX IX_Natural_person_Email_Unique ON Natural_person(Email);
GO

-- Task 5: Create index with included columns
PRINT '=== Task 5: Creating index with included columns ===';
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Good_orders_Status_Date_Include' AND object_id = OBJECT_ID('Good_orders'))
    CREATE NONCLUSTERED INDEX IX_Good_orders_Status_Date_Include
    ON Good_orders(Status, Date DESC)
    INCLUDE (Order_id, Amount, Client_id);
GO

-- Task 6: Create filtered index
PRINT '=== Task 6: Creating filtered index ===';
SET QUOTED_IDENTIFIER ON;
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Good_orders_Status_Pending' AND object_id = OBJECT_ID('Good_orders'))
    CREATE NONCLUSTERED INDEX IX_Good_orders_Status_Pending
    ON Good_orders(Status)
    WHERE Status = 'Pending';
GO

-- Task 7: Analyze index fragmentation
PRINT '=== Task 7: Analyzing index fragmentation ===';
SELECT 
    t.name AS Table_name,
    i.name AS Index_name,
    i.index_id,
    i.type_desc AS Index_type,
    ps.avg_fragmentation_in_percent,
    ps.fragment_count,
    ps.page_count,
    ps.avg_page_space_used_in_percent,
    ps.record_count
FROM 
    sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') AS ps
    INNER JOIN sys.tables AS t ON ps.object_id = t.object_id
    INNER JOIN sys.indexes AS i ON ps.object_id = i.object_id AND ps.index_id = i.index_id
WHERE 
    ps.database_id = DB_ID()
    AND ps.page_count > 0
ORDER BY 
    t.name, i.name;
GO

-- Task 8: Reorganize index
PRINT '=== Task 8: Reorganizing index ===';
ALTER INDEX IX_Good_orders_Status_Client_id ON Good_orders REORGANIZE;
GO

-- Task 9: Rebuild index
PRINT '=== Task 9: Rebuilding index ===';
ALTER INDEX IX_Good_orders_Status_Date_Include ON Good_orders REBUILD WITH (ONLINE = ON);
GO

-- Task 10: Drop unused index
PRINT '=== Task 10: Dropping index ===';
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Good_orders_Status_Pending' AND object_id = OBJECT_ID('Good_orders'))
    DROP INDEX IX_Good_orders_Status_Pending ON Good_orders;
GO

-- Task 11: Compare query performance before and after index creation
PRINT '=== Task 11: Comparing query performance ===';
SET STATISTICS TIME ON;
GO

-- Step 1: Execute query without index
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Good_orders_Status_Date_Include' AND object_id = OBJECT_ID('Good_orders'))
    DROP INDEX IX_Good_orders_Status_Date_Include ON Good_orders;
GO

PRINT '=== Query without index ===';
GO
SET SHOWPLAN_TEXT ON;
GO
SELECT 
    go.Order_id,
    g.Name AS Good_name,
    g.Price,
    go.Amount,
    go.Date,
    c.Type AS Client_type
FROM 
    Good_orders go
    INNER JOIN Good g ON go.Good_id = g.Good_id
    INNER JOIN Client c ON go.Client_id = c.Client_id
WHERE 
    go.Status = 'Completed'
    AND g.Price > 50
ORDER BY 
    go.Date DESC;
GO
SET SHOWPLAN_TEXT OFF;
GO

-- Step 2: Create index
CREATE NONCLUSTERED INDEX IX_Good_orders_Status_Date_Include
ON Good_orders(Status, Date DESC)
INCLUDE (Order_id, Amount, Client_id);
GO

PRINT '=== Query with index ===';
GO
SET SHOWPLAN_TEXT ON;
GO
SELECT 
    go.Order_id,
    g.Name AS Good_name,
    g.Price,
    go.Amount,
    go.Date,
    c.Type AS Client_type
FROM 
    Good_orders go
    INNER JOIN Good g ON go.Good_id = g.Good_id
    INNER JOIN Client c ON go.Client_id = c.Client_id
WHERE 
    go.Status = 'Completed'
    AND g.Price > 50
ORDER BY 
    go.Date DESC;
GO
SET SHOWPLAN_TEXT OFF;
GO

SET STATISTICS TIME OFF;
GO

-- Task 12: Create workload for Database Engine Tuning Advisor
PRINT '=== Task 12: Creating workload for DTA ===';
SELECT 
    go.Order_id,
    g.Name AS Good_name,
    g.Price,
    go.Amount,
    go.Date,
    c.Type AS Client_type
INTO #TempWorkload
FROM 
    Good_orders go
    INNER JOIN Good g ON go.Good_id = g.Good_id
    INNER JOIN Client c ON go.Client_id = c.Client_id
WHERE 
    go.Status = 'Completed'
    AND g.Price > 50
ORDER BY 
    go.Date DESC;
GO

DROP TABLE #TempWorkload;
GO

-- Task 13: Audit all indexes in the database
PRINT '=== Task 13: Auditing all indexes ===';
SELECT
    DB_NAME() AS Database_Name,
    OBJECT_NAME(i.[object_id]) AS Table_Name,
    i.name AS Index_Name,
    i.type_desc AS Index_Type,
    CASE WHEN i.is_unique = 1 THEN 'Yes' ELSE 'No' END AS Is_Unique,
    ps.avg_fragmentation_in_percent AS Fragmentation_Percent,
    ps.page_count AS Page_Count
FROM
    sys.indexes AS i
INNER JOIN
    sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') AS ps
    ON i.[object_id] = ps.[object_id] AND i.index_id = ps.index_id
WHERE
    i.type > 0 AND i.is_hypothetical = 0
ORDER BY
    ps.avg_fragmentation_in_percent DESC;
GO