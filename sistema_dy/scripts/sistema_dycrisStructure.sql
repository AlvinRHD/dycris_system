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


-- Tabla Sucursal
CREATE TABLE sucursal (
    idproveedores INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(50) UNIQUE NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    pais VARCHAR(50) NOT NULL,
    departamento VARCHAR(50) NOT NULL,
    ciudad VARCHAR(50) NOT NULL,
    estado ENUM('Activo', 'Inactivo') NOT NULL DEFAULT 'Activo'
);
select * from proveedores;
SELECT codigo, nombre FROM sucursal WHERE estado = 'Activo';


-- Tabla Categoría
CREATE TABLE categoria (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL,
    descripcion TEXT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    estado ENUM('Activo', 'Inactivo') NOT NULL DEFAULT 'Activo'
);

-- Tabla Proveedores -- tabla anterior 
/**CREATE TABLE proveedores (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    direccion TEXT NOT NULL,
    contacto VARCHAR(20) NOT NULL,
    correo VARCHAR(100) UNIQUE NOT NULL,
    clasificacion VARCHAR(50),
    tipo_persona ENUM('Natural', 'Jurídica') NOT NULL,
    numero_factura_compra VARCHAR(50),
    ley_tributaria TEXT
);**/

-- tablas nuevas
CREATE TABLE `proveedores` (
  `id` int primary key NOT NULL AUTO_INCREMENT,
  `tipo_proveedor` enum('Natural','Jurídico') NOT NULL,
  `nombre_comercial` varchar(150) NOT NULL,
  `correo` varchar(100) NOT NULL unique key,
  `direccion` text NOT NULL,
  `telefono` varchar(20) NOT NULL
);
select * from proveedores;
use sistema_dycris;

-- segunda tabla de proveedores
CREATE TABLE `proveedores_juridicos` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `proveedor_id` int(11) NOT NULL,
  `razon_social` varchar(200) NOT NULL,
  `nit` varchar(200) NOT NULL,
  `nrc` text NOT NULL,
  `giro` varchar(20) NOT NULL,
  `correspondencia` text NOT NULL,
  PRIMARY KEY (`id`),
  KEY `proveedor_id` (`proveedor_id`),
  CONSTRAINT `proveedores_juridicos_ibfk_1` FOREIGN KEY (`proveedor_id`) REFERENCES `proveedores` (`id`)
);

-- tercera tabla para proveedores
CREATE TABLE `proveedores_naturales` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `proveedor_id` int(11) NOT NULL,
  `nombre_propietario` varchar(200) NOT NULL,
  `dui` varchar(20) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `proveedor_id` (`proveedor_id`),
  CONSTRAINT `proveedores_naturales_ibfk_1` FOREIGN KEY (`proveedor_id`) REFERENCES `proveedores` (`id`)
);







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

-- Modificar la tabla clientes para agregar el campo codigo_cliente
ALTER TABLE `clientes`
ADD COLUMN `codigo_cliente` VARCHAR(50);



select * from clientes;

-- historial de cambios para la tabla de clientes
CREATE TABLE `historial_cambios_clientes` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `cliente_id` INT NOT NULL,
  `fecha_cambio` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `datos_anteriores` JSON NOT NULL, -- Estado anterior del cliente
  `datos_nuevos` JSON NOT NULL, -- Estado nuevo después del cambio
  PRIMARY KEY (`id`),
  FOREIGN KEY (`cliente_id`) REFERENCES `clientes`(`idCliente`) ON DELETE CASCADE
);



/**
-- Tabla Ventas -- anterior
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
**/



