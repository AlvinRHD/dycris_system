const express = require('express');
const router = express.Router();

// --- Endpoints Temporales para Sucursales Manuales ---
// Estos endpoints se eliminarán cuando las sucursales estén registradas en Hacienda

// Asignar una venta a una sucursal manualmente
router.post('/ventas/sucursal-manual', async (req, res) => {
  const { venta_id, sucursal_nombre } = req.body;
  try {
    // Verificar si la venta ya tiene una sucursal asignada
    const [existing] = await req.db.query(
      'SELECT * FROM ventas_sucursales_manual WHERE venta_id = ?',
      [venta_id]
    );
    if (existing.length > 0) {
      return res.status(400).json({ message: 'Esta venta ya está asignada a una sucursal' });
    }

    // Verificar si la venta existe
    const [venta] = await req.db.query('SELECT * FROM ventas WHERE idVentas = ?', [venta_id]);
    if (venta.length === 0) {
      return res.status(404).json({ message: 'Venta no encontrada' });
    }

    // Insertar la asignación
    await req.db.query(
      'INSERT INTO ventas_sucursales_manual (venta_id, sucursal_nombre, fecha_asignacion) VALUES (?, ?, NOW())',
      [venta_id, sucursal_nombre]
    );
    res.status(201).json({ message: 'Sucursal asignada correctamente' });
  } catch (err) {
    console.error('Error al asignar sucursal manual:', err);
    res.status(500).json({ message: 'Error al asignar sucursal', error: err.message });
  }
});

// En server_movimientos_temporales.js
router.get('/ventas/sucursal-manual', async (req, res) => {
  try {
    const [rows] = await req.db.query(
      'SELECT vsm.id, vsm.venta_id, vsm.sucursal_nombre, vsm.fecha_asignacion, ' +
      'v.codigo_venta, v.empleado_id, CONCAT(e.nombres, " ", e.apellidos) AS empleado_nombre, ' +
      'v.total, v.descuento ' + // Agregamos v.descuento explícitamente
      'FROM ventas_sucursales_manual vsm ' +
      'LEFT JOIN ventas v ON vsm.venta_id = v.idVentas ' +
      'LEFT JOIN empleados e ON v.empleado_id = e.id ' +
      'ORDER BY vsm.fecha_asignacion DESC'
    );

    // Para cada venta, obtener los productos
    for (let row of rows) {
      const [productos] = await req.db.query(
        'SELECT codigo_producto, nombre, cantidad, precio_unitario, subtotal ' +
        'FROM detalle_ventas WHERE idVentas = ?',
        [row.venta_id]
      );
      row.productos = productos;
    }

    res.json(rows);
  } catch (err) {
    console.error('Error al obtener asignaciones manuales:', err);
    res.status(500).json({ message: 'Error al obtener asignaciones', error: err.message });
  }
});

// Exportar el router
module.exports = router;