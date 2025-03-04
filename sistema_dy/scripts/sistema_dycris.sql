CREATE DATABASE  IF NOT EXISTS `sistema_dycris` /*!80016 DEFAULT ENCRYPTION='N' */;
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
-- Table structure for table `aperturas_caja`
--

DROP TABLE IF EXISTS `aperturas_caja`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `aperturas_caja` (
  `id` int NOT NULL AUTO_INCREMENT,
  `caja_id` int NOT NULL,
  `usuario_id` int NOT NULL,
  `fecha_apertura` datetime DEFAULT CURRENT_TIMESTAMP,
  `saldo_acumulado` decimal(10,2) DEFAULT '0.00',
  `monto_apertura` decimal(10,2) NOT NULL,
  `total_apertura` decimal(10,2) GENERATED ALWAYS AS ((`saldo_acumulado` + `monto_apertura`)) STORED,
  PRIMARY KEY (`id`),
  KEY `caja_id` (`caja_id`),
  KEY `usuario_id` (`usuario_id`),
  CONSTRAINT `aperturas_caja_ibfk_1` FOREIGN KEY (`caja_id`) REFERENCES `cajas` (`id`) ON DELETE CASCADE,
  CONSTRAINT `aperturas_caja_ibfk_2` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE RESTRICT
);
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `aperturas_caja`
--

