const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');




// Función reutilizable para generar códigos automáticos
async function generateCode(db, prefix, table, column) {
  const [result] = await db.query(
    `SELECT MAX(CAST(SUBSTRING_INDEX(${column}, '-', -1) AS UNSIGNED)) AS ultimoNumero 
     FROM ${table} WHERE ${column} LIKE '${prefix}-%'`
  );
  const ultimoNumero = result[0].ultimoNumero || 0;
  const proximoNumero = ultimoNumero + 1;
  return `${prefix}-${proximoNumero.toString().padStart(5, '0')}`;
}

///////////////////////////// MOVIMIENTOS //////////////////////////

// ------------------ VENTAS ------------------

// POST /ventas/autorizar-descuento - Autorizar descuento
router.post('/ventas/autorizar-descuento', async (req, res) => {
  try {
    const { codigo } = req.body;
    const [codigos] = await req.db.query('SELECT codigo FROM codigos_autorizacion');
    let autorizado = false;
    for (const row of codigos) {
      if (await bcrypt.compare(codigo, row.codigo)) {
        autorizado = true;
        break;
      }
    }
    res.json({ autorizado });
  } catch (err) {
    console.error('Error al verificar código:', err);
    res.status(500).json({ message: 'Error al verificar código', error: err.message });
  }
});

