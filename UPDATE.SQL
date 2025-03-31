-- Оновлення статусу замовлення
UPDATE Good_orders
SET Status = 'Completed'
WHERE Order_id = 1;

-- Оновлення кількості доступних товарів
UPDATE Good
SET Available_goods = Available_goods - 1
WHERE Good_id = 1;
