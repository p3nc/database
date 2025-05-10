-- Вставка даних у таблицю "Good"
INSERT INTO Good (Name, Discription, Price, Available_goods) VALUES
('Laptop', 'Gaming laptop', 1500.00, 10),
('Mouse', 'Wireless mouse', 25.50, 50);

-- Вставка даних у таблицю "Client"
INSERT INTO Client (Type) VALUES
('Natural_person'),
('Legal_entity');

-- Вставка даних у таблицю "Natural_person"
INSERT INTO Natural_person (Client_id, Name, Street, House, Phone, Email) VALUES
(1, 'John Doe', 'Main Street', '12A', '123-456-789', 'johndoe@example.com');

-- Вставка даних у таблицю "Legal_entity"
INSERT INTO Legal_entity (Client_id, Company_name, Company_street, Company_street_number, Company_CEO) VALUES
(2, 'Tech Corp', 'Business Street', '45B', 'Alice Smith');

-- Вставка даних у таблицю "Good_orders"
INSERT INTO Good_orders (Good_id, Date, Status, Amount, Client_id) VALUES
(1, '2024-01-01', 'Pending', 1, 1),
(2, '2024-01-02', 'Shipped', 2, 2);
