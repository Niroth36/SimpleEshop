-- MySQL dump 10.13  Distrib 8.4.4, for Linux (x86_64)
--
-- Host: localhost    Database: TechGearHub
-- ------------------------------------------------------
-- Server version	8.4.4

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `carts`
--

DROP TABLE IF EXISTS `carts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `carts` (
  `cart_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `quantity` int NOT NULL DEFAULT '1',
  `products` json NOT NULL,
  PRIMARY KEY (`cart_id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `carts_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=65 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `carts`
--

LOCK TABLES `carts` WRITE;
/*!40000 ALTER TABLE `carts` DISABLE KEYS */;
INSERT INTO `carts` VALUES (58,4,1,'[{\"title\": \"G.Skill Ripjaws V 16GB RAM\", \"value\": 33, \"quantity\": 3, \"product_id\": 6}]'),(62,2,1,'[{\"title\": \"G.Skill Ripjaws V 16GB RAM\", \"value\": 33, \"quantity\": 1, \"product_id\": 6}]'),(64,5,1,'[{\"title\": \"G.Skill Ripjaws V 16GB RAM\", \"value\": 33, \"quantity\": 2, \"product_id\": 6}, {\"title\": \"NVIDIA GeForce RTX 3080\", \"value\": 699, \"quantity\": 3, \"product_id\": 4}, {\"title\": \"Intel Core i9-13900K\", \"value\": 599, \"quantity\": 1, \"product_id\": 1}, {\"title\": \"Crucial BX500 SSD 1TB\", \"value\": 55, \"quantity\": 1, \"product_id\": 7}]');
/*!40000 ALTER TABLE `carts` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `orders`
--

DROP TABLE IF EXISTS `orders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `orders` (
  `order_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `cart_id` int NOT NULL,
  `total_amount` decimal(10,2) NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`order_id`),
  UNIQUE KEY `user_id` (`user_id`,`cart_id`),
  KEY `orders_ibfk_2` (`cart_id`),
  CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `orders_ibfk_2` FOREIGN KEY (`cart_id`) REFERENCES `carts` (`cart_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=47 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `orders`
--

LOCK TABLES `orders` WRITE;
/*!40000 ALTER TABLE `orders` DISABLE KEYS */;
INSERT INTO `orders` VALUES (41,4,58,99.00,'2025-01-06 00:27:22'),(45,2,62,33.00,'2025-01-11 15:14:34');
/*!40000 ALTER TABLE `orders` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `products`
--

DROP TABLE IF EXISTS `products`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `products` (
  `id` int NOT NULL AUTO_INCREMENT,
  `title` varchar(255) NOT NULL,
  `description` text NOT NULL,
  `image` varchar(255) NOT NULL,
  `value` decimal(10,2) NOT NULL,
  `category` varchar(50) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `products`
--

LOCK TABLES `products` WRITE;
/*!40000 ALTER TABLE `products` DISABLE KEYS */;
INSERT INTO `products` VALUES (1,'Intel Core i9-13900K','High-performance CPU','images/cpu1.jpg',599.00,'cpu'),(2,'Corsair Vengeance 16GB RAM','Reliable and fast RAM','images/ram1.jpg',89.00,'ram'),(3,'Samsung 970 EVO SSD','High-speed storage','images/storage1.jpg',109.00,'storage'),(4,'NVIDIA GeForce RTX 3080','Top-tier GPU','images/gpu1.jpg',699.00,'gpu'),(5,'AMD Ryzen™ 9 9950X','Higher-performance CPU from AMD','images/cpu2.jpg',699.00,'cpu'),(6,'G.Skill Ripjaws V 16GB RAM','Affordable and reliable RAM','images/ram2.jpg',33.00,'ram'),(7,'Crucial BX500 SSD 1TB',' High-speed ssd disk','images/storage2.jpg',55.00,'storage'),(8,'Sapphire Radeon RX 7900 XT 20GB','High performance CPU','images/gpu2.jpg',750.00,'gpu');
/*!40000 ALTER TABLE `products` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` int NOT NULL AUTO_INCREMENT,
  `username` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'myuser','$2b$10$r8bI6GhIwfz1Zva6gnak7OxnoXLbhcKOjxje069bVNngxvvLVw/Y6'),(2,'test1','$2b$10$EZPKoyZWGJR2IV9Eb.uJaOC3ObG8W6lioUEibDZIlu5A2iuY9QpLK'),(3,'user','$2b$10$OE92OLR5keNj9/595N84fOJbUcJ4.CmTFWG2k/LOAxNyPE5XMJ3xO'),(4,'new_user','$2b$10$PhooO38JOTFeBwzk/VSJCes150/1bRS4bz8nGFDOCOp8DeVIvN0EC'),(5,'panagiotis','$2b$10$Y5IrR/joQCvZxmnk1ecScOa0FiKRHwf.OAIyNhdxpigOmJaAzUQwK');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-02-15 15:16:03
