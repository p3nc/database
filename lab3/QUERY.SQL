-- 1. Вибірка всіх замовлень разом із даними про клієнтів
SELECT 
    go.Order_id,
    c.Client_id,
    CASE 
        WHEN c.Type = 'Natural_person' THEN np.Name
        ELSE le.Company_name
    END AS Client_Name,
    g.Name AS Good_Name,
    go.Amount,
    go.Date,
    go.Status
FROM Good_orders go
JOIN Client c ON go.Client_id = c.Client_id
JOIN Good g ON go.Good_id = g.Good_id
LEFT JOIN Natural_person np ON c.Client_id = np.Client_id
LEFT JOIN Legal_entity le ON c.Client_id = le.Client_id;

-- 2. Підрахунок загальної кількості замовлених товарів кожним клієнтом
SELECT 
    c.Client_id,
    CASE 
        WHEN c.Type = 'Natural_person' THEN np.Name
        ELSE le.Company_name
    END AS Client_Name,
    COUNT(go.Order_id) AS Total_Orders,
    SUM(go.Amount) AS Total_Amount
FROM Client c
LEFT JOIN Good_orders go ON c.Client_id = go.Client_id
LEFT JOIN Natural_person np ON c.Client_id = np.Client_id
LEFT JOIN Legal_entity le ON c.Client_id = le.Client_id
GROUP BY c.Client_id, c.Type, np.Name, le.Company_name;

-- 3. Пошук клієнтів, які зробили замовлення на певний товар
SELECT DISTINCT
    c.Client_id,
    CASE 
        WHEN c.Type = 'Natural_person' THEN np.Name
        ELSE le.Company_name
    END AS Client_Name
FROM Client c
JOIN Good_orders go ON c.Client_id = go.Client_id
JOIN Good g ON go.Good_id = g.Good_id
LEFT JOIN Natural_person np ON c.Client_id = np.Client_id
LEFT JOIN Legal_entity le ON c.Client_id = le.Client_id
WHERE g.Name = 'Товар1';

-- 4. Використання UNION: список всіх клієнтів
SELECT Client_id, Name AS Client_Name, 'Natural_person' AS Type FROM Natural_person
UNION
SELECT Client_id, Company_name AS Client_Name, 'Legal_entity' AS Type FROM Legal_entity
ORDER BY Client_Name;

-- 5. Знаходження найбільш замовленого товару
SELECT TOP 1
    g.Name,
    COUNT(go.Order_id) AS Order_Count,
    SUM(go.Amount) AS Total_Amount
FROM Good g
JOIN Good_orders go ON g.Good_id = go.Good_id
GROUP BY g.Good_id, g.Name
ORDER BY Total_Amount DESC;

-- 6. Аналіз товарів за ціною та наявністю
SELECT 
    Name,
    Price,
    Available_goods,
    CASE 
        WHEN Price < 50 THEN 'Низька'
        WHEN Price BETWEEN 50 AND 100 THEN 'Середня'
        ELSE 'Висока'
    END AS Price_Category
FROM Good
ORDER BY Price DESC;

-- 7. Статистика замовлень за статусами
SELECT 
    Status,
    COUNT(*) AS Order_Count,
    SUM(Amount) AS Total_Amount,
    AVG(Amount) AS Avg_Amount
FROM Good_orders
GROUP BY Status;

-- 8. Аналіз клієнтів за типами
SELECT 
    c.Type,
    COUNT(DISTINCT c.Client_id) AS Client_Count,
    COUNT(go.Order_id) AS Order_Count,
    SUM(go.Amount) AS Total_Amount
FROM Client c
LEFT JOIN Good_orders go ON c.Client_id = go.Client_id
GROUP BY c.Type;

-- 9. Товари з низьким запасом
SELECT 
    Name,
    Available_goods,
    Price
FROM Good
WHERE Available_goods < 20
ORDER BY Available_goods ASC;

-- 10. Аналіз замовлень за періодами
SELECT 
    FORMAT(Date, 'yyyy-MM') AS Month,
    COUNT(*) AS Order_Count,
    SUM(Amount) AS Total_Amount
FROM Good_orders
GROUP BY FORMAT(Date, 'yyyy-MM')
ORDER BY Month DESC;

