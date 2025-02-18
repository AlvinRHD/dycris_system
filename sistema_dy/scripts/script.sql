CREATE DATABASE  IF NOT EXISTS `sistema_dycris` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `sistema_dycris`;
-- MySQL dump 10.13  Distrib 8.0.40, for Win64 (x86_64)
--
-- Host: 127.0.0.1    Database: sistema_dycris
-- ------------------------------------------------------
-- Server version	9.1.0

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `categoria`
--

DROP TABLE IF EXISTS `categoria`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `categoria` (
  `id` int NOT NULL AUTO_INCREMENT,
  `nombre` varchar(100) NOT NULL,
  `descripcion` text,
  `fecha_creacion` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `estado` enum('Activo','Inactivo') NOT NULL DEFAULT 'Activo',
  PRIMARY KEY (`id`),
  UNIQUE KEY `nombre` (`nombre`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `categoria`
--

LOCK TABLES `categoria` WRITE;
/*!40000 ALTER TABLE `categoria` DISABLE KEYS */;
INSERT INTO `categoria` VALUES (1,'Tecnología','Productos electrónicos, computadores, etc.','2025-02-18 16:36:20','Activo'),(2,'Motores','ninguna por el momento','2025-02-18 18:46:16','Activo');
/*!40000 ALTER TABLE `categoria` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `clientes`
--

DROP TABLE IF EXISTS `clientes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `clientes` (
  `idCliente` int NOT NULL AUTO_INCREMENT,
  `nombre` varchar(100) NOT NULL,
  `direccion` varchar(200) DEFAULT NULL,
  `dui` varchar(10) DEFAULT NULL,
  `nit` varchar(17) DEFAULT NULL,
  `tipo_cliente` enum('Consumidor Final','Contribuyente Jurídico','Natural','ONG','Sujeto Excluido') NOT NULL DEFAULT 'Natural',
  `registro_contribuyente` varchar(20) DEFAULT NULL,
  `representante_legal` varchar(100) DEFAULT NULL,
  `direccion_representante` varchar(200) DEFAULT NULL,
  `razon_social` varchar(100) DEFAULT NULL,
  `email` varchar(100) NOT NULL,
  `telefono` varchar(15) NOT NULL,
  `fecha_inicio` date DEFAULT NULL,
  `fecha_fin` date DEFAULT NULL,
  `porcentaje_retencion` decimal(5,2) DEFAULT NULL,
  PRIMARY KEY (`idCliente`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `clientes`
--

LOCK TABLES `clientes` WRITE;
/*!40000 ALTER TABLE `clientes` DISABLE KEYS */;
INSERT INTO `clientes` VALUES (1,'Juan Pérez','San Salvador, El Salvador','12345678-9','0614-050616-101-3','Natural',NULL,NULL,NULL,NULL,'juan@example.com','7777-7777',NULL,NULL,NULL),(2,'Alvin Rosales','Col. Fatima','06626539-1','06626539-1','Natural',NULL,NULL,NULL,NULL,'ezequielhernandes907@gmail.com','1212-1212',NULL,NULL,NULL),(3,'alvin','col.fatima','','','Consumidor Final','1212-12121212','','','','alvin@gmail.com','1212-1212','2025-02-17','2025-02-28',NULL);
/*!40000 ALTER TABLE `clientes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `detalle_ventas`
--

DROP TABLE IF EXISTS `detalle_ventas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `detalle_ventas` (
  `idDetalle` int NOT NULL AUTO_INCREMENT,
  `idVentas` int NOT NULL,
  `codigo_producto` varchar(50) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `cantidad` int NOT NULL,
  `precio_unitario` decimal(10,2) NOT NULL,
  `subtotal` decimal(10,2) NOT NULL,
  PRIMARY KEY (`idDetalle`),
  KEY `idVentas` (`idVentas`),
  KEY `codigo_producto` (`codigo_producto`),
  CONSTRAINT `detalle_ventas_ibfk_1` FOREIGN KEY (`idVentas`) REFERENCES `ventas` (`idVentas`),
  CONSTRAINT `detalle_ventas_ibfk_2` FOREIGN KEY (`codigo_producto`) REFERENCES `inventario` (`codigo`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `detalle_ventas`
--

LOCK TABLES `detalle_ventas` WRITE;
/*!40000 ALTER TABLE `detalle_ventas` DISABLE KEYS */;
/*!40000 ALTER TABLE `detalle_ventas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `historial_ajustes`
--

DROP TABLE IF EXISTS `historial_ajustes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `historial_ajustes` (
  `id` int NOT NULL AUTO_INCREMENT,
  `codigo` varchar(50) NOT NULL,
  `nombre` varchar(50) DEFAULT NULL,
  `descripcion` text NOT NULL,
  `precio` decimal(20,0) NOT NULL,
  `fecha` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `stock` int NOT NULL,
  `motivo` text NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `historial_ajustes`
--

LOCK TABLES `historial_ajustes` WRITE;
/*!40000 ALTER TABLE `historial_ajustes` DISABLE KEYS */;
INSERT INTO `historial_ajustes` VALUES (1,'885','hhyyh','gg',24,'2025-02-18 00:00:00',6567,'gg'),(2,'1212','motor 1 editado','es un motor poderoso',300,'2025-02-18 12:28:34',15,'Equivocación de letras');
/*!40000 ALTER TABLE `historial_ajustes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `inventario`
--

DROP TABLE IF EXISTS `inventario`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `inventario` (
  `id` int NOT NULL AUTO_INCREMENT,
  `codigo` varchar(50) NOT NULL,
  `imagen` varchar(255) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `descripcion` text,
  `numero_motor` varchar(50) DEFAULT NULL,
  `numero_chasis` varchar(50) DEFAULT NULL,
  `categoria_id` int NOT NULL,
  `sucursal_id` int NOT NULL,
  `costo` decimal(10,2) NOT NULL,
  `credito` decimal(10,2) DEFAULT NULL,
  `precio_venta` decimal(10,2) NOT NULL,
  `stock_existencia` int NOT NULL,
  `stock_minimo` int NOT NULL,
  `fecha_ingreso` date NOT NULL,
  `fecha_reingreso` date DEFAULT NULL,
  `numero_poliza` varchar(50) DEFAULT NULL,
  `numero_lote` varchar(50) DEFAULT NULL,
  `proveedor_id` int NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `codigo` (`codigo`),
  KEY `categoria_id` (`categoria_id`),
  KEY `sucursal_id` (`sucursal_id`),
  KEY `proveedor_id` (`proveedor_id`),
  CONSTRAINT `inventario_ibfk_1` FOREIGN KEY (`categoria_id`) REFERENCES `categoria` (`id`) ON DELETE CASCADE,
  CONSTRAINT `inventario_ibfk_2` FOREIGN KEY (`sucursal_id`) REFERENCES `sucursal` (`id`) ON DELETE CASCADE,
  CONSTRAINT `inventario_ibfk_3` FOREIGN KEY (`proveedor_id`) REFERENCES `proveedores` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `inventario`
--

LOCK TABLES `inventario` WRITE;
/*!40000 ALTER TABLE `inventario` DISABLE KEYS */;
INSERT INTO `inventario` VALUES (2,'1212','/uploads/1739903246807.png','motor 1 editado','es un motor poderoso','12','2',1,1,350.00,12.00,300.00,15,10,'2025-02-18','2025-02-18','111122223333','3',1);
/*!40000 ALTER TABLE `inventario` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ofertas`
--

DROP TABLE IF EXISTS `ofertas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ofertas` (
  `id` int NOT NULL AUTO_INCREMENT,
  `inventario_id` int NOT NULL,
  `descuento` decimal(5,2) NOT NULL,
  `fecha_inicio` date NOT NULL,
  `fecha_fin` date NOT NULL,
  `estado` enum('Activa','Inactiva') NOT NULL DEFAULT 'Activa',
  PRIMARY KEY (`id`),
  KEY `inventario_id` (`inventario_id`),
  CONSTRAINT `ofertas_ibfk_1` FOREIGN KEY (`inventario_id`) REFERENCES `inventario` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ofertas`
--

LOCK TABLES `ofertas` WRITE;
/*!40000 ALTER TABLE `ofertas` DISABLE KEYS */;
/*!40000 ALTER TABLE `ofertas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `proveedores`
--

DROP TABLE IF EXISTS `proveedores`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `proveedores` (
  `id` int NOT NULL AUTO_INCREMENT,
  `nombre` varchar(150) NOT NULL,
  `direccion` text NOT NULL,
  `contacto` varchar(20) NOT NULL,
  `correo` varchar(100) NOT NULL,
  `clasificacion` varchar(50) DEFAULT NULL,
  `tipo_persona` enum('Natural','Jurídica') NOT NULL,
  `numero_factura_compra` varchar(50) DEFAULT NULL,
  `ley_tributaria` text,
  PRIMARY KEY (`id`),
  UNIQUE KEY `correo` (`correo`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `proveedores`
--

LOCK TABLES `proveedores` WRITE;
/*!40000 ALTER TABLE `proveedores` DISABLE KEYS */;
INSERT INTO `proveedores` VALUES (1,'Proveedor A','Calle 123, Ciudad A','1234567890','proveedorA@example.com','Mayorista','Jurídica','1234567890','Ley Tributaria 123'),(2,'Alvin Rosales H','col san sivar sv','1313-1313','alvinedit@gmail.com','pequeña','Natural','121212','contribuyente');
/*!40000 ALTER TABLE `proveedores` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sucursal`
--

DROP TABLE IF EXISTS `sucursal`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sucursal` (
  `id` int NOT NULL AUTO_INCREMENT,
  `codigo` varchar(50) NOT NULL,
  `nombre` varchar(50) NOT NULL,
  `pais` varchar(50) NOT NULL,
  `departamento` varchar(50) NOT NULL,
  `ciudad` varchar(50) NOT NULL,
  `estado` enum('Activo','Inactivo') NOT NULL DEFAULT 'Activo',
  PRIMARY KEY (`id`),
  UNIQUE KEY `codigo` (`codigo`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sucursal`
--

LOCK TABLES `sucursal` WRITE;
/*!40000 ALTER TABLE `sucursal` DISABLE KEYS */;
INSERT INTO `sucursal` VALUES (1,'S001','Sucursal Principal','Colombia','Bogotá','Bogotá','Activo');
/*!40000 ALTER TABLE `sucursal` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `traslados`
--

DROP TABLE IF EXISTS `traslados`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `traslados` (
  `id` int NOT NULL AUTO_INCREMENT,
  `codigo_traslado` varchar(50) NOT NULL,
  `inventario_id` int NOT NULL,
  `origen` varchar(50) NOT NULL,
  `destino` varchar(50) NOT NULL,
  `cantidad` int NOT NULL,
  `fecha_traslado` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `responsable` varchar(100) NOT NULL,
  `estado` enum('Pendiente','Completado','Cancelado') NOT NULL DEFAULT 'Pendiente',
  PRIMARY KEY (`id`),
  UNIQUE KEY `codigo_traslado` (`codigo_traslado`),
  KEY `inventario_id` (`inventario_id`),
  CONSTRAINT `traslados_ibfk_1` FOREIGN KEY (`inventario_id`) REFERENCES `inventario` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `traslados`
--

LOCK TABLES `traslados` WRITE;
/*!40000 ALTER TABLE `traslados` DISABLE KEYS */;
/*!40000 ALTER TABLE `traslados` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `usuarios`
--

DROP TABLE IF EXISTS `usuarios`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `usuarios` (
  `id` int NOT NULL AUTO_INCREMENT,
  `nombre_completo` varchar(255) NOT NULL,
  `usuario` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL,
  `rol` enum('Admin','Caja','Asesor de Venta') NOT NULL,
  `fecha_creacion` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_actualizacion` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `usuarios`
--

LOCK TABLES `usuarios` WRITE;
/*!40000 ALTER TABLE `usuarios` DISABLE KEYS */;
INSERT INTO `usuarios` VALUES (1,'Alvin Rosales','admin','4444','Admin','2025-02-17 06:00:00','2025-02-17 06:00:00');
/*!40000 ALTER TABLE `usuarios` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ventas`
--

DROP TABLE IF EXISTS `ventas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ventas` (
  `idVentas` int NOT NULL AUTO_INCREMENT,
  `fecha_venta` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `cliente_id` int DEFAULT NULL,
  `tipo_factura` enum('Consumidor Final','Crédito Fiscal','Ticket') NOT NULL,
  `metodo_pago` enum('Efectivo','Tarjeta de Crédito','Transferencia Bancaria') NOT NULL,
  `total` decimal(10,2) NOT NULL,
  `descripcion_compra` text,
  PRIMARY KEY (`idVentas`),
  KEY `cliente_id` (`cliente_id`),
  CONSTRAINT `ventas_ibfk_1` FOREIGN KEY (`cliente_id`) REFERENCES `clientes` (`idCliente`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ventas`
--

LOCK TABLES `ventas` WRITE;
/*!40000 ALTER TABLE `ventas` DISABLE KEYS */;
INSERT INTO `ventas` VALUES (1,'2025-02-17 16:41:24',1,'Consumidor Final','Efectivo',1200.00,'Venta de motocicleta'),(2,'2025-02-17 00:00:00',1,'Consumidor Final','Tarjeta de Crédito',1342.44,'ninguna'),(3,'2025-02-18 10:29:38',1,'Consumidor Final','Efectivo',1200.00,'Venta de motocicleta');
/*!40000 ALTER TABLE `ventas` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-02-18 13:16:43