// POST /ventas - Agregar una nueva venta
router.post('/ventas', async (req, res) => {
  try {
    const {
      cliente_id = 1, // Cliente de Paso por defecto
      empleado_id,
      tipo_dte = 'Factura', // Valor por defecto
      metodo_pago,
      total,
      descripcion_compra,
      productos,
      apertura_id,
      descuento,
      codigo_autorizacion
    } = req.body;

    // Validar apertura activa
    const [apertura] = await req.db.query(
      'SELECT id FROM aperturas_caja WHERE id = ? AND NOT EXISTS (SELECT 1 FROM cierres_caja WHERE apertura_id = ?)',
      [apertura_id, apertura_id]
    );
    if (!apertura.length) {
      return res.status(400).json({ message: 'No hay una apertura de caja activa para esta venta' });
    }

    const finalCodigoVenta = await generateCode(req.db, 'VGR', 'ventas', 'codigo_venta');

    if (!empleado_id) return res.status(400).json({ message: 'El ID del empleado es requerido' });

    const [empleado] = await req.db.query(
      `SELECT e.id, u.tipo_cuenta 
       FROM empleados e 
       LEFT JOIN usuarios u ON e.id = u.empleado_id 
       WHERE e.id = ?`,
      [empleado_id]
    );
    if (empleado.length === 0) return res.status(400).json({ message: 'Empleado no encontrado' });

    for (const producto of productos) {
      const [inventario] = await req.db.query('SELECT stock_existencia FROM inventario WHERE codigo = ?', [producto.codigo_producto]);
      if (inventario.length === 0) return res.status(404).json({ message: `Producto ${producto.codigo_producto} no encontrado` });
      if (inventario[0].stock_existencia < producto.cantidad) {
        return res.status(400).json({ message: `Stock insuficiente para el producto ${producto.codigo_producto}` });
      }
    }

    const descuentoValue = parseFloat(descuento) || 0.0;
    if (descuentoValue > 0) {
      const tipoCuenta = empleado[0].tipo_cuenta;
      if (tipoCuenta !== 'Admin' && tipoCuenta !== 'Root') {
        if (!codigo_autorizacion) {
          return res.status(403).json({ message: 'Se requiere autorización para aplicar descuento' });
        }
        const [codigos] = await req.db.query('SELECT codigo FROM codigos_autorizacion');
        let autorizado = false;
        for (const row of codigos) {
          if (await bcrypt.compare(codigo_autorizacion, row.codigo)) {
            autorizado = true;
            break;
          }
        }
        if (!autorizado) {
          return res.status(403).json({ message: 'Código de autorización inválido' });
        }
      }
    }

    const [ventaResult] = await req.db.query(
      `INSERT INTO ventas (
        codigo_venta, cliente_id, empleado_id, tipo_dte, metodo_pago, total, 
        descripcion_compra, descuento, apertura_id, sucursal_id
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        finalCodigoVenta, cliente_id, empleado_id, tipo_dte, metodo_pago, total,
        descripcion_compra || null, descuento || 0.0, apertura_id, 4 // Sucursal por defecto
      ]
    );

    const ventaId = ventaResult.insertId;

    for (const producto of productos) {
      await req.db.query(
        `INSERT INTO detalle_ventas (idVentas, codigo_producto, nombre, cantidad, precio_unitario, subtotal)
         VALUES (?, ?, ?, ?, ?, ?)`,
        [ventaId, producto.codigo_producto, producto.nombre, producto.cantidad, producto.precio_unitario, producto.subtotal]
      );
      await req.db.query(
        'UPDATE inventario SET stock_existencia = stock_existencia - ? WHERE codigo = ?',
        [producto.cantidad, producto.codigo_producto]
      );
    }

    res.status(201).json({ message: 'Venta agregada correctamente', ventaId, codigo_venta: finalCodigoVenta });
  } catch (err) {
    console.error('Error al agregar la venta:', err);
    res.status(500).json({ message: 'Error al agregar la venta', error: err.message });
  }
});


// GET /ventas - Obtener todas las ventas con paginación
router.get('/ventas', async (req, res) => {
  try {
    const { page = 1, limit = 10, apertura_id } = req.query;
    const offset = (page - 1) * limit;

    let query = `
      SELECT v.idVentas, v.codigo_venta, v.cliente_id, v.empleado_id, v.tipo_dte, v.metodo_pago, 
             v.total, v.descripcion_compra, v.descuento, v.apertura_id, v.sucursal_id,
             c.nombre AS cliente_nombre, c.direccion AS direccion_cliente, c.dui, c.nit,
             CONCAT(e.nombres, ' ', e.apellidos) AS empleado_nombre,
             s.nombre AS sucursal_nombre,
             v.fecha_venta AS fecha_venta,
             JSON_ARRAYAGG(
               JSON_OBJECT(
                 'id', dv.idDetalle, 'codigo', dv.codigo_producto, 'nombre', dv.nombre, 
                 'cantidad', dv.cantidad, 'precio', dv.precio_unitario, 'subtotal', dv.subtotal
               )
             ) AS productos
      FROM ventas v
      LEFT JOIN clientes c ON v.cliente_id = c.idCliente
      LEFT JOIN empleados e ON v.empleado_id = e.id
      LEFT JOIN sucursal s ON v.sucursal_id = s.id
      LEFT JOIN detalle_ventas dv ON v.idVentas = dv.idVentas
    `;
    let countQuery = 'SELECT COUNT(*) as total FROM ventas v';
    let params = [];

    if (apertura_id) {
      query += ' WHERE v.apertura_id = ?';
      countQuery += ' WHERE v.apertura_id = ?';
      params.push(apertura_id);
    }

    query += `
      GROUP BY v.idVentas, v.codigo_venta, v.cliente_id, v.empleado_id, v.tipo_dte, v.metodo_pago, 
               v.total, v.descripcion_compra, v.descuento, v.apertura_id, v.sucursal_id,
               c.nombre, c.direccion, c.dui, c.nit, e.nombres, e.apellidos, s.nombre,
               v.fecha_venta
      ORDER BY v.fecha_venta DESC
      LIMIT ? OFFSET ?
    `;
    params.push(parseInt(limit), parseInt(offset));

    const [ventas] = await req.db.query(query, params);
    const [countResult] = await req.db.query(countQuery, apertura_id ? [apertura_id] : []);
    const total = countResult[0].total;

    res.json({ ventas, total });
  } catch (err) {
    console.error('Error al obtener ventas:', err);
    res.status(500).json({ message: 'Error al obtener ventas', error: err.message });
  }
});

// PUT /ventas/:id - Actualizar una venta
router.put('/ventas/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { metodo_pago, descripcion_compra } = req.body;

    const [ventaActual] = await req.db.query('SELECT * FROM ventas WHERE idVentas = ?', [id]);
    if (ventaActual.length === 0) return res.status(404).json({ message: 'Venta no encontrada' });

    const datosActualizados = {
      metodo_pago: metodo_pago || ventaActual[0].metodo_pago,
      descripcion_compra: descripcion_compra || ventaActual[0].descripcion_compra
    };

    await req.db.query(
      `UPDATE ventas SET 
         metodo_pago = ?, descripcion_compra = ?
       WHERE idVentas = ?`,
      [datosActualizados.metodo_pago, datosActualizados.descripcion_compra, id]
    );

    const datosNuevos = { ...datosActualizados };
    await req.db.query(
      `INSERT INTO historial_cambios_ventas (venta_id, datos_anteriores, datos_nuevos)
       VALUES (?, ?, ?)`,
      [id, JSON.stringify(ventaActual[0]), JSON.stringify(datosNuevos)]
    );

    res.json({ message: 'Venta actualizada correctamente' });
  } catch (err) {
    console.error('Error al actualizar venta:', err);
    res.status(500).json({ message: 'Error al actualizar venta', error: err.message });
  }
});

// GET /ventas/:id/historial - Obtener historial de cambios
router.get('/ventas/:id/historial', async (req, res) => {
  try {
    const { id } = req.params;
    const [historial] = await req.db.query(
      'SELECT * FROM historial_cambios_ventas WHERE venta_id = ? ORDER BY fecha_cambio DESC',
      [id]
    );
    res.json(historial);
  } catch (err) {
    console.error('Error al obtener historial:', err);
    res.status(500).json({ message: 'Error al obtener historial', error: err.message });
  }
});

// DELETE /ventas/:id - Eliminar una venta
router.delete('/ventas/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const [venta] = await req.db.query('SELECT * FROM ventas WHERE idVentas = ?', [id]);
    if (venta.length === 0) return res.status(404).json({ message: 'Venta no encontrada' });

    const [detalles] = await req.db.query('SELECT * FROM detalle_ventas WHERE idVentas = ?', [id]);
    for (const detalle of detalles) {
      await req.db.query(
        'UPDATE inventario SET stock_existencia = stock_existencia + ? WHERE codigo = ?',
        [detalle.cantidad, detalle.codigo_producto]
      );
    }

    await req.db.query('DELETE FROM detalle_ventas WHERE idVentas = ?', [id]);
    await req.db.query('DELETE FROM ventas WHERE idVentas = ?', [id]);

    res.json({ message: 'Venta eliminada correctamente' });
  } catch (err) {
    console.error('Error al eliminar venta:', err);
    res.status(500).json({ message: 'Error al eliminar venta', error: err.message });
  }
});



// ------------------ CLIENTES ------------------

router.get("/clientes", async (req, res) => {
  const { page = 1, limit = 10, q } = req.query;
  const offset = (page - 1) * limit;
  try {
    let query = "SELECT * FROM clientes WHERE 1=1";
    const params = [];
    if (q) {
      query += " AND (nombre LIKE ? OR nit LIKE ? OR dui LIKE ?)";
      params.push(`%${q}%`, `%${q}%`, `%${q}%`);
    }
    query += " ORDER BY idCliente DESC LIMIT ? OFFSET ?";
    params.push(parseInt(limit), parseInt(offset));

    const [rows] = await req.db.query(query, params);
    const [totalResult] = await req.db.query(
      "SELECT COUNT(*) AS total FROM clientes" + (q ? " WHERE nombre LIKE ? OR nit LIKE ? OR dui LIKE ?" : ""),
      q ? [`%${q}%`, `%${q}%`, `%${q}%`] : []
    );
    res.json({ clientes: rows, total: totalResult[0].total, page: parseInt(page), limit: parseInt(limit) });
  } catch (err) {
    console.error("Error al obtener clientes:", err);
    res.status(500).json({ message: "Error al obtener clientes", error: err.message });
  }
});

router.post("/clientes", async (req, res) => {
  try {
    const {
      nombre, direccion, departamento, dui, nit, tipo_cliente, registro_contribuyente,
      representante_legal, direccion_representante, razon_social, email,
      telefono, fecha_inicio,
    } = req.body;

    if (!nombre) {
      return res.status(400).json({ message: "El campo nombre es requerido" });
    }

    const codigoCliente = await generateCode(req.db, 'CGR', 'clientes', 'codigo_cliente');

    const [result] = await req.db.query(
      `INSERT INTO clientes (
        codigo_cliente, nombre, direccion, departamento, dui, nit, tipo_cliente, 
        registro_contribuyente, representante_legal, direccion_representante, 
        razon_social, email, telefono, fecha_inicio
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        codigoCliente, nombre, direccion || null, departamento || null, dui || null, nit || null, 
        tipo_cliente || 'Cliente de Paso', registro_contribuyente || null, representante_legal || null, 
        direccion_representante || null, razon_social || null, email || null, telefono || null, 
        fecha_inicio || new Date().toISOString().split('T')[0]
      ]
    );

    res.status(201).json({
      message: "Cliente agregado correctamente",
      idCliente: result.insertId,
      codigo_cliente: codigoCliente,
      nombre: nombre, // Agregar nombre
      tipo_cliente: tipo_cliente || 'Cliente de Paso', // Agregar tipo_cliente
      fecha_inicio: fecha_inicio || new Date().toISOString().split('T')[0], // Agregar fecha_inicio
    });
  } catch (err) {
    console.error("Error al agregar cliente:", err);
    res.status(500).json({ message: "Error al agregar cliente", error: err.message });
  }
});