-- 11. Детальна інформація про замовлення
SELECT 
    go.Order_id,
    g.Name AS Good_Name,
    g.Price,
    go.Amount,
    (g.Price * go.Amount) AS Total_Sum,
    go.Date,
    go.Status,
    CASE 
        WHEN c.Type = 'Natural_person' THEN np.Name
        ELSE le.Company_name
    END AS Client_Name
FROM Good_orders go
JOIN Good g ON go.Good_id = g.Good_id
JOIN Client c ON go.Client_id = c.Client_id
LEFT JOIN Natural_person np ON c.Client_id = np.Client_id
LEFT JOIN Legal_entity le ON c.Client_id = le.Client_id
ORDER BY go.Date DESC;

-- 12. Топ-10 найдорожчих товарів
SELECT TOP 10
    Name,
    Price,
    Available_goods
FROM Good
ORDER BY Price DESC;

-- 13. Клієнти без замовлень
SELECT 
    c.Client_id,
    CASE 
        WHEN c.Type = 'Natural_person' THEN np.Name
        ELSE le.Company_name
    END AS Client_Name,
    c.Type
FROM Client c
LEFT JOIN Good_orders go ON c.Client_id = go.Client_id
LEFT JOIN Natural_person np ON c.Client_id = np.Client_id
LEFT JOIN Legal_entity le ON c.Client_id = le.Client_id
WHERE go.Order_id IS NULL;

-- 14. Середня вартість замовлення по місяцях
SELECT 
    FORMAT(go.Date, 'yyyy-MM') AS Month,
    COUNT(DISTINCT go.Order_id) AS Order_Count,
    AVG(g.Price * go.Amount) AS Avg_Order_Sum
FROM Good_orders go
JOIN Good g ON go.Good_id = g.Good_id
GROUP BY FORMAT(go.Date, 'yyyy-MM')
ORDER BY Month DESC;

-- 15. Аналіз активності клієнтів
SELECT 
    CASE 
        WHEN c.Type = 'Natural_person' THEN np.Name
        ELSE le.Company_name
    END AS Client_Name,
    COUNT(go.Order_id) AS Order_Count,
    SUM(go.Amount) AS Total_Amount,
    MAX(go.Date) AS Last_Order_Date
FROM Client c
LEFT JOIN Good_orders go ON c.Client_id = go.Client_id
LEFT JOIN Natural_person np ON c.Client_id = np.Client_id
LEFT JOIN Legal_entity le ON c.Client_id = le.Client_id
GROUP BY c.Client_id, c.Type, np.Name, le.Company_name
ORDER BY Order_Count DESC;

-- 16. Перевірка каскадного видалення: видалення клієнта та перевірка видалення пов'язаних записів
-- Спочатку перевіримо кількість замовлень для конкретного клієнта
SELECT COUNT(*) AS Orders_Before_Delete
FROM Good_orders
WHERE Client_id = 1;

-- Видаляємо клієнта
DELETE FROM Client
WHERE Client_id = 1;

-- Перевіряємо, що замовлення також були видалені
SELECT COUNT(*) AS Orders_After_Delete
FROM Good_orders
WHERE Client_id = 1;

-- 17. Перевірка каскадного видалення для юридичних осіб
-- Перевіряємо дані юридичної особи перед видаленням
SELECT * FROM Legal_entity
WHERE Client_id = 51;

-- Видаляємо клієнта (юридичну особу)
DELETE FROM Client
WHERE Client_id = 51;

-- Перевіряємо, що запис про юридичну особу також був видалений
SELECT * FROM Legal_entity
WHERE Client_id = 51;

-- 18. Перевірка каскадного видалення для фізичних осіб
-- Перевіряємо дані фізичної особи перед видаленням
SELECT * FROM Natural_person
WHERE Client_id = 2;

-- Видаляємо клієнта (фізичну особу)
DELETE FROM Client
WHERE Client_id = 2;

-- Перевіряємо, що запис про фізичну особу також був видалений
SELECT * FROM Natural_person
WHERE Client_id = 2;

-- 19. Перевірка каскадного видалення товару
-- Перевіряємо кількість замовлень для конкретного товару
SELECT COUNT(*) AS Orders_Before_Delete
FROM Good_orders
WHERE Good_id = 1;

-- Видаляємо товар
DELETE FROM Good
WHERE Good_id = 1;

-- Перевіряємо, що замовлення також були видалені
SELECT COUNT(*) AS Orders_After_Delete
FROM Good_orders
WHERE Good_id = 1;

