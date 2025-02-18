-- Crear la base de datos
CREATE DATABASE IF NOT EXISTS `sistema_dycris`;
USE `sistema_dycris`;


-- Tabla Inventario
CREATE TABLE inventario (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(50) UNIQUE NOT NULL,
    imagen varchar(255) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    numero_motor VARCHAR(50),
    numero_chasis VARCHAR(50),
    categoria_id INT NOT NULL,
    sucursal_id INT NOT NULL,
    costo DECIMAL(10,2) NOT NULL,
    credito DECIMAL(10,2),
    precio_venta DECIMAL(10,2) NOT NULL,
    stock_existencia INT NOT NULL,
    stock_minimo INT NOT NULL,
    fecha_ingreso DATE NOT NULL,
    fecha_reingreso DATE,
    numero_poliza VARCHAR(50),
    numero_lote VARCHAR(50),
    proveedor_id INT NOT NULL,
    FOREIGN KEY (categoria_id) REFERENCES categoria(id) ON DELETE CASCADE,
    FOREIGN KEY (sucursal_id) REFERENCES sucursal(id) ON DELETE CASCADE,
    FOREIGN KEY (proveedor_id) REFERENCES proveedores(id) ON DELETE CASCADE
);
INSERT INTO inventario (
    codigo, imagen, nombre, descripcion, numero_motor, numero_chasis, categoria_id, sucursal_id, costo, credito, precio_venta, stock_existencia, stock_minimo, fecha_ingreso, fecha_reingreso, numero_poliza, numero_lote, proveedor_id
) VALUES
    ('INV001', 'imagen1.jpg', 'Laptop Dell', 'Laptop de 15 pulgadas con procesador Intel Core i5', '1234567890', 'ABCDEFGHIJKLM', 1, 1, 1000.00, 200.00, 1200.00, 50, 10, '2023-10-27', NULL, 'POLIZA123', 'LOTE456', 1);




