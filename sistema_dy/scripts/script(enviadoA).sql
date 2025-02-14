-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 10-02-2025 a las 02:18:23
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
-- Estructura de tabla para la tabla `inventario`
--

CREATE TABLE `inventario` (
  `id` int(11) NOT NULL,
  `codigo` varchar(50) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `descripcion` text DEFAULT NULL,
  `nro_motor` varchar(20) NOT NULL,
  `nro_chasis` varchar(20) NOT NULL,
  `categoria` varchar(50) DEFAULT NULL,
  `sucursal` varchar(50) DEFAULT NULL,
  `precio_compra` decimal(10,2) NOT NULL,
  `credito` decimal(10,2) DEFAULT 0.00,
  `precio_venta` decimal(10,2) NOT NULL,
  `stock_existencia` int(11) NOT NULL DEFAULT 0,
  `stock_minimo` int(11) NOT NULL DEFAULT 0,
  `fecha_ingreso` date NOT NULL,
  `fecha_reingreso` date DEFAULT NULL,
  `nro_poliza` varchar(50) DEFAULT NULL,
  `nro_lote` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `inventario`
--

INSERT INTO `inventario` (`id`, `codigo`, `nombre`, `descripcion`, `nro_motor`, `nro_chasis`, `categoria`, `sucursal`, `precio_compra`, `credito`, `precio_venta`, `stock_existencia`, `stock_minimo`, `fecha_ingreso`, `fecha_reingreso`, `nro_poliza`, `nro_lote`) VALUES
(5, 'ACE-002', 'Aceite Castrol 10W-20', 'Aceite sintético para motores 4T', '-', '-', 'Aceites', 'Sucursal Norte', 10.00, 0.00, 15.00, 50, 10, '2025-01-20', '2025-04-15', 'POL654321', 'LOT54321'),
(6, 'CAS-003', 'Casco LS2 Rapid', 'Casco integral, color negro mate', '', '', 'Cascos', 'Sucursal Sur', 80.00, 0.00, 120.00, 15, 3, '2025-01-10', '2025-03-25', 'POL789012', 'LOT67890'),
(7, 'GUA-004', 'Guantes Alpinestars', 'Guantes de protección para motociclista', '', '', 'Accesorios', 'Sucursal Centro', 25.00, 0.00, 40.00, 30, 5, '2025-02-05', '2025-06-01', 'POL111222', 'LOT333444');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `proveedores`
--

CREATE TABLE `proveedores` (
  `id` int(10) NOT NULL,
  `nombre` varchar(20) NOT NULL,
  `direccion` varchar(20) NOT NULL,
  `contacto` varchar(20) NOT NULL,
  `correo` varchar(20) NOT NULL,
  `clasificacion` varchar(20) NOT NULL,
  `tipo_persona` varchar(20) NOT NULL,
  `n_factura_compra` varchar(20) NOT NULL,
  `ley_tributaria` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuarios`
--

CREATE TABLE `usuarios` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `nombre_completo` varchar(255) NOT NULL,
  `usuario` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL,
  `rol` enum('Admin','Caja','Asesor de Venta') NOT NULL,
  `fecha_creacion` timestamp NOT NULL DEFAULT current_timestamp(),
  `fecha_actualizacion` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `usuarios`
--

INSERT INTO `usuarios` (`id`, `nombre_completo`, `usuario`, `password`, `rol`, `fecha_creacion`, `fecha_actualizacion`) VALUES
(6, 'Cristian Rodríguez', 'Crist', '$2a$10$sZ2ZYRQg93WW1BXFKAemzu65lIqhfRYdUbtJ7.Mp5CVckkaxPvwwy', 'Admin', '2025-02-05 21:16:37', '2025-02-05 21:16:37'),
(7, 'Grupo Ramos', 'admin', '$2a$10$4rgQQ3swKwYe4knm0w0P4.Ud/aZDniTf1xdogtn0b2DaXsVLRqpeC', 'Admin', '2025-02-05 21:30:52', '2025-02-05 21:30:52'),
(12, 'David', 'Dvid', '$2a$12$c5jA8qlabkmF5DBE4lr.xeHej9BAugk10v7uemwhuTBrCUeQy7I7W', 'Caja', '2025-02-08 17:56:10', '2025-02-08 17:56:10');

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `inventario`
--
ALTER TABLE `inventario`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `codigo` (`codigo`);

--
-- Indices de la tabla `proveedores`
--
ALTER TABLE `proveedores`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `usuario` (`usuario`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `inventario`
--
ALTER TABLE `inventario`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT de la tabla `proveedores`
--
ALTER TABLE `proveedores`
  MODIFY `id` int(10) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