-- 20. Аналіз впливу каскадних видалень на структуру даних
-- Підрахунок загальної кількості записів до видалень
SELECT 
    (SELECT COUNT(*) FROM Client) AS Total_Clients,
    (SELECT COUNT(*) FROM Natural_person) AS Total_Natural_Persons,
    (SELECT COUNT(*) FROM Legal_entity) AS Total_Legal_Entities,
    (SELECT COUNT(*) FROM Good) AS Total_Goods,
    (SELECT COUNT(*) FROM Good_orders) AS Total_Orders;

-- Видаляємо кілька записів для тестування
DELETE FROM Client WHERE Client_id IN (3, 4, 5);
DELETE FROM Good WHERE Good_id IN (2, 3, 4);

-- Підрахунок загальної кількості записів після видалень
SELECT 
    (SELECT COUNT(*) FROM Client) AS Total_Clients,
    (SELECT COUNT(*) FROM Natural_person) AS Total_Natural_Persons,
    (SELECT COUNT(*) FROM Legal_entity) AS Total_Legal_Entities,
    (SELECT COUNT(*) FROM Good) AS Total_Goods,
    (SELECT COUNT(*) FROM Good_orders) AS Total_Orders;

-- 21. Сортування товарів за ціною (від дешевших до дорожчих)
SELECT 
    Name,
    Price,
    Available_goods
FROM Good
ORDER BY Price ASC;

-- 22. Сортування товарів за ціною (від дорожчих до дешевших) та кількістю на складі
SELECT 
    Name,
    Price,
    Available_goods
FROM Good
ORDER BY Price DESC, Available_goods ASC;

-- 23. Сортування замовлень за датою та статусом
SELECT 
    go.Order_id,
    g.Name AS Product_Name,
    go.Date,
    go.Status,
    go.Amount
FROM Good_orders go
JOIN Good g ON go.Good_id = g.Good_id
ORDER BY go.Date DESC, 
    CASE go.Status
        WHEN 'Completed' THEN 1
        WHEN 'Pending' THEN 2
        WHEN 'Cancelled' THEN 3
        ELSE 4
    END;

-- 24. Сортування клієнтів за кількістю замовлень (топ-10)
SELECT TOP 10
    CASE 
        WHEN c.Type = 'Natural_person' THEN np.Name
        ELSE le.Company_name
    END AS Client_Name,
    COUNT(go.Order_id) AS Total_Orders,
    SUM(go.Amount) AS Total_Amount
FROM Client c
LEFT JOIN Good_orders go ON c.Client_id = go.Client_id
LEFT JOIN Natural_person np ON c.Client_id = np.Client_id
LEFT JOIN Legal_entity le ON c.Client_id = le.Client_id
GROUP BY c.Client_id, c.Type, np.Name, le.Company_name
ORDER BY Total_Orders DESC, Total_Amount DESC;

-- 25. Сортування товарів за популярністю (кількістю замовлень)
SELECT 
    g.Name,
    COUNT(go.Order_id) AS Order_Count,
    SUM(go.Amount) AS Total_Amount_Sold,
    g.Price,
    g.Available_goods
FROM Good g
LEFT JOIN Good_orders go ON g.Good_id = go.Good_id
GROUP BY g.Good_id, g.Name, g.Price, g.Available_goods
ORDER BY Order_Count DESC, Total_Amount_Sold DESC;

-- 26. Сортування юридичних осіб за назвою компанії
SELECT 
    Company_name,
    Company_street,
    Company_street_number,
    Company_CEO
FROM Legal_entity
ORDER BY Company_name ASC;

-- 27. Сортування фізичних осіб за прізвищем (припускаючи, що Name містить прізвище)
SELECT 
    Name,
    Street,
    House,
    Phone,
    Email
FROM Natural_person
ORDER BY Name ASC;

-- 28. Сортування замовлень за сумою (ціна * кількість)
SELECT 
    go.Order_id,
    g.Name AS Product_Name,
    g.Price,
    go.Amount,
    (g.Price * go.Amount) AS Total_Sum,
    go.Date,
    go.Status
FROM Good_orders go
JOIN Good g ON go.Good_id = g.Good_id
ORDER BY Total_Sum DESC;