LOCK TABLES `aperturas_caja` WRITE;
/*!40000 ALTER TABLE `aperturas_caja` DISABLE KEYS */;
INSERT INTO `aperturas_caja` (`id`, `caja_id`, `usuario_id`, `fecha_apertura`, `saldo_acumulado`, `monto_apertura`) VALUES (10,6,9,'2025-03-03 17:51:28',0.00,130.00),(11,3,9,'2025-03-03 17:52:52',0.00,100.00),(12,2,9,'2025-03-03 17:54:27',0.00,100.00),(13,2,9,'2025-03-03 18:00:00',0.00,1500.00),(14,3,9,'2025-03-04 11:03:03',0.00,1000.00),(15,6,9,'2025-03-04 12:45:30',0.00,290.00);
/*!40000 ALTER TABLE `aperturas_caja` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cajas`
--

DROP TABLE IF EXISTS `cajas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cajas` (
  `id` int NOT NULL AUTO_INCREMENT,
  `numero_caja` varchar(50) NOT NULL,
  `sucursal_id` int NOT NULL,
  `estado` enum('Abierta','Cerrada') DEFAULT 'Cerrada',
  PRIMARY KEY (`id`),
  UNIQUE KEY `numero_caja` (`numero_caja`,`sucursal_id`),
  KEY `sucursal_id` (`sucursal_id`),
  CONSTRAINT `cajas_ibfk_1` FOREIGN KEY (`sucursal_id`) REFERENCES `sucursal` (`id`) ON DELETE CASCADE
);
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cajas`
--

LOCK TABLES `cajas` WRITE;
/*!40000 ALTER TABLE `cajas` DISABLE KEYS */;
INSERT INTO `cajas` VALUES (2,'1',4,'Cerrada'),(3,'1',5,'Cerrada'),(6,'2',4,'Cerrada');
/*!40000 ALTER TABLE `cajas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `categoria`
--

DROP TABLE IF EXISTS `categoria`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `categoria` (
  `id` int NOT NULL AUTO_INCREMENT,
  `nombre` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `descripcion` text COLLATE utf8mb4_general_ci,
  `fecha_creacion` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `estado` enum('Activo','Inactivo') COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'Activo',
  PRIMARY KEY (`id`),
  UNIQUE KEY `nombre` (`nombre`)
) ;
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
-- Table structure for table `cierres_caja`
--

DROP TABLE IF EXISTS `cierres_caja`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cierres_caja` (
  `id` int NOT NULL AUTO_INCREMENT,
  `apertura_id` int NOT NULL,
  `fecha_cierre` datetime DEFAULT CURRENT_TIMESTAMP,
  `total_ventas` decimal(10,2) NOT NULL,
  `efectivo_en_caja` decimal(10,2) NOT NULL,
  `observaciones` text,
  PRIMARY KEY (`id`),
  KEY `apertura_id` (`apertura_id`),
  CONSTRAINT `cierres_caja_ibfk_1` FOREIGN KEY (`apertura_id`) REFERENCES `aperturas_caja` (`id`) ON DELETE CASCADE
);
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cierres_caja`
--

LOCK TABLES `cierres_caja` WRITE;
/*!40000 ALTER TABLE `cierres_caja` DISABLE KEYS */;
INSERT INTO `cierres_caja` VALUES (4,10,'2025-03-03 17:52:23',0.00,0.00,'ninguna'),(5,11,'2025-03-03 17:53:26',0.00,0.00,NULL),(6,12,'2025-03-03 17:56:05',0.00,3322.20,'NINGUNA'),(7,13,'2025-03-03 18:00:48',0.00,1500.00,'ninguna'),(8,14,'2025-03-04 12:29:01',31142.80,30000.00,'Se sacaron 1142.80 para pago de tecnicos\n'),(9,15,'2025-03-04 12:48:03',41211.10,40000.00,'SE SACARON 1211.10 PARA MERITOS DE TECNICOS');
/*!40000 ALTER TABLE `cierres_caja` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `clientes`
--

DROP TABLE IF EXISTS `clientes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `clientes` (
  `idCliente` int NOT NULL AUTO_INCREMENT,
  `nombre` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `direccion` varchar(200) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `dui` varchar(10) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `nit` varchar(17) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `tipo_cliente` enum('Consumidor Final','Contribuyente Jurídico','Natural','ONG','Sujeto Excluido') COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'Natural',
  `registro_contribuyente` varchar(20) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `representante_legal` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `direccion_representante` varchar(200) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `razon_social` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `email` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `telefono` varchar(15) COLLATE utf8mb4_general_ci NOT NULL,
  `fecha_inicio` date DEFAULT NULL,
  `fecha_fin` date DEFAULT NULL,
  `porcentaje_retencion` decimal(5,2) DEFAULT NULL,
  `codigo_cliente` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL,
  PRIMARY KEY (`idCliente`)
);
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `clientes`
--

LOCK TABLES `clientes` WRITE;
/*!40000 ALTER TABLE `clientes` DISABLE KEYS */;
INSERT INTO `clientes` VALUES (20,'Roberto','Col. Fatima','06626539-1','1121-010101-010-1','Natural','362215-1',NULL,NULL,NULL,'robert@gmail.com','1212-1212','2025-03-01',NULL,NULL,'CGR-00001'),(21,'Palo Alto SA CV','Lourdes Colon',NULL,'1121-010101-010-1','Contribuyente Jurídico','2-1','Luis Perez','Calle Principal #3 barrio el centro, lourdes colón, libertad norte',NULL,'infoInfo@gmail.com','1212-1212','2025-03-01',NULL,NULL,'CGR-00002'),(22,'Crist','Col. Santiago',NULL,'0121-010101-010-1','Sujeto Excluido','0-1',NULL,NULL,NULL,'crist@gmail.com','1212-1212','2025-03-01','2025-03-02',10.00,'CGR-00003');
/*!40000 ALTER TABLE `clientes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `codigos_autorizacion`
--

DROP TABLE IF EXISTS `codigos_autorizacion`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `codigos_autorizacion` (
  `id` int NOT NULL AUTO_INCREMENT,
  `codigo` varchar(255) NOT NULL,
  `fecha_creacion` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
);
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `codigos_autorizacion`
--

LOCK TABLES `codigos_autorizacion` WRITE;
/*!40000 ALTER TABLE `codigos_autorizacion` DISABLE KEYS */;
INSERT INTO `codigos_autorizacion` VALUES (1,'$2b$10$PrtBre2/YddNO45AvltQP.wXo/K0/X4iQlcgIqrwFgLLi2VLaeyQW','2025-02-25 13:19:48');
/*!40000 ALTER TABLE `codigos_autorizacion` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `detalle_traslados`
--

DROP TABLE IF EXISTS `detalle_traslados`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `detalle_traslados` (
  `id` int NOT NULL AUTO_INCREMENT,
  `traslado_id` int NOT NULL,
  `codigo_inventario` varchar(50) NOT NULL,
  `cantidad` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `traslado_id` (`traslado_id`),
  KEY `codigo_inventario` (`codigo_inventario`),
  CONSTRAINT `detalle_traslados_ibfk_1` FOREIGN KEY (`traslado_id`) REFERENCES `traslados` (`id`) ON DELETE CASCADE,
  CONSTRAINT `detalle_traslados_ibfk_2` FOREIGN KEY (`codigo_inventario`) REFERENCES `inventario` (`codigo`)
);
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `detalle_traslados`
--

LOCK TABLES `detalle_traslados` WRITE;
/*!40000 ALTER TABLE `detalle_traslados` DISABLE KEYS */;
INSERT INTO `detalle_traslados` VALUES (2,18,'INV-0001',2),(3,19,'INV-0002',1);
/*!40000 ALTER TABLE `detalle_traslados` ENABLE KEYS */;
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
);
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `detalle_ventas`
--

