-- 1. Вибрати всі товари, що коштують більше ніж 50
SELECT * FROM Good WHERE Price > 50;

-- 2. Вибрати товари, які коштують більше ніж 50 і є в наявності (Available_goods > 0)
SELECT * FROM Good WHERE Price > 50 AND Available_goods > 0;

-- 3. Вибрати товари, назви яких починаються з літери 'T'
SELECT * FROM Good WHERE Name LIKE 'T%';

-- 4. Отримати список товарів і відповідних замовлень
SELECT Good.Name, Good.Price, Good_orders.Order_id, Good_orders.Amount
FROM Good
JOIN Good_orders ON Good.Good_id = Good_orders.Good_id;

-- 5. Вибрати всі товари та їхні замовлення (включаючи товари без замовлень)
SELECT Good.Name, Good.Price, Good_orders.Order_id, Good_orders.Amount
FROM Good
LEFT JOIN Good_orders ON Good.Good_id = Good_orders.Good_id;

-- 6. Вибрати всі товари, ціна яких вища за середню ціну всіх товарів
SELECT * FROM Good 
WHERE Price > (SELECT AVG(Price) FROM Good);

-- 7. Підрахувати кількість замовлень для кожного товару
SELECT Good.Name, COUNT(Good_orders.Order_id) AS Total_Orders
FROM Good
LEFT JOIN Good_orders ON Good.Good_id = Good_orders.Good_id
GROUP BY Good.Name;

-- 8. Вибрати клієнтів, які зробили замовлення на загальну суму більше 200, відсортувати за сумою у спадному порядку
SELECT 
    CASE 
        WHEN Client.Type = 'Natural' THEN Natural_person.Name
        WHEN Client.Type = 'Legal' THEN Legal_entity.Company_name
    END AS Client_Name,
    SUM(Good.Price * Good_orders.Amount) AS Total_Spent
FROM Client
LEFT JOIN Natural_person ON Client.Client_id = Natural_person.Client_id
LEFT JOIN Legal_entity ON Client.Client_id = Legal_entity.Client_id
JOIN Good_orders ON Client.Client_id = Good_orders.Client_id
JOIN Good ON Good_orders.Good_id = Good.Good_id
GROUP BY Client.Client_id, Client.Type, Natural_person.Name, Legal_entity.Company_name
HAVING SUM(Good.Price * Good_orders.Amount) > 200
ORDER BY Total_Spent DESC;


-- 9. Вибрати замовлення клієнтів, які є юридичними особами
SELECT Good_orders.Order_id, Legal_entity.Company_name, Good.Name, Good_orders.Amount
FROM Good_orders
JOIN Client ON Good_orders.Client_id = Client.Client_id
JOIN Legal_entity ON Client.Client_id = Legal_entity.Client_id
JOIN Good ON Good_orders.Good_id = Good.Good_id;