-- 29. Сортування товарів за залишком на складі (низький запас)
SELECT 
    Name,
    Available_goods,
    Price
FROM Good
WHERE Available_goods < 20
ORDER BY Available_goods ASC, Price DESC;

-- 30. Сортування замовлень за періодами (місяцями)
SELECT 
    FORMAT(go.Date, 'yyyy-MM') AS Month,
    COUNT(*) AS Total_Orders,
    SUM(go.Amount) AS Total_Amount,
    AVG(go.Amount) AS Average_Amount
FROM Good_orders go
GROUP BY FORMAT(go.Date, 'yyyy-MM')
ORDER BY Month DESC;

-- 31. Пошук товарів у певному ціновому діапазоні з достатньою кількістю на складі
SELECT 
    Name,
    Price,
    Available_goods
FROM Good
WHERE Price >= 50 AND Price <= 100 
    AND Available_goods > 20
ORDER BY Price ASC;

-- 32. Пошук замовлень з високою сумою або великою кількістю товарів
SELECT 
    go.Order_id,
    g.Name AS Product_Name,
    g.Price,
    go.Amount,
    (g.Price * go.Amount) AS Total_Sum,
    go.Status
FROM Good_orders go
JOIN Good g ON go.Good_id = g.Good_id
WHERE (g.Price * go.Amount) > 1000 OR go.Amount > 5
ORDER BY Total_Sum DESC;

-- 33. Пошук клієнтів, які не робили замовлень або мають скасовані замовлення
SELECT 
    CASE 
        WHEN c.Type = 'Natural_person' THEN np.Name
        ELSE le.Company_name
    END AS Client_Name,
    COUNT(go.Order_id) AS Total_Orders,
    SUM(CASE WHEN go.Status = 'Cancelled' THEN 1 ELSE 0 END) AS Cancelled_Orders
FROM Client c
LEFT JOIN Good_orders go ON c.Client_id = go.Client_id
LEFT JOIN Natural_person np ON c.Client_id = np.Client_id
LEFT JOIN Legal_entity le ON c.Client_id = le.Client_id
GROUP BY c.Client_id, c.Type, np.Name, le.Company_name
HAVING COUNT(go.Order_id) = 0 OR SUM(CASE WHEN go.Status = 'Cancelled' THEN 1 ELSE 0 END) > 0
ORDER BY Total_Orders DESC;

-- 34. Пошук товарів з ціною вище середньої та низьким запасом
SELECT 
    Name,
    Price,
    Available_goods,
    (SELECT AVG(Price) FROM Good) AS Average_Price
FROM Good
WHERE Price > (SELECT AVG(Price) FROM Good)
    AND Available_goods < 15
ORDER BY Price DESC;

-- 35. Пошук замовлень з певним статусом та сумою в заданому діапазоні
SELECT 
    go.Order_id,
    g.Name AS Product_Name,
    go.Amount,
    (g.Price * go.Amount) AS Total_Sum,
    go.Status,
    go.Date
FROM Good_orders go
JOIN Good g ON go.Good_id = g.Good_id
WHERE go.Status IN ('Completed', 'Pending')
    AND (g.Price * go.Amount) BETWEEN 500 AND 2000
ORDER BY go.Date DESC;

-- 36. Пошук юридичних осіб з певною назвою компанії або CEO
SELECT 
    Company_name,
    Company_street,
    Company_street_number,
    Company_CEO
FROM Legal_entity
WHERE Company_name LIKE '%Tech%' 
    OR Company_CEO LIKE '%Smith%'
ORDER BY Company_name;

-- 37. Пошук фізичних осіб з певною адресою або email
SELECT 
    Name,
    Street,
    House,
    Phone,
    Email
FROM Natural_person
WHERE Street LIKE '%Harris%' 
    OR Email LIKE '%@example.com'
ORDER BY Name;

-- 38. Пошук товарів з ціною вище середньої або низьким запасом
SELECT 
    Name,
    Price,
    Available_goods,
    (SELECT AVG(Price) FROM Good) AS Average_Price
FROM Good
WHERE Price > (SELECT AVG(Price) FROM Good)
    OR Available_goods < 10
ORDER BY Price DESC;

-- 39. Пошук замовлень з певним статусом та датою в заданому періоді
SELECT 
    go.Order_id,
    g.Name AS Product_Name,
    go.Amount,
    go.Status,
    go.Date
