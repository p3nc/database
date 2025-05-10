-- Отримання всіх товарів
SELECT * FROM Good;

-- Отримання всіх клієнтів
SELECT * FROM Client;

-- Отримання всіх фізичних осіб
SELECT * FROM Natural_person;

-- Отримання всіх юридичних осіб
SELECT * FROM Legal_entity;

-- Отримання всіх замовлень
SELECT * FROM Good_orders;

-- Отримання замовлень певного клієнта
SELECT * FROM Good_orders WHERE Client_id = 1;

-- Отримання товарів із залишком більше 0
SELECT * FROM Good WHERE Available_goods > 0;

-- Отримання інформації про замовлення разом із деталями про товар та клієнта
SELECT go.Order_id, go.Date, go.Status, go.Amount, g.Name AS Good_Name, c.Type AS Client_Type
FROM Good_orders go
JOIN Good g ON go.Good_id = g.Good_id
JOIN Client c ON go.Client_id = c.Client_id;

