CREATE FUNCTION dbo.CalculateDiscount(@client_id INT, @total_amount DECIMAL(10,2))
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @discount DECIMAL(10,2) = 0;
    DECLARE @client_type VARCHAR(50);
    
    SELECT @client_type = Type FROM Client WHERE Client_id = @client_id;
    
    IF @client_type = 'Natural'
        SET @discount = @total_amount * 0.05;
    
    ELSE IF @client_type = 'Legal' AND @total_amount > 1000
        SET @discount = @total_amount * 0.1;
    
    RETURN @discount;
END;
GO

SELECT 
    Order_id, 
    Amount, 
    Price, 
    (Amount * Price) AS Total,
    dbo.CalculateDiscount(Client_id, Amount * Price) AS Discount,
    (Amount * Price - dbo.CalculateDiscount(Client_id, Amount * Price)) AS FinalPrice
FROM Good_orders GO
JOIN Good G ON GO.Good_id = G.Good_id
WHERE Order_id = 5;
GO


CREATE FUNCTION dbo.CheckAvailability(@good_id INT, @requested_amount INT)
RETURNS VARCHAR(50)
AS
BEGIN
    DECLARE @available INT;
    DECLARE @result VARCHAR(50);
    
    SELECT @available = Available_goods FROM Good WHERE Good_id = @good_id;
    
    IF @available >= @requested_amount
        SET @result = 'Available';
    ELSE IF @available > 0
        SET @result = 'Partial (' + CAST(@available AS VARCHAR) + ' available)';
    ELSE
        SET @result = 'Out of stock';
    
    RETURN @result;
END;
GO

SELECT 
    G.Name, 
    G.Available_goods, 
    GO.Amount AS Requested,
    dbo.CheckAvailability(G.Good_id, GO.Amount) AS Availability
FROM Good_orders GO
JOIN Good G ON GO.Good_id = G.Good_id;
GO


CREATE FUNCTION dbo.FormatClientAddress(@client_id INT)
RETURNS VARCHAR(500)
AS
BEGIN
    DECLARE @address VARCHAR(500);
    DECLARE @client_type VARCHAR(50);
    
    SELECT @client_type = Type FROM Client WHERE Client_id = @client_id;
    
    IF @client_type = 'Natural'
        SELECT @address = CONCAT(Street, ', ', House) 
        FROM Natural_person 
        WHERE Client_id = @client_id;
    ELSE
        SELECT @address = CONCAT(Company_street, ', ', Company_street_number) 
        FROM Legal_entity 
        WHERE Client_id = @client_id;
    
    RETURN ISNULL(@address, 'Address not specified');
END;
GO

SELECT 
    C.Client_id,
    CASE 
        WHEN C.Type = 'Natural' THEN NP.Name
        ELSE LE.Company_name
    END AS ClientName,
    dbo.FormatClientAddress(C.Client_id) AS FullAddress
FROM Client C
LEFT JOIN Natural_person NP ON C.Client_id = NP.Client_id
LEFT JOIN Legal_entity LE ON C.Client_id = LE.Client_id;
GO


CREATE FUNCTION dbo.GetGoodsInPriceRange
(
    @minPrice DECIMAL(10,2),
    @maxPrice DECIMAL(10,2)
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        Good_id,
        Name,
        Price,
        Available_goods,
        CASE 
            WHEN Price < @minPrice + (@maxPrice - @minPrice)/3 THEN 'Low'
            WHEN Price < @minPrice + 2*(@maxPrice - @minPrice)/3 THEN 'Medium'
            ELSE 'High'
        END AS PriceCategory
    FROM Good
    WHERE Price BETWEEN @minPrice AND @maxPrice
);
GO

SELECT * FROM dbo.GetGoodsInPriceRange(100, 1000);
GO


CREATE FUNCTION dbo.GetClientActiveOrders
(
    @clientId INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        o.Order_id,
        g.Name AS GoodName,
        o.Date,
        o.Amount,
        g.Price,
        o.Amount * g.Price AS TotalSum,
        o.Status
    FROM Good_orders o
    JOIN Good g ON o.Good_id = g.Good_id
    WHERE o.Client_id = @clientId 
    AND o.Status NOT IN ('Completed', 'Cancelled')
);
GO