FROM Good_orders go
JOIN Good g ON go.Good_id = g.Good_id
WHERE go.Status = 'Completed'
    AND go.Date BETWEEN '2024-01-01' AND '2024-03-31'
ORDER BY go.Date DESC;

-- 40. Пошук клієнтів з певною кількістю замовлень та сумою
SELECT 
    CASE 
        WHEN c.Type = 'Natural_person' THEN np.Name
        ELSE le.Company_name
    END AS Client_Name,
    COUNT(go.Order_id) AS Total_Orders,
    SUM(go.Amount) AS Total_Amount
FROM Client c
LEFT JOIN Good_orders go ON c.Client_id = go.Client_id
LEFT JOIN Natural_person np ON c.Client_id = np.Client_id
LEFT JOIN Legal_entity le ON c.Client_id = le.Client_id
GROUP BY c.Client_id, c.Type, np.Name, le.Company_name
HAVING COUNT(go.Order_id) >= 3 
    AND SUM(go.Amount) > 10
ORDER BY Total_Orders DESC;

-- 41. Використання LEFT JOIN для аналізу всіх товарів та їх замовлень
SELECT 
    g.Name AS Product_Name,
    g.Price,
    g.Available_goods,
    COUNT(go.Order_id) AS Total_Orders,
    SUM(go.Amount) AS Total_Amount_Sold
FROM Good g
LEFT JOIN Good_orders go ON g.Good_id = go.Good_id
GROUP BY g.Good_id, g.Name, g.Price, g.Available_goods
ORDER BY Total_Orders DESC;

-- 42. Використання RIGHT JOIN для аналізу всіх замовлень та їх товарів
SELECT 
    go.Order_id,
    go.Date,
    go.Status,
    go.Amount,
    g.Name AS Product_Name,
    g.Price
FROM Good_orders go
RIGHT JOIN Good g ON go.Good_id = g.Good_id
ORDER BY go.Date DESC;

-- 43. Використання FULL JOIN для аналізу всіх клієнтів та їх замовлень
SELECT 
    CASE 
        WHEN c.Type = 'Natural_person' THEN np.Name
        ELSE le.Company_name
    END AS Client_Name,
    c.Type AS Client_Type,
    COUNT(go.Order_id) AS Total_Orders,
    SUM(go.Amount) AS Total_Amount
FROM Client c
FULL JOIN Good_orders go ON c.Client_id = go.Client_id
LEFT JOIN Natural_person np ON c.Client_id = np.Client_id
LEFT JOIN Legal_entity le ON c.Client_id = le.Client_id
GROUP BY c.Client_id, c.Type, np.Name, le.Company_name
ORDER BY Total_Orders DESC;

-- 44. Використання INNER JOIN з умовою для аналізу активних замовлень
SELECT 
    go.Order_id,
    g.Name AS Product_Name,
    g.Price,
    go.Amount,
    go.Date,
    go.Status,
    CASE 
        WHEN c.Type = 'Natural_person' THEN np.Name
        ELSE le.Company_name
    END AS Client_Name
FROM Good_orders go
INNER JOIN Good g ON go.Good_id = g.Good_id
INNER JOIN Client c ON go.Client_id = c.Client_id
LEFT JOIN Natural_person np ON c.Client_id = np.Client_id
LEFT JOIN Legal_entity le ON c.Client_id = le.Client_id
WHERE go.Status = 'Completed'
ORDER BY go.Date DESC;

-- 45. Використання LEFT JOIN з умовою для аналізу непопулярних товарів
SELECT 
    g.Name AS Product_Name,
    g.Price,
    g.Available_goods,
    COUNT(go.Order_id) AS Total_Orders,
    SUM(go.Amount) AS Total_Amount_Sold
FROM Good g
LEFT JOIN Good_orders go ON g.Good_id = go.Good_id
    AND go.Status = 'Completed'
GROUP BY g.Good_id, g.Name, g.Price, g.Available_goods
HAVING COUNT(go.Order_id) = 0
ORDER BY g.Price DESC;

-- 46. Використання RIGHT JOIN з умовою для аналізу замовлень дорогих товарів
SELECT 
    g.Name AS Product_Name,
    g.Price,
    COUNT(go.Order_id) AS Total_Orders,
    SUM(go.Amount) AS Total_Amount_Sold