LOCK TABLES `detalle_ventas` WRITE;
/*!40000 ALTER TABLE `detalle_ventas` DISABLE KEYS */;
INSERT INTO `detalle_ventas` VALUES (10,23,'INV-0001','Motor 1',3,1000.00,3000.00),(11,24,'INV-0001','Motor 1',3,1000.00,3000.00),(12,24,'INV-0003','Motocicleta',2,1500.00,3000.00),(13,24,'INV-0002','MOTOCICLETA',2,3000.00,6000.00),(14,25,'INV-0001','Motor 1',1,1000.00,1000.00),(15,25,'INV-0002','MOTOCICLETA',4,3000.00,12000.00),(16,26,'INV-0001','Motor 1',3,1000.00,3000.00),(17,26,'INV-0002','MOTOCICLETA',2,3000.00,6000.00);
/*!40000 ALTER TABLE `detalle_ventas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `empleados`
--

DROP TABLE IF EXISTS `empleados`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `empleados` (
  `id` int NOT NULL AUTO_INCREMENT,
  `nombres` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `apellidos` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `profesion` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `codigo_empleado` varchar(20) COLLATE utf8mb4_general_ci NOT NULL,
  `afp` varchar(20) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `isss` varchar(20) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `dui` varchar(10) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `cargo` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
  `sucursal` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `telefono` varchar(9) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `celular` varchar(9) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `correo` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `direccion` text COLLATE utf8mb4_general_ci,
  `estado` enum('Activo','Inactivo') COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'Activo',
  `sueldo_base` decimal(10,2) DEFAULT NULL,
  `licencia` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `fecha_creacion` datetime DEFAULT CURRENT_TIMESTAMP,
  `fecha_actualizacion` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
);
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `empleados`
--

LOCK TABLES `empleados` WRITE;
/*!40000 ALTER TABLE `empleados` DISABLE KEYS */;
INSERT INTO `empleados` VALUES (5,'David','Portillo','Desarrollador','EMP-0002','0200-2002-0222','02-00202-02202-2','01026537-7','Gerente','JUC123','6728-9202','9292-0220','dav@gmail.com','Berlin','Activo',360.00,'No posee licencia','2025-02-13 16:15:40','2025-02-14 10:27:48'),(11,'Alvin','Rosales','Desarrollador','EMP-0003','06626539-1','12121212121212','06626539-1','Bodeguero','3344','7881-5424','7881-5424','alvin@gmail.com','col. fatima','Activo',4000.00,'Licencia Liviana','2025-02-26 19:41:21','2025-02-27 14:54:48');
/*!40000 ALTER TABLE `empleados` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `historial_ajustes`
--

DROP TABLE IF EXISTS `historial_ajustes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `historial_ajustes` (
  `id` int NOT NULL AUTO_INCREMENT,
  `codigo` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
  `nombre` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `descripcion` text COLLATE utf8mb4_general_ci NOT NULL,
  `precio` decimal(20,0) NOT NULL,
  `fecha` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `stock` int NOT NULL,
  `motivo` text COLLATE utf8mb4_general_ci NOT NULL,
  PRIMARY KEY (`id`)
);
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `historial_ajustes`
--

LOCK TABLES `historial_ajustes` WRITE;
/*!40000 ALTER TABLE `historial_ajustes` DISABLE KEYS */;
INSERT INTO `historial_ajustes` VALUES (1,'885','hhyyh','gg',24,'2025-02-18 00:00:00',6567,'gg'),(2,'1212','motor 1 editado','es un motor poderoso',300,'2025-02-18 12:28:34',15,'Equivocación de letras'),(3,'1212','motor 1 editado','es un motor poderoso',300,'2025-02-25 12:56:39',99,'mas unidades');
/*!40000 ALTER TABLE `historial_ajustes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `historial_cambios_clientes`
--

DROP TABLE IF EXISTS `historial_cambios_clientes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `historial_cambios_clientes` (
  `id` int NOT NULL AUTO_INCREMENT,
  `cliente_id` int NOT NULL,
  `fecha_cambio` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `datos_anteriores` json NOT NULL,
  `datos_nuevos` json NOT NULL,
  PRIMARY KEY (`id`),
  KEY `cliente_id` (`cliente_id`),
  CONSTRAINT `historial_cambios_clientes_ibfk_1` FOREIGN KEY (`cliente_id`) REFERENCES `clientes` (`idCliente`) ON DELETE CASCADE
);
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `historial_cambios_clientes`
--

LOCK TABLES `historial_cambios_clientes` WRITE;
/*!40000 ALTER TABLE `historial_cambios_clientes` DISABLE KEYS */;
INSERT INTO `historial_cambios_clientes` VALUES (8,21,'2025-03-01 10:28:40','{\"dui\": null, \"nit\": \"1121-010101-010-1\", \"email\": \"info@gmail.com\", \"nombre\": \"Palo Alto SA CV\", \"telefono\": \"1212-1212\", \"direccion\": \"Lourdes Colon\", \"fecha_fin\": null, \"idCliente\": 21, \"fecha_inicio\": \"2025-03-01T06:00:00.000Z\", \"razon_social\": null, \"tipo_cliente\": \"Contribuyente Jurídico\", \"codigo_cliente\": \"CGR-00002\", \"representante_legal\": \"Luis Perez\", \"porcentaje_retencion\": null, \"registro_contribuyente\": \"2-1\", \"direccion_representante\": \"Calle Principal #3 barrio el centro, lourdes colón, libertad norte\"}','{\"email\": \"infoInfo@gmail.com\", \"telefono\": \"1212-1212\", \"direccion\": \"Lourdes Colon\"}');
/*!40000 ALTER TABLE `historial_cambios_clientes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `historial_cambios_ofertas`
--

DROP TABLE IF EXISTS `historial_cambios_ofertas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `historial_cambios_ofertas` (
  `id` int NOT NULL AUTO_INCREMENT,
  `oferta_id` int NOT NULL,
  `codigo_oferta` varchar(50) NOT NULL,
  `datos_anteriores` json NOT NULL,
  `datos_nuevos` json NOT NULL,
  `fecha_cambio` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `oferta_id` (`oferta_id`),
  CONSTRAINT `historial_cambios_ofertas_ibfk_1` FOREIGN KEY (`oferta_id`) REFERENCES `ofertas` (`id`)
);
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `historial_cambios_ofertas`
--

LOCK TABLES `historial_cambios_ofertas` WRITE;
/*!40000 ALTER TABLE `historial_cambios_ofertas` DISABLE KEYS */;
/*!40000 ALTER TABLE `historial_cambios_ofertas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `historial_cambios_traslados`
--

DROP TABLE IF EXISTS `historial_cambios_traslados`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `historial_cambios_traslados` (
  `id` int NOT NULL AUTO_INCREMENT,
  `traslado_id` int NOT NULL,
  `codigo_traslado` varchar(50) NOT NULL,
  `datos_anteriores` json NOT NULL,
  `datos_nuevos` json NOT NULL,
  `fecha_cambio` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `traslado_id` (`traslado_id`),
  CONSTRAINT `historial_cambios_traslados_ibfk_1` FOREIGN KEY (`traslado_id`) REFERENCES `traslados` (`id`)
);
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `historial_cambios_traslados`
--

LOCK TABLES `historial_cambios_traslados` WRITE;
/*!40000 ALTER TABLE `historial_cambios_traslados` DISABLE KEYS */;
INSERT INTO `historial_cambios_traslados` VALUES (2,18,'TGR-00001','{\"estado\": \"Pendiente\", \"productos\": [{\"cantidad\": 2, \"codigo_inventario\": \"INV-0001\"}]}','{\"estado\": \"Completado\"}','2025-03-01 11:35:45');
/*!40000 ALTER TABLE `historial_cambios_traslados` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `historial_cambios_ventas`
--

DROP TABLE IF EXISTS `historial_cambios_ventas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `historial_cambios_ventas` (
  `id` int NOT NULL AUTO_INCREMENT,
  `venta_id` int NOT NULL,
  `codigo_venta` varchar(50) NOT NULL,
  `fecha_cambio` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `datos_anteriores` json NOT NULL,
  `datos_nuevos` json NOT NULL,
  PRIMARY KEY (`id`),
  KEY `venta_id` (`venta_id`),
  CONSTRAINT `historial_cambios_ventas_ibfk_1` FOREIGN KEY (`venta_id`) REFERENCES `ventas` (`idVentas`) ON DELETE CASCADE
);
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `historial_cambios_ventas`
--

LOCK TABLES `historial_cambios_ventas` WRITE;
/*!40000 ALTER TABLE `historial_cambios_ventas` DISABLE KEYS */;
/*!40000 ALTER TABLE `historial_cambios_ventas` ENABLE KEYS */;
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
);
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `inventario`
--