router.put("/clientes/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { 
      nombre, direccion, departamento, dui, nit, registro_contribuyente,
      representante_legal, direccion_representante, razon_social, email,
      telefono, fecha_inicio
    } = req.body;

    const [clienteActual] = await req.db.query("SELECT * FROM clientes WHERE idCliente = ?", [id]);
    if (clienteActual.length === 0) return res.status(404).json({ message: "Cliente no encontrado" });

    const datosActualizados = {
      nombre: nombre || clienteActual[0].nombre,
      direccion: direccion || clienteActual[0].direccion,
      departamento: departamento || clienteActual[0].departamento,
      dui: dui || clienteActual[0].dui,
      nit: nit || clienteActual[0].nit,
      registro_contribuyente: registro_contribuyente || clienteActual[0].registro_contribuyente,
      representante_legal: representante_legal || clienteActual[0].representante_legal,
      direccion_representante: direccion_representante || clienteActual[0].direccion_representante,
      razon_social: razon_social || clienteActual[0].razon_social,
      email: email || clienteActual[0].email,
      telefono: telefono || clienteActual[0].telefono,
      fecha_inicio: fecha_inicio || clienteActual[0].fecha_inicio,
    };

    await req.db.query(
      `UPDATE clientes SET 
         nombre = ?, direccion = ?, departamento = ?, dui = ?, nit = ?, 
         registro_contribuyente = ?, representante_legal = ?, direccion_representante = ?, 
         razon_social = ?, email = ?, telefono = ?, fecha_inicio = ?
       WHERE idCliente = ?`,
      [
        datosActualizados.nombre, datosActualizados.direccion, datosActualizados.departamento,
        datosActualizados.dui, datosActualizados.nit, datosActualizados.registro_contribuyente,
        datosActualizados.representante_legal, datosActualizados.direccion_representante,
        datosActualizados.razon_social, datosActualizados.email, datosActualizados.telefono,
        datosActualizados.fecha_inicio, id
      ]
    );

    const datosNuevos = { ...datosActualizados };
    await req.db.query(
      `INSERT INTO historial_cambios_clientes (cliente_id, datos_anteriores, datos_nuevos)
       VALUES (?, ?, ?)`,
      [id, JSON.stringify(clienteActual[0]), JSON.stringify(datosNuevos)]
    );

    res.json({ message: "Cliente actualizado correctamente" });
  } catch (err) {
    console.error("Error al actualizar cliente:", err);
    res.status(500).json({ message: "Error al actualizar cliente", error: err.message });
  }
});

