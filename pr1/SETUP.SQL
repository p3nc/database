-- Створення таблиці "Good"
CREATE TABLE Good (
    Good_id INT IDENTITY(1,1) PRIMARY KEY, 
    Name VARCHAR(255) NOT NULL,
    Discription TEXT,
    Price NUMERIC(10, 2) NOT NULL,
    Available_goods INT NOT NULL
);

-- Створення таблиці "Client"
CREATE TABLE Client (
    Client_id INT IDENTITY(1,1) PRIMARY KEY,  
    Type VARCHAR(50) NOT NULL
);

-- Створення таблиці "Natural_person"
CREATE TABLE Natural_person (
    Client_id INT PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,
    Street VARCHAR(255),
    House VARCHAR(50),
    Phone VARCHAR(20),
    Email VARCHAR(100),
    FOREIGN KEY (Client_id) REFERENCES Client(Client_id) ON DELETE CASCADE
);

-- Створення таблиці "Legal_entity"
CREATE TABLE Legal_entity (
    Client_id INT PRIMARY KEY,
    Company_name VARCHAR(255) NOT NULL,
    Company_street VARCHAR(255),
    Company_street_number VARCHAR(50),
    Company_CEO VARCHAR(255),
    FOREIGN KEY (Client_id) REFERENCES Client(Client_id) ON DELETE CASCADE
);

-- Створення таблиці "Good_orders"
CREATE TABLE Good_orders (
    Order_id INT IDENTITY(1,1) PRIMARY KEY,  
    Good_id INT NOT NULL,
    Date DATE NOT NULL,
    Status VARCHAR(50),
    Amount INT NOT NULL,
    Client_id INT NOT NULL,
    FOREIGN KEY (Good_id) REFERENCES Good(Good_id) ON DELETE CASCADE,
    FOREIGN KEY (Client_id) REFERENCES Client(Client_id) ON DELETE CASCADE
);