select * from ventas;
-- Modificar la tabla Ventas
DROP TABLE IF EXISTS `ventas`; -- Eliminar la tabla anterior para recrearla con los cambios
CREATE TABLE `ventas` (
  `idVentas` int NOT NULL AUTO_INCREMENT,
  `codigo_venta` VARCHAR(50) UNIQUE NOT NULL, -- Nuevo campo para el código de venta
  `fecha_venta` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `cliente_id` int DEFAULT NULL,
  `empleado_id` int NOT NULL, -- Nueva relación con empleados
  `tipo_factura` ENUM('Consumidor Final', 'Crédito Fiscal', 'Ticket') NOT NULL,
  `metodo_pago` ENUM('Efectivo', 'Tarjeta de Crédito', 'Transferencia Bancaria') NOT NULL,
  `total` DECIMAL(10,2) NOT NULL,
  `descripcion_compra` TEXT,
  -- Campos adicionales para los documentos asociados según tipo de factura
  `factura` VARCHAR(100) DEFAULT NULL, -- Número o identificador del documento
  `comprobante_credito_fiscal` VARCHAR(100) DEFAULT NULL,
  `factura_exportacion` VARCHAR(100) DEFAULT NULL,
  `nota_credito` VARCHAR(100) DEFAULT NULL,
  `nota_debito` VARCHAR(100) DEFAULT NULL,
  `nota_remision` VARCHAR(100) DEFAULT NULL,
  `comprobante_liquidacion` VARCHAR(100) DEFAULT NULL,
  `comprobante_retencion` VARCHAR(100) DEFAULT NULL,
  `documento_contable_liquidacion` VARCHAR(100) DEFAULT NULL,
  `comprobante_donacion` VARCHAR(100) DEFAULT NULL,
  `factura_sujeto_excluido` VARCHAR(100) DEFAULT NULL,
  PRIMARY KEY (`idVentas`),
  FOREIGN KEY (`cliente_id`) REFERENCES `clientes`(`idCliente`) ON DELETE SET NULL,
  FOREIGN KEY (`empleado_id`) REFERENCES `empleados`(`id`) ON DELETE RESTRICT
);
select * from ventas;
-- Agregar campo descuento a la tabla ventas oara autorizacion
ALTER TABLE `ventas` ADD COLUMN `descuento` DECIMAL(5,2) DEFAULT 0.00;

-- Crear tabla para códigos de autorización
CREATE TABLE `codigos_autorizacion` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `codigo` VARCHAR(255) NOT NULL, -- Cifrado con bcrypt
  `fecha_creacion` DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Contra con hash para codigos creada desde el backend
INSERT INTO codigos_autorizacion (codigo) VALUES ('$2b$10$PrtBre2/YddNO45AvltQP.wXo/K0/X4iQlcgIqrwFgLLi2VLaeyQW');


-- tabla historial de cambios de ventas
CREATE TABLE `historial_cambios_ventas` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `venta_id` INT NOT NULL,
  `codigo_venta` VARCHAR(50) NOT NULL,
  `fecha_cambio` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `datos_anteriores` JSON NOT NULL, -- Estado anterior de la venta
  `datos_nuevos` JSON NOT NULL, -- Estado nuevo después del cambio
  PRIMARY KEY (`id`),
  FOREIGN KEY (`venta_id`) REFERENCES `ventas`(`idVentas`) ON DELETE CASCADE
);

select * from historial_cambios_ventas;




-- Tabla Detalle Ventas
CREATE TABLE `detalle_ventas` (
  `idDetalle` int NOT NULL AUTO_INCREMENT,
  `idVentas` int NOT NULL,
  `codigo_producto` varchar(50) NOT NULL,  -- Aquí se ajusta la colación
  `nombre` varchar(100) NOT NULL,
  `cantidad` int NOT NULL,
  `precio_unitario` decimal(10,2) NOT NULL,
  `subtotal` decimal(10,2) NOT NULL,
  PRIMARY KEY (`idDetalle`),
  FOREIGN KEY (`idVentas`) REFERENCES `ventas`(`idVentas`),
  FOREIGN KEY (`codigo_producto`) REFERENCES `inventario`(`codigo`)  -- Definimos la FK con la tabla inventario
);
SHOW FULL COLUMNS FROM inventario;



-- Tabla Traslados (simplificada sin dependencias eliminadas)
-- Tabla Traslados (modificada para usar códigos)
CREATE TABLE `traslados` (
  `id` int NOT NULL AUTO_INCREMENT,
  `codigo_traslado` varchar(50) NOT NULL,
  `codigo_inventario` varchar(50) NOT NULL, -- Cambiado a código
  `codigo_sucursal_origen` varchar(50) NOT NULL, -- Código de sucursal
  `codigo_sucursal_destino` varchar(50) NOT NULL, -- Código de sucursal
  `codigo_empleado` varchar(20) NOT NULL, -- Código de empleado
  `cantidad` int NOT NULL,
  `fecha_traslado` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `estado` enum('Pendiente','Completado','Cancelado') NOT NULL DEFAULT 'Pendiente',
  PRIMARY KEY (`id`),
  UNIQUE KEY `codigo_traslado` (`codigo_traslado`),
  FOREIGN KEY (`codigo_inventario`) REFERENCES `inventario`(`codigo`),
  FOREIGN KEY (`codigo_sucursal_origen`) REFERENCES `sucursal`(`codigo`),
  FOREIGN KEY (`codigo_sucursal_destino`) REFERENCES `sucursal`(`codigo`)
);

