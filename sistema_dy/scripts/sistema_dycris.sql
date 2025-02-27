-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: localhost
-- Tiempo de generación: 24-02-2025 a las 15:09:05
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `sistema_dycris`
--

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `categoria`
--

CREATE TABLE `categoria` (
  `id` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `descripcion` text DEFAULT NULL,
  `fecha_creacion` timestamp NULL DEFAULT current_timestamp(),
  `estado` enum('Activo','Inactivo') NOT NULL DEFAULT 'Activo'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `categoria`
--

INSERT INTO `categoria` (`id`, `nombre`, `descripcion`, `fecha_creacion`, `estado`) VALUES
(1, 'Tecnología', 'Productos electrónicos, computadores, etc.', '2025-02-18 16:36:20', 'Activo'),
(2, 'Motores', 'ninguna por el momento', '2025-02-18 18:46:16', 'Activo');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `clientes`
--

CREATE TABLE `clientes` (
  `idCliente` int(11) NOT NULL,
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
  `porcentaje_retencion` decimal(5,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `clientes`
--

INSERT INTO `clientes` (`idCliente`, `nombre`, `direccion`, `dui`, `nit`, `tipo_cliente`, `registro_contribuyente`, `representante_legal`, `direccion_representante`, `razon_social`, `email`, `telefono`, `fecha_inicio`, `fecha_fin`, `porcentaje_retencion`) VALUES
(1, 'Juan Pérez', 'ahora si con direccion', '12345678-9', '0614-050616-101-3', 'Natural', NULL, NULL, NULL, NULL, 'juan@example.com', '7777-7777', NULL, NULL, NULL),
(2, 'Alvin Rosales', 'Col. Fatima', '06626539-1', '06626539-1', 'Natural', NULL, NULL, NULL, NULL, 'ezequielhernandes907@gmail.com', '1212-1212', NULL, NULL, NULL),
(3, 'alvin', 'col.fatima', '', '', 'Consumidor Final', '1212-12121212', '', '', '', 'alvin@gmail.com', '1212-1212', '2025-02-17', '2025-02-28', NULL),
(5, 'Juan Rodriguez Gonzales Hernandez', 'por ahi', '', '0614-050616-101-3', 'Sujeto Excluido', '', '', '', '', 'juan@gmail.com', '1212-1212', '2025-02-19', '2025-02-20', 10.00),
(6, 'aasas', 'asasas', '', '0122-121212-121-2', 'Sujeto Excluido', '', '', '', '', '1212@gmail.com', '1212', '2025-02-19', '2025-02-20', 10.00),
(7, 'edit', 'asasas', '14141212-9', '1212-121221-121-1', 'Natural', '12121212121212', 'empresa', 'cop as', '', 'edit@gmail.com', '14514143', '2025-02-19', NULL, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalle_ventas`
--

CREATE TABLE `detalle_ventas` (
  `idDetalle` int(11) NOT NULL,
  `idVentas` int(11) NOT NULL,
  `codigo_producto` varchar(50) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `cantidad` int(11) NOT NULL,
  `precio_unitario` decimal(10,2) NOT NULL,
  `subtotal` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `detalle_ventas`
--

INSERT INTO `detalle_ventas` (`idDetalle`, `idVentas`, `codigo_producto`, `nombre`, `cantidad`, `precio_unitario`, `subtotal`) VALUES
(2, 4, '1212', 'motor 1 editado', 11, 300.00, 3300.00),
(3, 5, '1212', 'motor 1 editado', 1, 300.00, 300.00),
(4, 6, '1212', 'motor 1 editado', 1, 300.00, 300.00);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `empleados`
--

CREATE TABLE `empleados` (
  `id` int(11) NOT NULL,
  `nombres` varchar(100) NOT NULL,
  `apellidos` varchar(100) NOT NULL,
  `profesion` varchar(100) DEFAULT NULL,
  `codigo_empleado` varchar(20) NOT NULL,
  `afp` varchar(20) DEFAULT NULL,
  `isss` varchar(20) DEFAULT NULL,
  `dui` varchar(10) DEFAULT NULL,
  `cargo` varchar(50) NOT NULL,
  `sucursal` varchar(100) DEFAULT NULL,
  `telefono` varchar(9) DEFAULT NULL,
  `celular` varchar(9) DEFAULT NULL,
  `correo` varchar(100) DEFAULT NULL,
  `direccion` text DEFAULT NULL,
  `estado` enum('Activo','Inactivo') NOT NULL DEFAULT 'Activo',
  `sueldo_base` decimal(10,2) DEFAULT NULL,
  `licencia` varchar(50) DEFAULT NULL,
  `fecha_creacion` datetime DEFAULT current_timestamp(),
  `fecha_actualizacion` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `empleados`
--

INSERT INTO `empleados` (`id`, `nombres`, `apellidos`, `profesion`, `codigo_empleado`, `afp`, `isss`, `dui`, `cargo`, `sucursal`, `telefono`, `celular`, `correo`, `direccion`, `estado`, `sueldo_base`, `licencia`, `fecha_creacion`, `fecha_actualizacion`) VALUES
(5, 'David', 'Portillo', 'Desarrollador', 'EMP-0002', '0200-2002-0222', '02-00202-02202-2', '01026537-7', 'Gerente', 'JUC123', '6728-9202', '9292-0220', 'dav@gmail.com', 'Berlin', 'Activo', 360.00, 'No posee licencia', '2025-02-13 16:15:40', '2025-02-14 10:27:48');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `historial_ajustes`
--

CREATE TABLE `historial_ajustes` (
  `id` int(11) NOT NULL,
  `codigo` varchar(50) NOT NULL,
  `nombre` varchar(50) DEFAULT NULL,
  `descripcion` text NOT NULL,
  `precio` decimal(20,0) NOT NULL,
  `fecha` datetime NOT NULL DEFAULT current_timestamp(),
  `stock` int(11) NOT NULL,
  `motivo` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `historial_ajustes`
--

INSERT INTO `historial_ajustes` (`id`, `codigo`, `nombre`, `descripcion`, `precio`, `fecha`, `stock`, `motivo`) VALUES
(1, '885', 'hhyyh', 'gg', 24, '2025-02-18 00:00:00', 6567, 'gg'),
(2, '1212', 'motor 1 editado', 'es un motor poderoso', 300, '2025-02-18 12:28:34', 15, 'Equivocación de letras');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `inventario`
--

CREATE TABLE `inventario` (
  `id` int(11) NOT NULL,
  `codigo` varchar(50) NOT NULL,
  `imagen` varchar(255) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `descripcion` text DEFAULT NULL,
  `numero_motor` varchar(50) DEFAULT NULL,
  `numero_chasis` varchar(50) DEFAULT NULL,
  `categoria_id` int(11) NOT NULL,
  `sucursal_id` int(11) NOT NULL,
  `costo` decimal(10,2) NOT NULL,
  `credito` decimal(10,2) DEFAULT NULL,
  `precio_venta` decimal(10,2) NOT NULL,
  `stock_existencia` int(11) NOT NULL,
  `stock_minimo` int(11) NOT NULL,
  `fecha_ingreso` date NOT NULL,
  `fecha_reingreso` date DEFAULT NULL,
  `numero_poliza` varchar(50) DEFAULT NULL,
  `numero_lote` varchar(50) DEFAULT NULL,
  `proveedor_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `inventario`
--

INSERT INTO `inventario` (`id`, `codigo`, `imagen`, `nombre`, `descripcion`, `numero_motor`, `numero_chasis`, `categoria_id`, `sucursal_id`, `costo`, `credito`, `precio_venta`, `stock_existencia`, `stock_minimo`, `fecha_ingreso`, `fecha_reingreso`, `numero_poliza`, `numero_lote`, `proveedor_id`) VALUES
(2, '1212', '/uploads/1739903246807.png', 'motor 1 editado', 'es un motor poderoso', '12', '2', 1, 1, 350.00, 12.00, 300.00, 2, 10, '2025-02-18', '2025-02-18', '111122223333', '3', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `ofertas`
--

CREATE TABLE `ofertas` (
  `id` int(11) NOT NULL,
  `inventario_id` int(11) NOT NULL,
  `descuento` decimal(5,2) NOT NULL,
  `fecha_inicio` date NOT NULL,
  `fecha_fin` date NOT NULL,
  `estado` enum('Activa','Inactiva') NOT NULL DEFAULT 'Activa'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `ofertas`
--

INSERT INTO `ofertas` (`id`, `inventario_id`, `descuento`, `fecha_inicio`, `fecha_fin`, `estado`) VALUES
(1, 2, 1.00, '2025-02-19', '2025-02-20', 'Activa');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `proveedores`
--

CREATE TABLE `proveedores` (
  `id` int(11) NOT NULL,
  `nombre` varchar(150) NOT NULL,
  `direccion` text NOT NULL,
  `contacto` varchar(20) NOT NULL,
  `correo` varchar(100) NOT NULL,
  `clasificacion` varchar(50) DEFAULT NULL,
  `tipo_persona` enum('Natural','Jurídica') NOT NULL,
  `numero_factura_compra` varchar(50) DEFAULT NULL,
  `ley_tributaria` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `proveedores`
--

INSERT INTO `proveedores` (`id`, `nombre`, `direccion`, `contacto`, `correo`, `clasificacion`, `tipo_persona`, `numero_factura_compra`, `ley_tributaria`) VALUES
(1, 'Proveedor A', 'Calle 123, Ciudad A', '1234567890', 'proveedorA@example.com', 'Mayorista', 'Jurídica', '1234567890', 'Ley Tributaria 123'),
(2, 'Alvin Rosales H', 'col san sivar sv', '1313-1313', 'alvinedit@gmail.com', 'pequeña', 'Natural', '121212', 'contribuyente');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `sucursal`
--

CREATE TABLE `sucursal` (
  `id` int(11) NOT NULL,
  `codigo` varchar(50) NOT NULL,
  `nombre` varchar(50) NOT NULL,
  `pais` varchar(50) NOT NULL,
  `departamento` varchar(50) NOT NULL,
  `ciudad` varchar(50) NOT NULL,
  `estado` enum('Activo','Inactivo') NOT NULL DEFAULT 'Activo'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `sucursal`
--

INSERT INTO `sucursal` (`id`, `codigo`, `nombre`, `pais`, `departamento`, `ciudad`, `estado`) VALUES
(1, 'S001', 'Sucursal Principal', 'Colombia', 'Bogotá', 'Bogotá', 'Activo'),
(2, '3344', 'Sucursal poderosa', 'El Salvador', 'Ahuachapán', 'Apaneca', 'Activo');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `traslados`
--

CREATE TABLE `traslados` (
  `id` int(11) NOT NULL,
  `codigo_traslado` varchar(50) NOT NULL,
  `codigo_inventario` varchar(50) NOT NULL,
  `codigo_sucursal_origen` varchar(50) NOT NULL,
  `codigo_sucursal_destino` varchar(50) NOT NULL,
  `codigo_empleado` varchar(20) NOT NULL,
  `cantidad` int(11) NOT NULL,
  `fecha_traslado` datetime NOT NULL DEFAULT current_timestamp(),
  `estado` enum('Pendiente','Completado','Cancelado') NOT NULL DEFAULT 'Pendiente'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `traslados`
--

INSERT INTO `traslados` (`id`, `codigo_traslado`, `codigo_inventario`, `codigo_sucursal_origen`, `codigo_sucursal_destino`, `codigo_empleado`, `cantidad`, `fecha_traslado`, `estado`) VALUES
(1, 'T1', '1212', 'S001', 'S001', 'EMP-0002', 1, '2025-02-19 12:30:02', 'Pendiente');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuarios`
--

CREATE TABLE `usuarios` (
  `id` int(11) NOT NULL,
  `empleado_id` int(11) DEFAULT NULL,
  `nombre_completo` varchar(255) NOT NULL,
  `usuario` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL,
  `tipo_cuenta` varchar(50) NOT NULL,
  `cargo` varchar(50) NOT NULL,
  `fecha_creacion` datetime NOT NULL DEFAULT current_timestamp(),
  `fecha_actualizacion` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `usuarios`
--

INSERT INTO `usuarios` (`id`, `empleado_id`, `nombre_completo`, `usuario`, `password`, `tipo_cuenta`, `cargo`, `fecha_creacion`, `fecha_actualizacion`) VALUES
(1, NULL, 'Super Usuario', 'root', '123', 'Root', 'Administrador', '2025-02-21 14:35:00', '2025-02-21 14:35:44');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `ventas`
--

CREATE TABLE `ventas` (
  `idVentas` int(11) NOT NULL,
  `fecha_venta` datetime NOT NULL DEFAULT current_timestamp(),
  `cliente_id` int(11) DEFAULT NULL,
  `tipo_factura` enum('Consumidor Final','Crédito Fiscal','Ticket') NOT NULL,
  `metodo_pago` enum('Efectivo','Tarjeta de Crédito','Transferencia Bancaria') NOT NULL,
  `total` decimal(10,2) NOT NULL,
  `descripcion_compra` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `ventas`
--

INSERT INTO `ventas` (`idVentas`, `fecha_venta`, `cliente_id`, `tipo_factura`, `metodo_pago`, `total`, `descripcion_compra`) VALUES
(1, '2025-02-17 16:41:24', 1, 'Consumidor Final', 'Efectivo', 1200.00, 'Venta de motocicleta'),
(2, '2025-02-17 00:00:00', 1, 'Consumidor Final', 'Tarjeta de Crédito', 1342.44, 'ninguna'),
(3, '2025-02-18 10:29:38', 1, 'Consumidor Final', 'Efectivo', 1200.00, 'Venta de motocicleta'),
(4, '2025-02-18 00:00:00', 1, 'Ticket', 'Efectivo', 3691.71, 'ninguna'),
(5, '2025-02-19 00:00:00', 1, 'Crédito Fiscal', 'Efectivo', 335.61, 'ninguna nota'),
(6, '2025-02-19 00:00:00', 1, 'Ticket', 'Efectivo', 335.61, 'ninguna nota');

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `categoria`
--
ALTER TABLE `categoria`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `nombre` (`nombre`);

--
-- Indices de la tabla `clientes`
--
ALTER TABLE `clientes`
  ADD PRIMARY KEY (`idCliente`);

--
-- Indices de la tabla `detalle_ventas`
--
ALTER TABLE `detalle_ventas`
  ADD PRIMARY KEY (`idDetalle`),
  ADD KEY `idVentas` (`idVentas`),
  ADD KEY `codigo_producto` (`codigo_producto`);

--
-- Indices de la tabla `empleados`
--
ALTER TABLE `empleados`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `historial_ajustes`
--
ALTER TABLE `historial_ajustes`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `inventario`
--
ALTER TABLE `inventario`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `codigo` (`codigo`),
  ADD KEY `categoria_id` (`categoria_id`),
  ADD KEY `sucursal_id` (`sucursal_id`),
  ADD KEY `proveedor_id` (`proveedor_id`);

--
-- Indices de la tabla `ofertas`
--
ALTER TABLE `ofertas`
  ADD PRIMARY KEY (`id`),
  ADD KEY `inventario_id` (`inventario_id`);

--
-- Indices de la tabla `proveedores`
--
ALTER TABLE `proveedores`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `correo` (`correo`);

--
-- Indices de la tabla `sucursal`
--
ALTER TABLE `sucursal`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `codigo` (`codigo`);

--
-- Indices de la tabla `traslados`
--
ALTER TABLE `traslados`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `codigo_traslado` (`codigo_traslado`),
  ADD KEY `codigo_inventario` (`codigo_inventario`),
  ADD KEY `codigo_sucursal_origen` (`codigo_sucursal_origen`),
  ADD KEY `codigo_sucursal_destino` (`codigo_sucursal_destino`);

--
-- Indices de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_empleado_id` (`empleado_id`);

--
-- Indices de la tabla `ventas`
--
ALTER TABLE `ventas`
  ADD PRIMARY KEY (`idVentas`),
  ADD KEY `cliente_id` (`cliente_id`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `categoria`
--
ALTER TABLE `categoria`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `clientes`
--
ALTER TABLE `clientes`
  MODIFY `idCliente` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT de la tabla `detalle_ventas`
--
ALTER TABLE `detalle_ventas`
  MODIFY `idDetalle` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `empleados`
--
ALTER TABLE `empleados`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT de la tabla `historial_ajustes`
--
ALTER TABLE `historial_ajustes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `inventario`
--
ALTER TABLE `inventario`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `ofertas`
--
ALTER TABLE `ofertas`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `proveedores`
--
ALTER TABLE `proveedores`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `sucursal`
--
ALTER TABLE `sucursal`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `traslados`
--
ALTER TABLE `traslados`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT de la tabla `ventas`
--
ALTER TABLE `ventas`
  MODIFY `idVentas` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `detalle_ventas`
--
ALTER TABLE `detalle_ventas`
  ADD CONSTRAINT `detalle_ventas_ibfk_1` FOREIGN KEY (`idVentas`) REFERENCES `ventas` (`idVentas`),
  ADD CONSTRAINT `detalle_ventas_ibfk_2` FOREIGN KEY (`codigo_producto`) REFERENCES `inventario` (`codigo`);

--
-- Filtros para la tabla `inventario`
--
ALTER TABLE `inventario`
  ADD CONSTRAINT `inventario_ibfk_1` FOREIGN KEY (`categoria_id`) REFERENCES `categoria` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `inventario_ibfk_2` FOREIGN KEY (`sucursal_id`) REFERENCES `sucursal` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `inventario_ibfk_3` FOREIGN KEY (`proveedor_id`) REFERENCES `proveedores` (`id`) ON DELETE CASCADE;

--
-- Filtros para la tabla `ofertas`
--
ALTER TABLE `ofertas`
  ADD CONSTRAINT `ofertas_ibfk_1` FOREIGN KEY (`inventario_id`) REFERENCES `inventario` (`id`);

--
-- Filtros para la tabla `traslados`
--
ALTER TABLE `traslados`
  ADD CONSTRAINT `traslados_ibfk_1` FOREIGN KEY (`codigo_inventario`) REFERENCES `inventario` (`codigo`),
  ADD CONSTRAINT `traslados_ibfk_2` FOREIGN KEY (`codigo_sucursal_origen`) REFERENCES `sucursal` (`codigo`),
  ADD CONSTRAINT `traslados_ibfk_3` FOREIGN KEY (`codigo_sucursal_destino`) REFERENCES `sucursal` (`codigo`);

--
-- Filtros para la tabla `usuarios`
--
ALTER TABLE `usuarios`
  ADD CONSTRAINT `fk_empleado_id` FOREIGN KEY (`empleado_id`) REFERENCES `empleados` (`id`);

--
-- Filtros para la tabla `ventas`
--
ALTER TABLE `ventas`
  ADD CONSTRAINT `ventas_ibfk_1` FOREIGN KEY (`cliente_id`) REFERENCES `clientes` (`idCliente`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