router.get("/clientes/:id/historial", async (req, res) => {
  try {
    const { id } = req.params;
    const [historial] = await req.db.query(
      `SELECT id, cliente_id, fecha_cambio, datos_anteriores, datos_nuevos
       FROM historial_cambios_clientes WHERE cliente_id = ? ORDER BY fecha_cambio DESC`,
      [id]
    );
    res.json(historial);
  } catch (err) {
    console.error("Error al obtener historial:", err);
    res.status(500).json({ message: "Error al obtener historial", error: err.message });
  }
});

router.delete("/clientes/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const [result] = await req.db.query("DELETE FROM clientes WHERE idCliente = ?", [id]);
    if (result.affectedRows === 0) return res.status(404).json({ message: "Cliente no encontrado" });
    res.json({ message: "Cliente eliminado correctamente" });
  } catch (err) {
    console.error("Error al eliminar cliente:", err);
    res.status(500).json({ message: "Error al eliminar cliente", error: err.message });
  }
});

// POST /clientes/paso - Agregar Cliente de Paso
router.post('/clientes/paso', async (req, res) => {
  try {
    const { nombre, fecha_inicio } = req.body;
    if (!nombre) return res.status(400).json({ message: 'El nombre es requerido' });

    const [result] = await req.db.query(
      'INSERT INTO clientes (nombre, tipo_cliente, fecha_inicio) VALUES (?, "Cliente de Paso", ?)',
      [nombre, fecha_inicio || new Date().toISOString().split('T')[0]] // Fecha actual por defecto
    );
    res.status(201).json({ idCliente: result.insertId, nombre, fecha_inicio: fecha_inicio || new Date().toISOString().split('T')[0] });
  } catch (err) {
    console.error('Error al agregar cliente de paso:', err);
    res.status(500).json({ message: 'Error al agregar cliente de paso', error: err.message });
  }
});

// ------------------ TRASLADOS ------------------

// Ajustar GET /traslados para incluir detalles
router.get("/traslados", async (req, res) => {
  try {
    const { search, codigo_sucursal_origen, page = 1, limit = 10 } = req.query;
    const offset = (page - 1) * limit;
    let query = `
      SELECT 
        t.id, t.codigo_traslado, t.fecha_traslado, t.estado,
        s1.codigo AS codigo_sucursal_origen, s1.nombre AS sucursal_origen,
        s2.codigo AS codigo_sucursal_destino, s2.nombre AS sucursal_destino,
        e.codigo_empleado, CONCAT(e.nombres, ' ', e.apellidos) AS empleado,
        JSON_ARRAYAGG(
          JSON_OBJECT(
            'codigo_inventario', dt.codigo_inventario,
            'cantidad', dt.cantidad,
            'producto_nombre', i.nombre,
            'numero_motor', i.numero_motor,
            'numero_chasis', i.numero_chasis,
            'descripcion', i.descripcion
          )
        ) AS productos
      FROM traslados t
      INNER JOIN sucursal s1 ON t.codigo_sucursal_origen = s1.codigo
      INNER JOIN sucursal s2 ON t.codigo_sucursal_destino = s2.codigo
      LEFT JOIN empleados e ON t.codigo_empleado = e.codigo_empleado
      LEFT JOIN detalle_traslados dt ON t.id = dt.traslado_id
      LEFT JOIN inventario i ON dt.codigo_inventario = i.codigo
      WHERE 1=1
    `;
    const params = [];

    if (search) {
      query += " AND (t.codigo_traslado LIKE ? OR i.nombre LIKE ? OR i.numero_motor LIKE ? OR i.numero_chasis LIKE ?)";
      params.push(`%${search}%`, `%${search}%`, `%${search}%`, `%${search}%`);
    }
    if (codigo_sucursal_origen) {
      query += " AND t.codigo_sucursal_origen = ?";
      params.push(codigo_sucursal_origen);
    }

    query += `
      GROUP BY t.id, t.codigo_traslado, t.fecha_traslado, t.estado,
               s1.codigo, s1.nombre, s2.codigo, s2.nombre,
               e.codigo_empleado, e.nombres, e.apellidos
      ORDER BY t.fecha_traslado DESC
      LIMIT ? OFFSET ?
    `;
    params.push(parseInt(limit), parseInt(offset));

    const [rows] = await req.db.query(query, params);
    const [totalResult] = await req.db.query(
      'SELECT COUNT(DISTINCT t.id) AS total FROM traslados t ' +
      'LEFT JOIN detalle_traslados dt ON t.id = dt.traslado_id ' +
      'LEFT JOIN inventario i ON dt.codigo_inventario = i.codigo ' +
      'WHERE 1=1' +
      (search ? " AND (t.codigo_traslado LIKE ? OR i.nombre LIKE ? OR i.numero_motor LIKE ? OR i.numero_chasis LIKE ?)" : "") +
      (codigo_sucursal_origen ? " AND t.codigo_sucursal_origen = ?" : ""),
      search && codigo_sucursal_origen ? [`%${search}%`, `%${search}%`, `%${search}%`, `%${search}%`, codigo_sucursal_origen] :
      search ? [`%${search}%`, `%${search}%`, `%${search}%`, `%${search}%`] : codigo_sucursal_origen ? [codigo_sucursal_origen] : []
    );
    const total = totalResult[0].total;

    res.json({ traslados: rows, total });
  } catch (err) {
    console.error("Error al obtener los traslados:", err);
    res.status(500).json({ message: "Error al obtener los traslados", error: err.message });
  }
});