SELECT * FROM dbo.GetClientActiveOrders(5);
GO


CREATE FUNCTION dbo.GetSalesAnalysis
(
    @startDate DATE,
    @endDate DATE
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        g.Good_id,
        g.Name,
        SUM(o.Amount) AS TotalSold,
        SUM(o.Amount * g.Price) AS TotalRevenue,
        AVG(o.Amount) AS AvgOrderAmount,
        COUNT(o.Order_id) AS OrderCount,
        RANK() OVER (ORDER BY SUM(o.Amount * g.Price) DESC) AS RevenueRank
    FROM Good_orders o
    JOIN Good g ON o.Good_id = g.Good_id
    WHERE o.Date BETWEEN @startDate AND @endDate
    AND o.Status = 'Completed'
    GROUP BY g.Good_id, g.Name
);
GO

SELECT * FROM dbo.GetSalesAnalysis('2024-01-01', '2024-12-31')
WHERE RevenueRank <= 10
ORDER BY RevenueRank;
GO


CREATE FUNCTION dbo.AnalyzeClientActivity
(
    @daysPeriod INT
)
RETURNS @result TABLE
(
    Client_id INT,
    ClientName NVARCHAR(255),
    ClientType NVARCHAR(50),
    TotalOrders INT,
    TotalSpent DECIMAL(15,2),
    AvgOrderValue DECIMAL(15,2),
    LastOrderDate DATE,
    ActivityLevel NVARCHAR(20)
)
AS
BEGIN
    INSERT INTO @result
    SELECT 
        c.Client_id,
        CASE 
            WHEN c.Type = 'Natural' THEN np.Name
            ELSE le.Company_name
        END AS ClientName,
        c.Type AS ClientType,
        COUNT(o.Order_id) AS TotalOrders,
        SUM(o.Amount * g.Price) AS TotalSpent,
        CASE 
            WHEN COUNT(o.Order_id) > 0 THEN SUM(o.Amount * g.Price) / COUNT(o.Order_id)
            ELSE 0
        END AS AvgOrderValue,
        MAX(o.Date) AS LastOrderDate,
        'Normal' AS ActivityLevel
    FROM Client c
    LEFT JOIN Natural_person np ON c.Client_id = np.Client_id AND c.Type = 'Natural'
    LEFT JOIN Legal_entity le ON c.Client_id = le.Client_id AND c.Type = 'Legal'
    LEFT JOIN Good_orders o ON c.Client_id = o.Client_id
    LEFT JOIN Good g ON o.Good_id = g.Good_id
    WHERE o.Date >= DATEADD(DAY, -@daysPeriod, GETDATE())
    GROUP BY c.Client_id, c.Type, np.Name, le.Company_name;
    
    UPDATE @result
    SET ActivityLevel = CASE
        WHEN TotalOrders = 0 THEN 'Inactive'
        WHEN TotalOrders > 5 AND TotalSpent > 5000 THEN 'VIP'
        WHEN TotalOrders > 3 THEN 'Active'
        ELSE 'Occasional'
    END;
    
    RETURN;
END;
GO

SELECT * FROM dbo.AnalyzeClientActivity(30) ORDER BY TotalSpent DESC;
GO


