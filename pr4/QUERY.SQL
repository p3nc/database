SELECT 'Good', COUNT(*) FROM Good
UNION ALL
SELECT 'Client', COUNT(*) FROM Client
UNION ALL
SELECT 'Natural_person', COUNT(*) FROM Natural_person
UNION ALL
SELECT 'Legal_entity', COUNT(*) FROM Legal_entity
UNION ALL
SELECT 'Good_orders', COUNT(*) FROM Good_orders;


SELECT 
    MIN(Price) AS Min_Price, 
    MAX(Price) AS Max_Price 
FROM Good;
SELECT AVG(Price) AS Average_Price FROM Good;
SELECT SUM(Available_goods) AS Total_Available FROM Good;


SELECT 
    Good_id, 
    Name, 
    Price, 
    RANK() OVER (ORDER BY Price DESC) AS Price_Rank 
FROM Good;
SELECT 
    Name, 
    Price, 
    AVG(Price) OVER () AS Avg_Price 
FROM Good;
SELECT 
    Good_id, 
    Name, 
    Available_goods, 
    SUM(Available_goods) OVER (ORDER BY Good_id) AS Cumulative_Sum 
FROM Good;

SELECT 
    Name, 
    UPPER(Name) AS Upper_Name 
FROM Good;
SELECT 
    Name, 
    LEN(Name) AS Name_Length 
FROM Good;
SELECT 
    Name, 
    Price, 
    CONCAT(Name, ' - ', Price, ' грн') AS Product_Info 
FROM Good;

SELECT Order_id, Good_id, Date, Status, Amount, Client_id
FROM Good_orders
WHERE Date >= DATEADD(MONTH, -1, GETDATE());

SELECT Good_id, COUNT(Order_id) AS Order_count
FROM Good_orders
WHERE YEAR(Date) = YEAR(GETDATE())
GROUP BY Good_id;

SELECT Order_id, Good_id, Date, Status, Amount, Client_id
FROM Good_orders
WHERE MONTH(Date) = MONTH(GETDATE()) AND YEAR(Date) = YEAR(GETDATE());