router.get("/traslados/sucursales", async (req, res) => {
  try {
    const [rows] = await req.db.query(
      "SELECT codigo, nombre FROM sucursal WHERE estado = 'Activo'"
    );
    res.json(rows);
  } catch (err) {
    console.error("Error al obtener sucursales:", err);
    res.status(500).json({ message: "Error al obtener sucursales", error: err.message });
  }
});

router.post("/traslados", async (req, res) => {
  try {
    const { productos, codigo_sucursal_origen, codigo_sucursal_destino, codigo_empleado, fecha_traslado, estado } = req.body;
    const codigoTraslado = await generateCode(req.db, 'TGR', 'traslados', 'codigo_traslado');

    // Convertir el ID numérico a codigo_empleado si es necesario
    let finalCodigoEmpleado = codigo_empleado;
    if (/^\d+$/.test(codigo_empleado)) { // Si es un número (ID)
      const [empleado] = await req.db.query(
        "SELECT codigo_empleado FROM empleados WHERE id = ?",
        [codigo_empleado]
      );
      if (empleado.length === 0) {
        return res.status(400).json({ message: "Empleado no encontrado con ese ID" });
      }
      finalCodigoEmpleado = empleado[0].codigo_empleado;
    }

    // Insertar el traslado principal
    const [trasladoResult] = await req.db.query(
      `INSERT INTO traslados (
        codigo_traslado, codigo_sucursal_origen, codigo_sucursal_destino, 
        codigo_empleado, fecha_traslado, estado
      ) VALUES (?, ?, ?, ?, ?, ?)`,
      [codigoTraslado, codigo_sucursal_origen, codigo_sucursal_destino, finalCodigoEmpleado || null, fecha_traslado, estado]
    );

    const trasladoId = trasladoResult.insertId;

    // Insertar detalles de los productos
    for (const producto of productos) {
      const { codigo, cantidad } = producto;
      await req.db.query(
        `INSERT INTO detalle_traslados (traslado_id, codigo_inventario, cantidad)
         VALUES (?, ?, ?)`,
        [trasladoId, codigo, cantidad]
      );
    }

    res.status(201).json({ message: "Traslado agregado", codigo_traslado: codigoTraslado });
  } catch (err) {
    console.error("Error al agregar traslado:", err);
    res.status(500).json({ message: "Error al agregar traslado", error: err.message });
  }
});

router.put("/traslados/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { estado, productos } = req.body;

    // Obtener traslado actual con detalles
    const [trasladoActual] = await req.db.query(
      "SELECT t.*, JSON_ARRAYAGG(JSON_OBJECT('codigo_inventario', dt.codigo_inventario, 'cantidad', dt.cantidad)) AS productos " +
      "FROM traslados t LEFT JOIN detalle_traslados dt ON t.id = dt.traslado_id WHERE t.id = ? GROUP BY t.id",
      [id]
    );
    if (trasladoActual.length === 0) return res.status(404).json({ message: "Traslado no encontrado" });

    // Usar productos directamente como objeto, sin JSON.parse
    const productosActuales = trasladoActual[0].productos || [];

    // Actualizar estado si cambió
    if (estado && estado !== trasladoActual[0].estado) {
      await req.db.query(
        "UPDATE traslados SET estado = ? WHERE id = ?",
        [estado, id]
      );
    }

    // Actualizar cantidades si hay cambios
    const cambiosProductos = [];
    if (productos && productos.length > 0) {
      for (const producto of productos) {
        const { codigo_inventario, cantidad } = producto;
        const productoActual = productosActuales.find(p => p.codigo_inventario === codigo_inventario);
        if (productoActual && cantidad !== productoActual.cantidad) {
          await req.db.query(
            "UPDATE detalle_traslados SET cantidad = ? WHERE traslado_id = ? AND codigo_inventario = ?",
            [cantidad, id, codigo_inventario]
          );
          cambiosProductos.push({ 
            codigo_inventario, 
            cantidadAntes: productoActual.cantidad, 
            cantidadDespues: cantidad 
          });
        }
      }
    }

    // Registrar historial solo si hay cambios
    const datosNuevos = {};
    const datosAnteriores = {
      estado: trasladoActual[0].estado,
      productos: productosActuales
    };
    if (estado && estado !== trasladoActual[0].estado) {
      datosNuevos.estado = estado;
    }
    if (cambiosProductos.length > 0) {
      datosNuevos.productos = cambiosProductos;
    }

    if (Object.keys(datosNuevos).length > 0) {
      await req.db.query(
        `INSERT INTO historial_cambios_traslados (traslado_id, codigo_traslado, datos_anteriores, datos_nuevos, fecha_cambio)
         VALUES (?, ?, ?, ?, NOW())`,
        [id, trasladoActual[0].codigo_traslado, JSON.stringify(datosAnteriores), JSON.stringify(datosNuevos)]
      );
    }

    res.json({ message: "Traslado actualizado correctamente" });
  } catch (err) {
    console.error("Error al actualizar traslado:", err);
    res.status(500).json({ message: "Error al actualizar traslado", error: err.message });
  }
});