CREATE FUNCTION dbo.GetInventoryReport
(
    @minStock INT = 0,
    @maxStock INT = 999999
)
RETURNS @report TABLE
(
    Good_id INT,
    GoodName NVARCHAR(255),
    CurrentStock INT,
    ReorderLevel INT,
    Status NVARCHAR(50),
    MonthsSupply DECIMAL(10,2),
    AvgMonthlySales DECIMAL(10,2)
)
AS
BEGIN
    DECLARE @avgSales TABLE (Good_id INT, AvgSales DECIMAL(10,2));
    
    INSERT INTO @avgSales
    SELECT 
        g.Good_id,
        ISNULL(SUM(o.Amount) / NULLIF(DATEDIFF(MONTH, MIN(o.Date), 0), 0) AS AvgSales
    FROM Good g
    LEFT JOIN Good_orders o ON g.Good_id = o.Good_id
    WHERE o.Date >= DATEADD(MONTH, -6, GETDATE())
    GROUP BY g.Good_id;
    
    INSERT INTO @report
    SELECT 
        g.Good_id,
        g.Name AS GoodName,
        g.Available_goods AS CurrentStock,
        CASE 
            WHEN g.Price < 100 THEN 20
            WHEN g.Price < 500 THEN 10
            ELSE 5
        END AS ReorderLevel,
        CASE
            WHEN g.Available_goods = 0 THEN 'Out of Stock'
            WHEN g.Available_goods <= 5 THEN 'Critical'
            WHEN g.Available_goods <= 10 THEN 'Low'
            ELSE 'OK'
        END AS Status,
        CASE
            WHEN a.AvgSales = 0 THEN 999
            ELSE g.Available_goods / a.AvgSales
        END AS MonthsSupply,
        a.AvgSales
    FROM Good g
    JOIN @avgSales a ON g.Good_id = a.Good_id
    WHERE g.Available_goods BETWEEN @minStock AND @maxStock;
    
    RETURN;
END;
GO

SELECT * FROM dbo.GetInventoryReport(0, 50) WHERE Status IN ('Critical', 'Low');
GO


CREATE FUNCTION dbo.AnalyzeSalesPerformance
(
    @startDate DATE,
    @endDate DATE,
    @minTotalSales DECIMAL(15,2) = 0
)
RETURNS @performance TABLE
(
    Good_id INT,
    GoodName NVARCHAR(255),
    Category NVARCHAR(50),
    TotalUnitsSold INT,
    TotalRevenue DECIMAL(15,2),
    AvgPrice DECIMAL(10,2),
    PercentOfTotalRevenue DECIMAL(5,2),
    PerformanceRating NVARCHAR(20)
)
AS
BEGIN
    DECLARE @totalRevenue DECIMAL(15,2);
    
    SELECT @totalRevenue = SUM(o.Amount * g.Price)
    FROM Good_orders o
    JOIN Good g ON o.Good_id = g.Good_id
    WHERE o.Date BETWEEN @startDate AND @endDate;
    
    INSERT INTO @performance
    SELECT 
        g.Good_id,
        g.Name AS GoodName,
        CASE
            WHEN g.Price < 100 THEN 'Budget'
            WHEN g.Price < 500 THEN 'Standard'
            ELSE 'Premium'
        END AS Category,
        SUM(o.Amount) AS TotalUnitsSold,
        SUM(o.Amount * g.Price) AS TotalRevenue,
        AVG(g.Price) AS AvgPrice,
        CASE 
            WHEN @totalRevenue > 0 THEN (SUM(o.Amount * g.Price) / @totalRevenue) * 100
            ELSE 0
        END AS PercentOfTotalRevenue,
        'Normal' AS PerformanceRating
    FROM Good_orders o
    JOIN Good g ON o.Good_id = g.Good_id
    WHERE o.Date BETWEEN @startDate AND @endDate
    GROUP BY g.Good_id, g.Name, g.Price
    HAVING SUM(o.Amount * g.Price) >= @minTotalSales;
    
    UPDATE @performance
    SET PerformanceRating = CASE
        WHEN PercentOfTotalRevenue > 10 THEN 'High'
        WHEN PercentOfTotalRevenue > 5 THEN 'Medium'
        ELSE 'Low'
    END;
    
    RETURN;
END;
GO

SELECT * FROM dbo.AnalyzeSalesPerformance('2024-01-01', '2024-12-31', 1000)
ORDER BY PercentOfTotalRevenue DESC;
GO


CREATE FUNCTION dbo.CalculateOrderTotalWithDiscount
(
    @orderId INT
)
RETURNS DECIMAL(15,2)
AS
BEGIN
    DECLARE @total DECIMAL(15,2);
    DECLARE @discount DECIMAL(5,2) = 0;
    DECLARE @clientType VARCHAR(50);
    
    SELECT @total = SUM(g.Price * o.Amount)
    FROM Good_orders o
    JOIN Good g ON o.Good_id = g.Good_id
    WHERE o.Order_id = @orderId;
    
    SELECT @clientType = c.Type
    FROM Client c
    JOIN Good_orders o ON c.Client_id = o.Client_id
    WHERE o.Order_id = @orderId;
    
    IF @clientType = 'Legal' AND @total > 5000
        SET @discount = 0.15;
    ELSE IF @clientType = 'Natural'
        SET @discount = 0.05;
    
    RETURN @total * (1 - @discount);
END;
GO

SELECT 
    Order_id,
    dbo.CalculateOrderTotalWithDiscount(Order_id) AS TotalWithDiscount
FROM Good_orders
WHERE Order_id = 5;
GO


CREATE FUNCTION dbo.GetLowStockItems
(
    @threshold INT = 10
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        g.Good_id,
        g.Name,
        g.Price,
        g.Available_goods AS CurrentStock,
        CASE 
            WHEN g.Available_goods = 0 THEN 'Out of Stock'
            WHEN g.Available_goods <= @threshold THEN 'Low Stock'
            ELSE 'In Stock'
        END AS StockStatus,
        (SELECT COUNT(*) FROM Good_orders o 
         WHERE o.Good_id = g.Good_id 
         AND o.Date >= DATEADD(MONTH, -3, GETDATE())) AS OrdersLast3Months
    FROM Good g
    WHERE g.Available_goods <= @threshold
);
GO

SELECT * FROM dbo.GetLowStockItems(5) ORDER BY CurrentStock ASC;
GO


CREATE FUNCTION dbo.AnalyzeCustomerBase
(
    @minOrders INT = 1,
    @timePeriodMonths INT = 12
)
RETURNS @analysis TABLE
(
    Client_id INT,
    ClientName NVARCHAR(255),
    ClientType NVARCHAR(50),
    TotalOrders INT,
    TotalSpent DECIMAL(15,2),
    AvgOrderValue DECIMAL(15,2),
    LastOrderDate DATE,
    DaysSinceLastOrder INT,
    CustomerSegment NVARCHAR(50)
)
AS
BEGIN
    INSERT INTO @analysis
    SELECT 
        c.Client_id,
        CASE 
            WHEN c.Type = 'Natural' THEN np.Name
            ELSE le.Company_name
        END AS ClientName,
        c.Type AS ClientType,
        COUNT(o.Order_id) AS TotalOrders,
        SUM(g.Price * o.Amount) AS TotalSpent,
        CASE WHEN COUNT(o.Order_id) > 0 
             THEN SUM(g.Price * o.Amount) / COUNT(o.Order_id)
             ELSE 0 
        END AS AvgOrderValue,
        MAX(o.Date) AS LastOrderDate,
        DATEDIFF(DAY, MAX(o.Date), GETDATE()) AS DaysSinceLastOrder,
        'Regular' AS CustomerSegment
    FROM Client c
    LEFT JOIN Natural_person np ON c.Client_id = np.Client_id AND c.Type = 'Natural'
    LEFT JOIN Legal_entity le ON c.Client_id = le.Client_id AND c.Type = 'Legal'
    LEFT JOIN Good_orders o ON c.Client_id = o.Client_id
    LEFT JOIN Good g ON o.Good_id = g.Good_id
    WHERE o.Date >= DATEADD(MONTH, -@timePeriodMonths, GETDATE())
    GROUP BY c.Client_id, c.Type, np.Name, le.Company_name
    HAVING COUNT(o.Order_id) >= @minOrders;
    
    UPDATE @analysis
    SET CustomerSegment = CASE
        WHEN TotalSpent > 10000 THEN 'VIP'
        WHEN TotalSpent > 5000 THEN 'Premium'
        WHEN DaysSinceLastOrder > 180 THEN 'Inactive'
        WHEN DaysSinceLastOrder > 90 THEN 'Lapsing'
        ELSE 'Active'
    END;
    
    RETURN;
END;
GO

SELECT * FROM dbo.AnalyzeCustomerBase(3, 6)
WHERE CustomerSegment IN ('VIP', 'Premium')
ORDER BY TotalSpent DESC;
GO