LOCK TABLES `inventario` WRITE;
/*!40000 ALTER TABLE `inventario` DISABLE KEYS */;
INSERT INTO `inventario` VALUES (2,'INV-0001','/uploads/1740841782010.png','Motor 1','Es un motor de gama alta','121212','12122',2,4,500.00,500.00,1000.00,31,10,'2025-03-01','2025-03-01','12121212','12121212',2),(3,'INV-0002','/uploads/1740851098934.png','MOTOCICLETA','AMARILLO NEON','SD5RCML08SH609058','UXAA2007S609058',2,5,2000.00,2000.00,3000.00,92,10,'2025-02-27','2025-03-01','1212','1',2),(4,'INV-0003','/uploads/1740852024034.png','Motocicleta','Una moto, buena moto','000000003030','883833939',2,5,1250.00,1620.00,1500.00,48,10,'2025-03-01','2025-03-01','00044004','00040404',2);
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
  `fecha_inicio` datetime NOT NULL,
  `fecha_fin` datetime NOT NULL,
  `estado` enum('Activa','Inactiva') NOT NULL DEFAULT 'Activa',
  `codigo_oferta` varchar(50) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `codigo_oferta` (`codigo_oferta`),
  KEY `inventario_id` (`inventario_id`),
  CONSTRAINT `ofertas_ibfk_1` FOREIGN KEY (`inventario_id`) REFERENCES `inventario` (`id`)
);
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
  `tipo_proveedor` enum('Natural','Jurídico') NOT NULL,
  `nombre_comercial` varchar(150) NOT NULL,
  `correo` varchar(100) NOT NULL,
  `direccion` text NOT NULL,
  `telefono` varchar(20) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `correo` (`correo`)
);
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `proveedores`
--