router.get("/traslados/:id/historial", async (req, res) => {
  try {
    const { id } = req.params;
    const [historial] = await req.db.query(
      `SELECT id, traslado_id, codigo_traslado, datos_anteriores, datos_nuevos, fecha_cambio
       FROM historial_cambios_traslados WHERE traslado_id = ? ORDER BY fecha_cambio DESC`,
      [id]
    );
    res.json(historial);
  } catch (err) {
    console.error("Error al obtener historial:", err);
    res.status(500).json({ message: "Error al obtener historial", error: err.message });
  }
});

router.delete("/traslados/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const [result] = await req.db.query("DELETE FROM traslados WHERE id = ?", [id]);
    if (result.affectedRows === 0) return res.status(404).json({ message: "Traslado no encontrado" });
    res.json({ message: "Traslado eliminado correctamente" });
  } catch (err) {
    console.error("Error al eliminar traslado:", err);
    res.status(500).json({ message: "Error al eliminar traslado", error: err.message });
  }
});

// ------------------ OFERTAS ------------------

router.get("/ofertas", async (req, res) => {
  try {
    const { categoria_id, nombre, estado, page = 1, limit = 10 } = req.query;
    const offset = (page - 1) * limit;
    let query = `
      SELECT 
        o.id, o.inventario_id, o.descuento, o.fecha_inicio, o.fecha_fin, o.codigo_oferta,
        i.codigo AS codigo, i.nombre AS producto_nombre, i.precio_venta,
        i.precio_venta * (1 - o.descuento / 100) AS precio_con_descuento,
        i.categoria AS categoria,  -- Cambiado de i.categoria_id a i.categoria
        CASE 
          WHEN o.fecha_fin < NOW() THEN 'Inactiva'
          WHEN o.fecha_inicio <= NOW() AND o.fecha_fin >= NOW() THEN 'Activa'
          ELSE 'Pendiente'
        END AS estado
      FROM ofertas o
      INNER JOIN inventario i ON o.inventario_id = i.id
      WHERE 1=1
    `;
    const params = [];

    // Ajustar el filtro por categoría
    if (categoria_id) {
      query += " AND i.categoria = ?";  // Cambiado de i.categoria_id a i.categoria
      params.push(categoria_id);  // Ahora espera un valor de texto (nombre de categoría)
    }
    if (nombre) {
      query += " AND i.nombre LIKE ?";
      params.push(`%${nombre}%`);
    }
    if (estado && estado !== 'Todas') {
      query += " AND CASE WHEN o.fecha_fin < NOW() THEN 'Inactiva' WHEN o.fecha_inicio <= NOW() AND o.fecha_fin >= NOW() THEN 'Activa' ELSE 'Pendiente' END = ?";
      params.push(estado);
    }

    query += " LIMIT ? OFFSET ?";
    params.push(parseInt(limit), parseInt(offset));

    const [rows] = await req.db.query(query, params);
    const [totalResult] = await req.db.query(
      'SELECT COUNT(*) AS total FROM ofertas o INNER JOIN inventario i ON o.inventario_id = i.id WHERE 1=1' + 
      (categoria_id ? " AND i.categoria = ?" : "") +  // Ajustado aquí también
      (nombre ? " AND i.nombre LIKE ?" : ""), 
      categoria_id && nombre ? [categoria_id, `%${nombre}%`] : categoria_id ? [categoria_id] : nombre ? [`%${nombre}%`] : []
    );
    const total = totalResult[0].total;

    res.json({ ofertas: rows, total });
  } catch (err) {
    console.error("Error al obtener las ofertas:", err);
    res.status(500).json({ message: "Error al obtener las ofertas", error: err.message });
  }
});