ALTER TABLE traslados DROP FOREIGN KEY traslados_ibfk_1;

-- Modificar la tabla traslados para eliminar codigo_inventario y cantidad
ALTER TABLE traslados
  DROP COLUMN codigo_inventario,
  DROP COLUMN cantidad;


SHOW CREATE TABLE inventario;

-- Crear tabla detalle_traslados
CREATE TABLE detalle_traslados (
  id INT AUTO_INCREMENT PRIMARY KEY,
  traslado_id INT NOT NULL,
  codigo_inventario VARCHAR(50)NOT NULL,
  cantidad INT NOT NULL,
  FOREIGN KEY (traslado_id) REFERENCES traslados(id) ON DELETE CASCADE,
  FOREIGN KEY (codigo_inventario) REFERENCES inventario(codigo)
);



CREATE TABLE historial_cambios_traslados (
  id INT AUTO_INCREMENT PRIMARY KEY,
  traslado_id INT NOT NULL,
  codigo_traslado VARCHAR(50) NOT NULL,
  datos_anteriores JSON NOT NULL,
  datos_nuevos JSON NOT NULL,
  fecha_cambio DATETIME NOT NULL,
  FOREIGN KEY (traslado_id) REFERENCES traslados(id)
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

ALTER TABLE ofertas ADD COLUMN codigo_oferta VARCHAR(50) NOT NULL UNIQUE;
select * from ventas;

ALTER TABLE ofertas MODIFY COLUMN fecha_inicio DATETIME NOT NULL;
ALTER TABLE ofertas MODIFY COLUMN fecha_fin DATETIME NOT NULL;

CREATE TABLE historial_cambios_ofertas (
  id INT AUTO_INCREMENT PRIMARY KEY,
  oferta_id INT NOT NULL,
  codigo_oferta VARCHAR(50) NOT NULL,
  datos_anteriores JSON NOT NULL,
  datos_nuevos JSON NOT NULL,
  fecha_cambio DATETIME NOT NULL,
  FOREIGN KEY (oferta_id) REFERENCES ofertas(id)
);



-- // Empleados
-- Tabla 'empleados'
CREATE TABLE `empleados` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombres` varchar(100) NOT NULL,
  `apellidos` varchar(100) NOT NULL,
  `profesion` varchar(100) DEFAULT NULL,
  `codigo_empleado` varchar(20) NOT NULL,
  `afp` varchar(20) DEFAULT NULL,
  `isss` varchar(20) DEFAULT NULL,
  `dui` varchar(10) DEFAULT NULL,
  `cargo` varchar(50) NOT NULL CHECK (`cargo` in ('Administrador','Gerente','Cajero','Vendedor','Bodeguero')),
  `sucursal` varchar(100) DEFAULT NULL,
  `telefono` varchar(9) DEFAULT NULL,
  `celular` varchar(9) DEFAULT NULL,
  `correo` varchar(100) DEFAULT NULL,
  `direccion` text DEFAULT NULL,
  `estado` enum('Activo','Inactivo') NOT NULL DEFAULT 'Activo',
  `sueldo_base` decimal(10,2) DEFAULT NULL,
  `licencia` varchar(50) DEFAULT NULL,
  `fecha_creacion` datetime DEFAULT current_timestamp(),
  `fecha_actualizacion` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`)
);


-- Tabla 'usuarios'
CREATE TABLE `usuarios` (
  `id` int(11) PRIMARY KEY AUTO_INCREMENT,
  `empleado_id` int(11) DEFAULT NULL,
  `nombre_completo` varchar(255) NOT NULL,
  `usuario` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL,
  `tipo_cuenta` varchar(50) NOT NULL CHECK (`tipo_cuenta` in ('Admin','Root','Normal')),
  `cargo` varchar(50) NOT NULL CHECK (`cargo` in ('Administrador','Gerente','Cajero','Vendedor','Bodeguero')),
  `fecha_creacion` datetime NOT NULL DEFAULT current_timestamp(),
  `fecha_actualizacion` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  FOREIGN KEY (`empleado_id`) REFERENCES `empleados`(`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE
);

select * from usuarios;
use sistema_dycris;
SELECT * FROM codigos_autorizacion;