FROM Good_orders go
RIGHT JOIN Good g ON go.Good_id = g.Good_id
    AND g.Price > (SELECT AVG(Price) FROM Good)
GROUP BY g.Good_id, g.Name, g.Price
ORDER BY g.Price DESC;

-- 47. Використання FULL JOIN для аналізу всіх взаємодій між клієнтами та товарами
SELECT 
    CASE 
        WHEN c.Type = 'Natural_person' THEN np.Name
        ELSE le.Company_name
    END AS Client_Name,
    g.Name AS Product_Name,
    COUNT(go.Order_id) AS Total_Orders,
    SUM(go.Amount) AS Total_Amount
FROM Client c
FULL JOIN Good_orders go ON c.Client_id = go.Client_id
FULL JOIN Good g ON go.Good_id = g.Good_id
LEFT JOIN Natural_person np ON c.Client_id = np.Client_id
LEFT JOIN Legal_entity le ON c.Client_id = le.Client_id
GROUP BY c.Client_id, c.Type, np.Name, le.Company_name, g.Good_id, g.Name
ORDER BY Total_Orders DESC;

-- 48. Використання INNER JOIN з підзапитом для аналізу найпопулярніших товарів
SELECT 
    g.Name AS Product_Name,
    g.Price,
    COUNT(go.Order_id) AS Total_Orders,
    SUM(go.Amount) AS Total_Amount_Sold
FROM Good g
INNER JOIN Good_orders go ON g.Good_id = go.Good_id
WHERE g.Good_id IN (
    SELECT Good_id
    FROM Good_orders
    GROUP BY Good_id
    HAVING COUNT(*) > 5
)
GROUP BY g.Good_id, g.Name, g.Price
ORDER BY Total_Orders DESC;

-- 49. Використання LEFT JOIN з умовою для аналізу клієнтів без замовлень
SELECT 
    CASE 
        WHEN c.Type = 'Natural_person' THEN np.Name
        ELSE le.Company_name
    END AS Client_Name,
    c.Type AS Client_Type,
    COUNT(go.Order_id) AS Total_Orders
FROM Client c
LEFT JOIN Good_orders go ON c.Client_id = go.Client_id
    AND go.Status = 'Completed'
LEFT JOIN Natural_person np ON c.Client_id = np.Client_id
LEFT JOIN Legal_entity le ON c.Client_id = le.Client_id
GROUP BY c.Client_id, c.Type, np.Name, le.Company_name
HAVING COUNT(go.Order_id) = 0
ORDER BY Client_Name;

-- 50. Використання RIGHT JOIN з умовою для аналізу товарів з низьким запасом
SELECT 
    g.Name AS Product_Name,
    g.Price,
    g.Available_goods,
    COUNT(go.Order_id) AS Total_Orders,
    SUM(go.Amount) AS Total_Amount_Sold
FROM Good_orders go
RIGHT JOIN Good g ON go.Good_id = g.Good_id
    AND g.Available_goods < 20
GROUP BY g.Good_id, g.Name, g.Price, g.Available_goods
ORDER BY g.Available_goods ASC;

-- 51. Аналіз замовлень за статусами з використанням GROUP BY та HAVING
SELECT 
    go.Status,
    COUNT(*) AS Total_Orders,
    SUM(go.Amount) AS Total_Amount,
    AVG(go.Amount) AS Average_Amount
FROM Good_orders go
JOIN Good g ON go.Good_id = g.Good_id
GROUP BY go.Status
HAVING COUNT(*) > 10
ORDER BY Total_Orders DESC;

-- 52. Аналіз клієнтів за типами з групуванням та фільтрацією
SELECT 
    c.Type AS Client_Type,
    COUNT(DISTINCT c.Client_id) AS Total_Clients,
    COUNT(go.Order_id) AS Total_Orders,
    SUM(go.Amount) AS Total_Amount
FROM Client c
LEFT JOIN Good_orders go ON c.Client_id = go.Client_id
GROUP BY c.Type
HAVING COUNT(go.Order_id) > 0
ORDER BY Total_Amount DESC;

-- 53. Аналіз товарів за ціновими категоріями
SELECT 
    CASE 
        WHEN g.Price < 50 THEN 'Економ'
        WHEN g.Price BETWEEN 50 AND 100 THEN 'Середній'
        ELSE 'Преміум'
    END AS Price_Category,
    COUNT(DISTINCT g.Good_id) AS Total_Products,
    COUNT(go.Order_id) AS Total_Orders,
    SUM(go.Amount) AS Total_Amount_Sold,
    AVG(g.Price) AS Average_Price