router.post("/ofertas", async (req, res) => {
  try {
    const { inventario_id, descuento, fecha_inicio, fecha_fin } = req.body;
    const codigoOferta = await generateCode(req.db, 'OGR', 'ofertas', 'codigo_oferta');

    const [result] = await req.db.query(
      `INSERT INTO ofertas (inventario_id, descuento, fecha_inicio, fecha_fin, codigo_oferta)
       VALUES (?, ?, ?, ?, ?)`,
      [inventario_id, descuento, fecha_inicio, fecha_fin, codigoOferta]
    );

    res.status(201).json({ message: "Oferta agregada correctamente", id: result.insertId, codigo_oferta: codigoOferta });
  } catch (err) {
    console.error("Error al agregar la oferta:", err);
    res.status(500).json({ message: "Error al agregar la oferta", error: err.message });
  }
});

router.put("/ofertas/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { inventario_id, descuento, fecha_inicio, fecha_fin } = req.body;

    const [ofertaActual] = await req.db.query("SELECT * FROM ofertas WHERE id = ?", [id]);
    if (ofertaActual.length === 0) return res.status(404).json({ message: "Oferta no encontrada" });

    const datosNuevos = {
      inventario_id: inventario_id || ofertaActual[0].inventario_id,
      descuento: descuento || ofertaActual[0].descuento,
      fecha_inicio: fecha_inicio || ofertaActual[0].fecha_inicio,
      fecha_fin: fecha_fin || ofertaActual[0].fecha_fin,
    };

    const [result] = await req.db.query(
      `UPDATE ofertas 
       SET inventario_id = ?, descuento = ?, fecha_inicio = ?, fecha_fin = ?
       WHERE id = ?`,
      [datosNuevos.inventario_id, datosNuevos.descuento, datosNuevos.fecha_inicio, datosNuevos.fecha_fin, id]
    );

    if (result.affectedRows === 0) return res.status(404).json({ message: "Oferta no encontrada" });

    // Guardar historial de cambios
    await req.db.query(
      `INSERT INTO historial_cambios_ofertas (oferta_id, codigo_oferta, datos_anteriores, datos_nuevos, fecha_cambio)
       VALUES (?, ?, ?, ?, NOW())`,
      [id, ofertaActual[0].codigo_oferta, JSON.stringify(ofertaActual[0]), JSON.stringify(datosNuevos)]
    );

    res.json({ message: "Oferta actualizada correctamente" });
  } catch (err) {
    console.error("Error al actualizar la oferta:", err);
    res.status(500).json({ message: "Error al actualizar la oferta", error: err.message });
  }
});

router.get("/ofertas/:id/historial", async (req, res) => {
  try {
    const { id } = req.params;
    const [historial] = await req.db.query(
      `SELECT id, oferta_id, codigo_oferta, datos_anteriores, datos_nuevos, fecha_cambio
       FROM historial_cambios_ofertas WHERE oferta_id = ? ORDER BY fecha_cambio DESC`,
      [id]
    );
    res.json(historial);
  } catch (err) {
    console.error("Error al obtener historial:", err);
    res.status(500).json({ message: "Error al obtener historial", error: err.message });
  }
});

router.delete("/ofertas/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const [result] = await req.db.query("DELETE FROM ofertas WHERE id = ?", [id]);
    if (result.affectedRows === 0) return res.status(404).json({ message: "Oferta no encontrada" });
    res.json({ message: "Oferta eliminada correctamente" });
  } catch (err) {
    console.error("Error al eliminar la oferta:", err);
    res.status(500).json({ message: "Error al eliminar la oferta", error: err.message });
  }
});



// ------------------ CAJAS ------------------
// Agregar endpoints para cajas y aperturas
router.get('/cajas', async (req, res) => {
  try {
    const [rows] = await req.db.query(
      'SELECT c.id, c.numero_caja, c.sucursal_id, s.nombre AS sucursal_nombre ' +
      'FROM cajas c LEFT JOIN sucursal s ON c.sucursal_id = s.id WHERE c.estado = "Abierta"'
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: 'Error al obtener cajas', error: err.message });
  }
});

router.get('/cajas/todas', async (req, res) => {
  try {
    const [rows] = await req.db.query(
      'SELECT c.id, c.numero_caja, c.sucursal_id, s.nombre AS sucursal_nombre, s.codigo AS sucursal_codigo, c.estado ' +
      'FROM cajas c LEFT JOIN sucursal s ON c.sucursal_id = s.id ' +
      'ORDER BY c.sucursal_id, c.numero_caja'
    );
    res.json(rows);
  } catch (err) {
    console.error('Error al obtener todas las cajas:', err);
    res.status(500).json({ message: 'Error al obtener cajas', error: err.message });
  }
});

router.post('/cajas', async (req, res) => {
  const { numero_caja, sucursal_id, estado } = req.body;
  try {
    const [sucursal] = await req.db.query("SELECT id FROM sucursal WHERE codigo = ?", [sucursal_id]);
    if (!sucursal.length) return res.status(404).json({ message: "Sucursal no encontrada" });
    const [result] = await req.db.query(
      'INSERT INTO cajas (numero_caja, sucursal_id, estado) VALUES (?, ?, ?)',
      [numero_caja, sucursal[0].id, estado || 'Cerrada']
    );
    res.status(201).json({ id: result.insertId, message: 'Caja agregada' });
  } catch (err) {
    console.error('Error al agregar caja:', err);
    res.status(500).json({ message: 'Error al agregar caja', error: err.message });
  }
});