LOCK TABLES `proveedores` WRITE;
/*!40000 ALTER TABLE `proveedores` DISABLE KEYS */;
INSERT INTO `proveedores` VALUES (1,'Natural','Gobierno SV','mauricio@domain.com','Col. Roba','12121212'),(2,'Jurídico','Comercial buena ventura','ventua@gmail.com','Venturas del cielo col.','12121212');
/*!40000 ALTER TABLE `proveedores` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `proveedores_juridicos`
--

DROP TABLE IF EXISTS `proveedores_juridicos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `proveedores_juridicos` (
  `id` int NOT NULL AUTO_INCREMENT,
  `proveedor_id` int NOT NULL,
  `razon_social` varchar(200) NOT NULL,
  `nit` varchar(200) NOT NULL,
  `nrc` text NOT NULL,
  `giro` varchar(20) NOT NULL,
  `correspondencia` text NOT NULL,
  PRIMARY KEY (`id`),
  KEY `proveedor_id` (`proveedor_id`),
  CONSTRAINT `proveedores_juridicos_ibfk_1` FOREIGN KEY (`proveedor_id`) REFERENCES `proveedores` (`id`)
);
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `proveedores_juridicos`
--

LOCK TABLES `proveedores_juridicos` WRITE;
/*!40000 ALTER TABLE `proveedores_juridicos` DISABLE KEYS */;
INSERT INTO `proveedores_juridicos` VALUES (1,2,'Comercial de CA de CV','1212-121212-121-2','12121212111','Servicios','No tiene');
/*!40000 ALTER TABLE `proveedores_juridicos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `proveedores_naturales`
--

DROP TABLE IF EXISTS `proveedores_naturales`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `proveedores_naturales` (
  `id` int NOT NULL AUTO_INCREMENT,
  `proveedor_id` int NOT NULL,
  `nombre_propietario` varchar(200) NOT NULL,
  `dui` varchar(20) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `proveedor_id` (`proveedor_id`),
  CONSTRAINT `proveedores_naturales_ibfk_1` FOREIGN KEY (`proveedor_id`) REFERENCES `proveedores` (`id`)
);
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `proveedores_naturales`
--

LOCK TABLES `proveedores_naturales` WRITE;
/*!40000 ALTER TABLE `proveedores_naturales` DISABLE KEYS */;
INSERT INTO `proveedores_naturales` VALUES (1,1,'Mauricio Funes','12345679-9');
/*!40000 ALTER TABLE `proveedores_naturales` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sucursal`
--

DROP TABLE IF EXISTS `sucursal`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sucursal` (
  `id` int NOT NULL AUTO_INCREMENT,
  `codigo` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
  `nombre` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
  `pais` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
  `departamento` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
  `ciudad` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
  `estado` enum('Activo','Inactivo') COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'Activo',
  PRIMARY KEY (`id`),
  UNIQUE KEY `codigo` (`codigo`)
);
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sucursal`
--

LOCK TABLES `sucursal` WRITE;
/*!40000 ALTER TABLE `sucursal` DISABLE KEYS */;
INSERT INTO `sucursal` VALUES (4,'SGR-0001','CASA MATRIZ','El Salvador','Usulután','Usulután','Activo'),(5,'SGR-0002','SUCURSAL MAXIMOTO SAN SALVADOR','El Salvador','','San Salvador','Activo'),(6,'SGR-0003',' SUCURSAL MAXIMOTO SENSUNTEPEQUE','El Salvador','Cabañas','Sensuntepeque','Activo'),(7,'SGR-0004',' SUCURSAL MAXIMOTO SAN MIGUEL CENTRO','El Salvador','San Miguel','San Miguel','Activo'),(8,'SGR-0005',' SUCURSAL MAXIMOTO SANTA ANA','El Salvador','Santa Ana','Santa Ana','Activo');
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
  `codigo_traslado` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
  `codigo_sucursal_origen` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
  `codigo_sucursal_destino` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
  `codigo_empleado` varchar(20) COLLATE utf8mb4_general_ci NOT NULL,
  `fecha_traslado` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `estado` enum('Pendiente','Completado','Cancelado') COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'Pendiente',
  PRIMARY KEY (`id`),
  UNIQUE KEY `codigo_traslado` (`codigo_traslado`),
  KEY `codigo_sucursal_origen` (`codigo_sucursal_origen`),
  KEY `codigo_sucursal_destino` (`codigo_sucursal_destino`),
  CONSTRAINT `traslados_ibfk_2` FOREIGN KEY (`codigo_sucursal_origen`) REFERENCES `sucursal` (`codigo`),
  CONSTRAINT `traslados_ibfk_3` FOREIGN KEY (`codigo_sucursal_destino`) REFERENCES `sucursal` (`codigo`)
);
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `traslados`
--

