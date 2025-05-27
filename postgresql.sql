-- PostgreSQL dump for TechGearHub database
-- Converted from MySQL

-- Create database (run this separately if needed)
-- CREATE DATABASE techgearhub;

-- Connect to the database
-- \c techgearhub;

-- Drop tables if they exist (in correct order due to foreign keys)
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS carts;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS users;

-- Create users table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL
);

-- Create products table
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    image VARCHAR(255) NOT NULL,
    value DECIMAL(10,2) NOT NULL,
    category VARCHAR(50) NOT NULL
);

-- Create carts table
CREATE TABLE carts (
    cart_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    products JSONB NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create index on user_id for carts table
CREATE INDEX idx_carts_user_id ON carts(user_id);

-- Create orders table
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    cart_id INTEGER NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (cart_id) REFERENCES carts(cart_id) ON DELETE CASCADE,
    UNIQUE(user_id, cart_id)
);

-- Create indexes on foreign keys for orders table
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_cart_id ON orders(cart_id);

-- Insert data into users table
INSERT INTO users (id, username, password) VALUES 
(1, 'myuser', '$2b$10$r8bI6GhIwfz1Zva6gnak7OxnoXLbhcKOjxje069bVNngxvvLVw/Y6'),
(2, 'test1', '$2b$10$EZPKoyZWGJR2IV9Eb.uJaOC3ObG8W6lioUEibDZIlu5A2iuY9QpLK'),
(3, 'user', '$2b$10$OE92OLR5keNj9/595N84fOJbUcJ4.CmTFWG2k/LOAxNyPE5XMJ3xO'),
(4, 'new_user', '$2b$10$PhooO38JOTFeBwzk/VSJCes150/1bRS4bz8nGFDOCOp8DeVIvN0EC'),
(5, 'panagiotis', '$2b$10$Y5IrR/joQCvZxmnk1ecScOa0FiKRHwf.OAIyNhdxpigOmJaAzUQwK');

-- Insert data into products table
INSERT INTO products (id, title, description, image, value, category) VALUES 
(1, 'Intel Core i9-13900K', 'High-performance CPU', 'images/cpu1.jpg', 599.00, 'cpu'),
(2, 'Corsair Vengeance 16GB RAM', 'Reliable and fast RAM', 'images/ram1.jpg', 89.00, 'ram'),
(3, 'Samsung 970 EVO SSD', 'High-speed storage', 'images/storage1.jpg', 109.00, 'storage'),
(4, 'NVIDIA GeForce RTX 3080', 'Top-tier GPU', 'images/gpu1.jpg', 699.00, 'gpu'),
(5, 'AMD Ryzen™ 9 9950X', 'Higher-performance CPU from AMD', 'images/cpu2.jpg', 699.00, 'cpu'),
(6, 'G.Skill Ripjaws V 16GB RAM', 'Affordable and reliable RAM', 'images/ram2.jpg', 33.00, 'ram'),
(7, 'Crucial BX500 SSD 1TB', ' High-speed ssd disk', 'images/storage2.jpg', 55.00, 'storage'),
(8, 'Sapphire Radeon RX 7900 XT 20GB', 'High performance CPU', 'images/gpu2.jpg', 750.00, 'gpu');

-- Insert data into carts table
INSERT INTO carts (cart_id, user_id, quantity, products) VALUES 
(58, 4, 1, '[{"title": "G.Skill Ripjaws V 16GB RAM", "value": 33, "quantity": 3, "product_id": 6}]'::jsonb),
(62, 2, 1, '[{"title": "G.Skill Ripjaws V 16GB RAM", "value": 33, "quantity": 1, "product_id": 6}]'::jsonb),
(64, 5, 1, '[{"title": "G.Skill Ripjaws V 16GB RAM", "value": 33, "quantity": 2, "product_id": 6}, {"title": "NVIDIA GeForce RTX 3080", "value": 699, "quantity": 3, "product_id": 4}, {"title": "Intel Core i9-13900K", "value": 599, "quantity": 1, "product_id": 1}, {"title": "Crucial BX500 SSD 1TB", "value": 55, "quantity": 1, "product_id": 7}]'::jsonb);

-- Insert data into orders table
INSERT INTO orders (order_id, user_id, cart_id, total_amount, created_at) VALUES 
(41, 4, 58, 99.00, '2025-01-06 00:27:22'),
(45, 2, 62, 33.00, '2025-01-11 15:14:34');

-- Update sequences to continue from the last inserted ID
-- This ensures that new records will have the correct auto-increment values
SELECT setval('users_id_seq', (SELECT MAX(id) FROM users));
SELECT setval('products_id_seq', (SELECT MAX(id) FROM products));
SELECT setval('carts_cart_id_seq', (SELECT MAX(cart_id) FROM carts));
SELECT setval('orders_order_id_seq', (SELECT MAX(order_id) FROM orders));