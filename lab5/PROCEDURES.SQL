-- Видалення процедур, якщо існують
DROP PROCEDURE IF EXISTS ##GetAllOrders;
DROP PROCEDURE IF EXISTS ##InsertOrder;
DROP PROCEDURE IF EXISTS ##GetOrdersByStatus;
DROP PROCEDURE IF EXISTS #GetLastOrders;
DROP PROCEDURE IF EXISTS #UpdateOrderStatus;
DROP PROCEDURE IF EXISTS #CountOrdersByStatus;
DROP PROCEDURE IF EXISTS AddOrderWithTransaction;
DROP PROCEDURE IF EXISTS AddRowsToGoodOrders;
DROP PROCEDURE IF EXISTS InsertGoodOrder;
GO

-- 1. ##GetAllOrders
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE ##GetAllOrders
AS
BEGIN
    SELECT * FROM Good_orders;
END;
GO

-- 2. ##InsertOrder
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE ##InsertOrder
    @Good_id INT,
    @Date DATE,
    @Status NVARCHAR(50),
    @Amount INT,
    @Client_id INT
AS
BEGIN
    INSERT INTO Good_orders (Good_id, Date, Status, Amount, Client_id)
    VALUES (@Good_id, @Date, @Status, @Amount, @Client_id);
END;
GO

-- 3. ##GetOrdersByStatus
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE ##GetOrdersByStatus
    @Status NVARCHAR(50)
AS
BEGIN
    SELECT * FROM Good_orders WHERE Status = @Status;
END;
GO

-- 4. #GetLastOrders
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE #GetLastOrders
AS
BEGIN
    SELECT TOP 10 * FROM Good_orders ORDER BY Date DESC;
END;
GO

-- 5. #UpdateOrderStatus
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE #UpdateOrderStatus
    @OrderId INT,
    @NewStatus NVARCHAR(50)
AS
BEGIN
    UPDATE Good_orders
    SET Status = @NewStatus
    WHERE Order_id = @OrderId;
END;
GO

-- 6. #CountOrdersByStatus
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE #CountOrdersByStatus
    @Status NVARCHAR(50)
AS
BEGIN
    SELECT COUNT(*) AS OrderCount FROM Good_orders WHERE Status = @Status;
END;
GO

-- 7. AddOrderWithTransaction
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AddOrderWithTransaction
    @Good_id INT,
    @Date DATE,
    @Status NVARCHAR(20),
    @Amount INT,
    @Client_id INT
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        INSERT INTO Good_orders (Good_id, Date, Status, Amount, Client_id)
        VALUES (@Good_id, @Date, @Status, @Amount, @Client_id);
        COMMIT TRANSACTION;
        PRINT 'Замовлення успішно додано';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT 'Сталася помилка, транзакцію скасовано. Опис помилки: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

-- 8. AddRowsToGoodOrders
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AddRowsToGoodOrders
    @NumRows INT
AS
BEGIN
    DECLARE @i INT = 1;

    IF @NumRows <= 0
    BEGIN
        PRINT 'Кількість рядків повинна бути більшою за 0';
        RETURN;
    END

    WHILE @i <= @NumRows
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
    END
    PRINT 'Рядки успішно додано';
END;
GO

-- 9. InsertGoodOrder
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE InsertGoodOrder
(
    @Good_id INT,
    @Date DATE,
    @Status VARCHAR(50),
    @Amount INT,
    @Client_id INT
)
AS
BEGIN
    DECLARE @NewOrderId INT;

    INSERT INTO Good_orders (Good_id, Date, Status, Amount, Client_id)
    VALUES (@Good_id, @Date, @Status, @Amount, @Client_id);

    SET @NewOrderId = SCOPE_IDENTITY();

    IF @NewOrderId IS NOT NULL
        RETURN @NewOrderId;
    ELSE
        RETURN NULL;
END;
GO