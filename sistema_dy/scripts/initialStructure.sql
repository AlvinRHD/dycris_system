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



select * from usuarios;