CREATE DATABASE sistema_dycris;
USE sistema_dycris;


#######-- TABLE INVENTARIO --#########
CREATE TABLE inventario (
  id int(11) NOT NULL,
  codigo varchar(50) NOT NULL,
  nombre varchar(100) NOT NULL,
  descripcion text DEFAULT NULL,
  nro_motor varchar(20) NOT NULL,
  nro_chasis varchar(20) NOT NULL,
  categoria varchar(50) DEFAULT NULL,
  sucursal varchar(50) DEFAULT NULL,
  precio_compra decimal(10,2) NOT NULL,
  credito decimal(10,2) DEFAULT 0.00,
  precio_venta decimal(10,2) NOT NULL,
  stock_existencia int(11) NOT NULL DEFAULT 0,
  stock_minimo int(11) NOT NULL DEFAULT 0,
  fecha_ingreso date NOT NULL,
  fecha_reingreso date DEFAULT NULL,
  nro_poliza varchar(50) DEFAULT NULL,
  nro_lote varchar(50) DEFAULT NULL
);
select * from sucursal;

#######--TABLE PROVEEDORES --##########
CREATE TABLE proveedores (
  id int(10) NOT NULL,
  nombre varchar(20) NOT NULL,
  direccion varchar(20) NOT NULL,
  contacto varchar(20) NOT NULL,
  correo varchar(20) NOT NULL,
  clasificacion varchar(20) NOT NULL,
  tipo_persona varchar(20) NOT NULL,
  n_factura_compra varchar(20) NOT NULL,
  ley_tributaria varchar(20) NOT NULL
);


#######-- TABLE USUARIOS --##########
CREATE TABLE usuarios (
  id bigint(20) UNSIGNED NOT NULL,
  nombre_completo varchar(255) NOT NULL,
  usuario varchar(50) NOT NULL,
  password varchar(255) NOT NULL,
  rol enum('Admin','Caja','Asesor de Venta') NOT NULL,
  fecha_creacion timestamp NOT NULL DEFAULT current_timestamp(),
  fecha_actualizacion timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
);



#######-- TABLE VENTAS --#########
CREATE TABLE ventas (
  idVentas INT AUTO_INCREMENT PRIMARY KEY,
  fecha_venta DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  cliente_id INT, -- Para enlazar con la tabla de clientes
  tipo_factura ENUM('Consumidor Final', 'Crédito Fiscal', 'Ticket') NOT NULL,
  metodo_pago ENUM('Efectivo', 'Tarjeta de Crédito', 'Transferencia Bancaria') NOT NULL,
  total DECIMAL(10,2) NOT NULL,
  descripcion_compra TEXT DEFAULT NULL
);
select * from ventas;

CREATE TABLE detalle_ventas (
  idDetalle INT AUTO_INCREMENT PRIMARY KEY,
  idVentas INT NOT NULL, -- Relación con la tabla `ventas`
  codigo_producto VARCHAR(50) NOT NULL,
  nombre VARCHAR(100) NOT NULL,
  cantidad INT NOT NULL,
  precio_unitario DECIMAL(10,2) NOT NULL,
  subtotal DECIMAL(10,2) NOT NULL,
  FOREIGN KEY (idVentas) REFERENCES ventas(idVentas),
  FOREIGN KEY (codigo_producto) REFERENCES inventario(codigo)
)CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE clientes (
  idCliente INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  direccion VARCHAR(200) DEFAULT NULL,
  dui VARCHAR(10) DEFAULT NULL,
  nit VARCHAR(17) DEFAULT NULL
);
select * from inventario;



drop table ventas;
SELECT * FROM ventas WHERE idVentas = 3;

ALTER TABLE ventas ADD COLUMN fecha_venta DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP;


CREATE TABLE `traslados` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `codigo_traslado` VARCHAR(50) NOT NULL UNIQUE,
  `inventario_id` INT NOT NULL,
  `origen_id` INT NOT NULL, -- ID de la sucursal de origen
  `destino_id` INT NOT NULL, -- ID de la sucursal de destino
  `cantidad` INT NOT NULL,
  `fecha_traslado` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `empleado_id` INT NOT NULL, -- Quién realizó el traslado
  `estado` ENUM('Pendiente', 'Completado', 'Cancelado') NOT NULL DEFAULT 'Pendiente',
  FOREIGN KEY (`inventario_id`) REFERENCES `inventario`(`id`),
  FOREIGN KEY (`origen_id`) REFERENCES `sucursal`(`id`),
  FOREIGN KEY (`destino_id`) REFERENCES `sucursal`(`id`),
  FOREIGN KEY (`empleado_id`) REFERENCES `empleados`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `ofertas` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `inventario_id` INT NOT NULL, -- Relación con el producto en inventario
  `descuento` DECIMAL(5,2) NOT NULL, -- Porcentaje de descuento (ej: 10.50)
  `fecha_inicio` DATE NOT NULL, -- Fecha de inicio de la oferta
  `fecha_fin` DATE NOT NULL, -- Fecha de fin de la oferta
  `estado` ENUM('Activa', 'Inactiva') NOT NULL DEFAULT 'Activa',
  FOREIGN KEY (`inventario_id`) REFERENCES `inventario`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


select * from ofertas;



 SELECT 
        v.idVentas,
        v.fecha_venta,
        v.tipo_factura,
        v.metodo_pago,
        v.total,
        v.descripcion_compra,
        c.nombre AS cliente_nombre,
        JSON_ARRAYAGG(
          JSON_OBJECT(
            'codigo', dv.codigo_producto,
            'nombre', i.nombre,
            'cantidad', dv.cantidad,
            'precio', dv.precio_unitario,
            'costo', i.precio_compra
          )
        ) AS productos
      FROM ventas v
      LEFT JOIN clientes c ON v.cliente_id = c.idCliente
      LEFT JOIN detalle_ventas dv ON v.idVentas = dv.idVentas
      LEFT JOIN inventario i ON dv.codigo_producto = i.codigo
      GROUP BY v.idVentas