-- Tabla Usuarios (versión original con rol ENUM)
CREATE TABLE `usuarios` (
  `id` int NOT NULL AUTO_INCREMENT,
  `nombre_completo` varchar(255) NOT NULL,
  `usuario` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL,
  `rol` enum('Admin','Caja','Asesor de Venta') NOT NULL,
  `fecha_creacion` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_actualizacion` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
);

INSERT INTO usuarios (`nombre_completo`, `usuario`, `password`, `rol`,  `fecha_creacion`, `fecha_actualizacion`) 
VALUES ('Alvin Rosales', 'admin', 4444, 'Admin', DATE(NOW()),DATE(NOW()));



-- Tabla Sucursal
CREATE TABLE sucursal (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(50) UNIQUE NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    pais VARCHAR(50) NOT NULL,
    departamento VARCHAR(50) NOT NULL,
    ciudad VARCHAR(50) NOT NULL,
    estado ENUM('Activo', 'Inactivo') NOT NULL DEFAULT 'Activo'
);
INSERT INTO sucursal (codigo, nombre, pais, departamento, ciudad, estado) VALUES
    ('S001', 'Sucursal Principal', 'Colombia', 'Bogotá', 'Bogotá', 'Activo');



-- Tabla Categoría
CREATE TABLE categoria (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL,
    descripcion TEXT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    estado ENUM('Activo', 'Inactivo') NOT NULL DEFAULT 'Activo'
);
INSERT INTO categoria (nombre, descripcion, estado) VALUES
    ('Tecnología', 'Productos electrónicos, computadores, etc.', 'Activo');



-- Tabla Proveedores
CREATE TABLE proveedores (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    direccion TEXT NOT NULL,
    contacto VARCHAR(20) NOT NULL,
    correo VARCHAR(100) UNIQUE NOT NULL,
    clasificacion VARCHAR(50),
    tipo_persona ENUM('Natural', 'Jurídica') NOT NULL,
    numero_factura_compra VARCHAR(50),
    ley_tributaria TEXT
);
INSERT INTO proveedores (nombre, direccion, contacto, correo, clasificacion, tipo_persona, numero_factura_compra, ley_tributaria) VALUES
    ('Proveedor A', 'Calle 123, Ciudad A', '1234567890', 'proveedorA@example.com', 'Mayorista', 'Jurídica', '1234567890', 'Ley Tributaria 123');






-- Historial de ajustes


CREATE TABLE historial_ajustes (
  id int(20) primary key auto_increment,
  codigo varchar(50) NOT NULL,
  nombre varchar(50),
  descripcion text NOT NULL,
  precio decimal(20,0) NOT NULL,
  fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  stock int(20) NOT NULL,
  motivo text NOT NULL
);
INSERT INTO historial_ajustes (codigo, nombre, descripcion, precio, fecha, stock, motivo)
VALUES ('885', 'hhyyh', 'gg', 24, CURDATE(), 6567, 'gg');








-- Tabla Clientes (con campos ampliados)
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
);

-- Tabla Ventas
CREATE TABLE `ventas` (
  `idVentas` int NOT NULL AUTO_INCREMENT,
  `fecha_venta` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `cliente_id` int DEFAULT NULL,
  `tipo_factura` enum('Consumidor Final','Crédito Fiscal','Ticket') NOT NULL,
  `metodo_pago` enum('Efectivo','Tarjeta de Crédito','Transferencia Bancaria') NOT NULL,
  `total` decimal(10,2) NOT NULL,
  `descripcion_compra` text,
  PRIMARY KEY (`idVentas`),
  FOREIGN KEY (`cliente_id`) REFERENCES `clientes`(`idCliente`)
);

-- Tabla Detalle Ventas
CREATE TABLE `detalle_ventas` (
  `idDetalle` int NOT NULL AUTO_INCREMENT,
  `idVentas` int NOT NULL,
  `codigo_producto` varchar(50) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `cantidad` int NOT NULL,
  `precio_unitario` decimal(10,2) NOT NULL,
  `subtotal` decimal(10,2) NOT NULL,
  PRIMARY KEY (`idDetalle`),
  FOREIGN KEY (`idVentas`) REFERENCES `ventas`(`idVentas`),
  FOREIGN KEY (`codigo_producto`) REFERENCES `inventario`(`codigo`)
);



-- Tabla Traslados (simplificada sin dependencias eliminadas)
CREATE TABLE `traslados` (
  `id` int NOT NULL AUTO_INCREMENT,
  `codigo_traslado` varchar(50) NOT NULL,
  `inventario_id` int NOT NULL,
  `origen` varchar(50) NOT NULL, -- Nombre de sucursal en texto
  `destino` varchar(50) NOT NULL, -- Nombre de sucursal en texto
  `cantidad` int NOT NULL,
  `fecha_traslado` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `responsable` varchar(100) NOT NULL, -- Nombre del responsable directo
  `estado` enum('Pendiente','Completado','Cancelado') NOT NULL DEFAULT 'Pendiente',
  PRIMARY KEY (`id`),
  UNIQUE KEY `codigo_traslado` (`codigo_traslado`),
  FOREIGN KEY (`inventario_id`) REFERENCES `inventario`(`id`)
);

-- Tabla Ofertas
CREATE TABLE `ofertas` (
  `id` int NOT NULL AUTO_INCREMENT,
  `inventario_id` int NOT NULL,
  `descuento` decimal(5,2) NOT NULL,
  `fecha_inicio` date NOT NULL,
  `fecha_fin` date NOT NULL,
  `estado` enum('Activa','Inactiva') NOT NULL DEFAULT 'Activa',
  PRIMARY KEY (`id`),
  FOREIGN KEY (`inventario_id`) REFERENCES `inventario`(`id`)
);




select * from clientes;
INSERT INTO clientes (nombre, direccion, dui, nit, tipo_cliente, email, telefono)  
VALUES ('Juan Pérez', 'San Salvador, El Salvador', '12345678-9', '0614-050616-101-3', 'Natural', 'juan@example.com', '7777-7777');


INSERT INTO ventas (cliente_id, tipo_factura, metodo_pago, total, descripcion_compra)  
VALUES (1, 'Consumidor Final', 'Efectivo', 1200.00, 'Venta de motocicleta');
select * from ventas;

INSERT INTO detalle_ventas (idVentas, codigo_producto, nombre, cantidad, precio_unitario, subtotal)  
VALUES (LAST_INSERT_ID(), 'PROD001', 'Motocicleta XYZ', 1, 1200.00, 1200.00);