FROM Good g
LEFT JOIN Good_orders go ON g.Good_id = go.Good_id
GROUP BY 
    CASE 
        WHEN g.Price < 50 THEN 'Економ'
        WHEN g.Price BETWEEN 50 AND 100 THEN 'Середній'
        ELSE 'Преміум'
    END
HAVING COUNT(go.Order_id) > 0
ORDER BY Total_Amount_Sold DESC;

-- 54. Аналіз замовлень за місяцями з фільтрацією по сумі
SELECT 
    FORMAT(go.Date, 'yyyy-MM') AS Month,
    COUNT(*) AS Total_Orders,
    SUM(go.Amount) AS Total_Amount,
    AVG(go.Amount) AS Average_Amount,
    COUNT(DISTINCT go.Client_id) AS Unique_Clients
FROM Good_orders go
JOIN Good g ON go.Good_id = g.Good_id
GROUP BY FORMAT(go.Date, 'yyyy-MM')
HAVING SUM(go.Amount) > 1000
ORDER BY Month DESC;

-- 55. Аналіз клієнтів за кількістю замовлень та сумою
SELECT 
    CASE 
        WHEN c.Type = 'Natural_person' THEN np.Name
        ELSE le.Company_name
    END AS Client_Name,
    COUNT(go.Order_id) AS Total_Orders,
    SUM(go.Amount) AS Total_Amount,
    AVG(go.Amount) AS Average_Amount
FROM Client c
LEFT JOIN Good_orders go ON c.Client_id = go.Client_id
LEFT JOIN Natural_person np ON c.Client_id = np.Client_id
LEFT JOIN Legal_entity le ON c.Client_id = le.Client_id
GROUP BY c.Client_id, c.Type, np.Name, le.Company_name
HAVING COUNT(go.Order_id) >= 2 
    AND SUM(go.Amount) > 500
ORDER BY Total_Amount DESC;

-- 56. Аналіз продуктивності запиту з JOIN та GROUP BY
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT 
    g.Name AS Product_Name,
    COUNT(go.Order_id) AS Total_Orders,
    SUM(go.Amount) AS Total_Amount_Sold
FROM Good g
LEFT JOIN Good_orders go ON g.Good_id = go.Good_id
GROUP BY g.Good_id, g.Name
ORDER BY Total_Orders DESC;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

-- 57. Аналіз продуктивності запиту з підзапитом
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT 
    g.Name,
    g.Price,
    g.Available_goods
FROM Good g
WHERE g.Price > (
    SELECT AVG(Price) 
    FROM Good
)
ORDER BY g.Price DESC;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

-- 58. Аналіз продуктивності запиту з HAVING
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT 
    c.Type AS Client_Type,
    COUNT(go.Order_id) AS Total_Orders,
    SUM(go.Amount) AS Total_Amount
FROM Client c
LEFT JOIN Good_orders go ON c.Client_id = go.Client_id
GROUP BY c.Type
HAVING COUNT(go.Order_id) > 5
ORDER BY Total_Amount DESC;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

-- 59. Аналіз продуктивності запиту з UNION
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT Client_id, Name AS Client_Name FROM Natural_person
UNION
SELECT Client_id, Company_name FROM Legal_entity
ORDER BY Client_Name;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

-- 60. Аналіз продуктивності складного запиту з декількома JOIN
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT 
    CASE 
        WHEN c.Type = 'Natural_person' THEN np.Name
        ELSE le.Company_name
    END AS Client_Name,
    g.Name AS Product_Name,
    COUNT(go.Order_id) AS Total_Orders,
    SUM(go.Amount) AS Total_Amount
FROM Client c
LEFT JOIN Good_orders go ON c.Client_id = go.Client_id
LEFT JOIN Good g ON go.Good_id = g.Good_id
LEFT JOIN Natural_person np ON c.Client_id = np.Client_id
LEFT JOIN Legal_entity le ON c.Client_id = le.Client_id
GROUP BY c.Client_id, c.Type, np.Name, le.Company_name, g.Good_id, g.Name
HAVING COUNT(go.Order_id) > 0
ORDER BY Total_Orders DESC;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