router.post('/aperturas_caja', async (req, res) => {
  const { caja_id, usuario_id, monto_apertura } = req.body;
  try {
    const [usuario] = await req.db.query("SELECT id FROM usuarios WHERE id = ?", [usuario_id]);
    if (!usuario.length) return res.status(400).json({ message: "Usuario no encontrado" });
    const [caja] = await req.db.query("SELECT estado FROM cajas WHERE id = ?", [caja_id]);
    if (!caja.length || caja[0].estado !== 'Cerrada') {
      return res.status(400).json({ message: "Caja no disponible para apertura" });
    }
    const [result] = await req.db.query(
      `INSERT INTO aperturas_caja (caja_id, usuario_id, monto_apertura) VALUES (?, ?, ?)`,
      [caja_id, usuario_id, monto_apertura]
    );
    await req.db.query("UPDATE cajas SET estado = 'Abierta' WHERE id = ?", [caja_id]);
    res.status(201).json({ id: result.insertId, message: 'Apertura registrada' });
  } catch (err) {
    console.error('Error al registrar apertura:', err);
    res.status(500).json({ message: 'Error al registrar apertura', error: err.message });
  }
});

// Agregar endpoint para cierres de caja
router.post('/cierres_caja', async (req, res) => {
  const { apertura_id, total_ventas, efectivo_en_caja, observaciones } = req.body;
  try {
    const [result] = await req.db.query(
      `INSERT INTO cierres_caja (apertura_id, total_ventas, efectivo_en_caja, observaciones)
       VALUES (?, ?, ?, ?)`,
      [apertura_id, total_ventas, efectivo_en_caja, observaciones || null]
    );
    await req.db.query('UPDATE cajas SET estado = "Cerrada" WHERE id = (SELECT caja_id FROM aperturas_caja WHERE id = ?)', [apertura_id]);
    res.status(201).json({ id: result.insertId, message: 'Cierre registrado' });
  } catch (err) {
    console.error('Error al registrar cierre:', err);
    res.status(500).json({ message: 'Error al registrar cierre', error: err.message });
  }
});

router.get('/aperturas_cierres', async (req, res) => {
  const { apertura_id } = req.query;
  try {
    let query = `
      SELECT 
        a.id, a.caja_id, a.usuario_id, a.fecha_apertura, a.monto_apertura, a.total_apertura,
        c.numero_caja, c.sucursal_id, s.nombre AS sucursal_nombre, c.estado,
        cc.fecha_cierre, cc.total_ventas, cc.efectivo_en_caja, cc.observaciones
      FROM aperturas_caja a
      LEFT JOIN cajas c ON a.caja_id = c.id
      LEFT JOIN sucursal s ON c.sucursal_id = s.id
      LEFT JOIN cierres_caja cc ON a.id = cc.apertura_id
    `;
    const params = [];
    if (apertura_id) {
      query += ' WHERE a.id = ?';
      params.push(apertura_id);
    }
    query += ' ORDER BY a.fecha_apertura DESC';
    const [rows] = await req.db.query(query, params);
    res.json(rows);
  } catch (err) {
    console.error('Error al obtener aperturas y cierres:', err);
    res.status(500).json({ message: 'Error al obtener aperturas y cierres', error: err.message });
  }
});



// ------------------ OTROS ENDPOINTS ------------------

router.get("/traslados/sucursales", async (req, res) => {
  try {
    const [rows] = await req.db.query(
      "SELECT codigo, nombre FROM sucursal WHERE estado = 'Activo'"
    );
    console.log("Datos crudos de sucursales enviados al frontend:", JSON.stringify(rows, null, 2));
    res.json(rows);
  } catch (err) {
    console.error("Error al obtener sucursales:", err);
    res.status(500).json({ message: "Error al obtener sucursales", error: err.message });
  }
});

router.get("/categorias", async (req, res) => {
  try {
    const [rows] = await req.db.query("SELECT id, nombre FROM categoria");
    res.json(rows);
  } catch (err) {
    console.error("Error al obtener categorías:", err);
    res.status(500).json({ error: err.message });
  }
});

router.get("/buscar-inventario", async (req, res) => {
  try {
    const { categoria_id, nombre } = req.query;  // categoria_id ahora es el nombre de la categoría
    let query = "SELECT id, codigo, nombre, precio_venta, stock_existencia FROM inventario WHERE 1=1";
    const params = [];

    if (categoria_id) {
      query += " AND categoria = ?";  // Cambiado de categoria_id a categoria
      params.push(categoria_id);  // Ahora es texto
    }
    if (nombre) {
      query += " AND (nombre LIKE ? OR codigo LIKE ?)";
      params.push(`%${nombre}%`, `%${nombre}%`);
    }

    const [rows] = await req.db.query(query, params);
    console.log("Productos devueltos:", rows);
    res.status(200).json(rows);
  } catch (err) {
    console.error("Error al buscar inventario:", err);
    res.status(500).json({ error: err.message });
  }
});




module.exports = router;