LOCK TABLES `traslados` WRITE;
/*!40000 ALTER TABLE `traslados` DISABLE KEYS */;
INSERT INTO `traslados` VALUES (18,'TGR-00001','SGR-0001','SGR-0002','EMP-0003','2025-03-01 11:32:54','Completado'),(19,'TGR-00002','SGR-0001','SGR-0002','EMP-0003','2025-03-01 12:02:11','Pendiente');
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
  `empleado_id` int DEFAULT NULL,
  `nombre_completo` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `usuario` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
  `password` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `tipo_cuenta` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
  `cargo` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
  `fecha_creacion` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_actualizacion` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_empleado_id` (`empleado_id`),
  CONSTRAINT `fk_empleado_id` FOREIGN KEY (`empleado_id`) REFERENCES `empleados` (`id`)
);
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `usuarios`
--

LOCK TABLES `usuarios` WRITE;
/*!40000 ALTER TABLE `usuarios` DISABLE KEYS */;
INSERT INTO `usuarios` VALUES (1,NULL,'Super Usuario','root','123','Root','Administrador','2025-02-21 14:35:00','2025-02-21 14:35:44'),(9,11,'Alvin Rosales','Alvin','$2b$12$Avr3J.sRlruCYBKOeBdAlO/Ztgivb6EVyPJ8OtxlcytdICNsGWb.G','Normal','Bodeguero','2025-02-27 14:53:59','2025-02-27 14:54:48');
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
  `codigo_venta` varchar(50) NOT NULL,
  `fecha_venta` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `cliente_id` int DEFAULT NULL,
  `empleado_id` int NOT NULL,
  `tipo_factura` enum('Consumidor Final','Crédito Fiscal','Ticket') NOT NULL,
  `metodo_pago` enum('Efectivo','Tarjeta de Crédito','Transferencia Bancaria') NOT NULL,
  `total` decimal(10,2) NOT NULL,
  `descripcion_compra` text,
  `factura` varchar(100) DEFAULT NULL,
  `comprobante_credito_fiscal` varchar(100) DEFAULT NULL,
  `factura_exportacion` varchar(100) DEFAULT NULL,
  `nota_credito` varchar(100) DEFAULT NULL,
  `nota_debito` varchar(100) DEFAULT NULL,
  `nota_remision` varchar(100) DEFAULT NULL,
  `comprobante_liquidacion` varchar(100) DEFAULT NULL,
  `comprobante_retencion` varchar(100) DEFAULT NULL,
  `documento_contable_liquidacion` varchar(100) DEFAULT NULL,
  `comprobante_donacion` varchar(100) DEFAULT NULL,
  `factura_sujeto_excluido` varchar(100) DEFAULT NULL,
  `descuento` decimal(5,2) DEFAULT '0.00',
  `sucursal_id` int NOT NULL DEFAULT '4',
  `apertura_id` int NOT NULL,
  PRIMARY KEY (`idVentas`),
  UNIQUE KEY `codigo_venta` (`codigo_venta`),
  KEY `cliente_id` (`cliente_id`),
  KEY `empleado_id` (`empleado_id`),
  KEY `sucursal_id` (`sucursal_id`),
  KEY `fk_apertura` (`apertura_id`),
  CONSTRAINT `fk_apertura` FOREIGN KEY (`apertura_id`) REFERENCES `aperturas_caja` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `ventas_ibfk_1` FOREIGN KEY (`cliente_id`) REFERENCES `clientes` (`idCliente`) ON DELETE SET NULL,
  CONSTRAINT `ventas_ibfk_2` FOREIGN KEY (`empleado_id`) REFERENCES `empleados` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `ventas_ibfk_3` FOREIGN KEY (`sucursal_id`) REFERENCES `sucursal` (`id`)
);
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ventas`
--

LOCK TABLES `ventas` WRITE;
/*!40000 ALTER TABLE `ventas` DISABLE KEYS */;
INSERT INTO `ventas` VALUES (23,'VGR-00001','2025-03-03 17:55:08',22,11,'Consumidor Final','Efectivo',3322.20,'ninguns',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,2.00,4,12),(24,'VGR-00002','2025-03-04 11:04:55',21,11,'Consumidor Final','Efectivo',13424.40,'ninguna nota','1','1','1','1','1','1','1','1','1','1','1',1.00,4,14),(25,'VGR-00003','2025-03-04 11:07:36',22,11,'Crédito Fiscal','Tarjeta de Crédito',14396.20,'NINGUNA NOTA','2','2','2','2','2','2','2','2','2','2','2',2.00,4,14),(26,'VGR-00004','2025-03-04 12:47:35',21,11,'Consumidor Final','Transferencia Bancaria',10068.30,'ninguna nota','5','5','5','5','5','5','5','5','5','5','5',1.00,4,15);
/*!40000 ALTER TABLE `ventas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ventas_sucursales_manual`
--

DROP TABLE IF EXISTS `ventas_sucursales_manual`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ventas_sucursales_manual` (
  `id` int NOT NULL AUTO_INCREMENT,
  `venta_id` int NOT NULL,
  `sucursal_nombre` varchar(100) NOT NULL,
  `fecha_asignacion` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `venta_id` (`venta_id`),
  CONSTRAINT `ventas_sucursales_manual_ibfk_1` FOREIGN KEY (`venta_id`) REFERENCES `ventas` (`idVentas`) ON DELETE CASCADE
);
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ventas_sucursales_manual`
--

LOCK TABLES `ventas_sucursales_manual` WRITE;
/*!40000 ALTER TABLE `ventas_sucursales_manual` DISABLE KEYS */;
/*!40000 ALTER TABLE `ventas_sucursales_manual` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-03-04 13:05:11
