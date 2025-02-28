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

router.post('/ventas/autorizar-descuento', async (req, res) => {
  const { codigo } = req.body;
  try {
    const [rows] = await req.db.query('SELECT codigo FROM codigos_autorizacion');
    for (const row of rows) {
      if (await bcrypt.compare(codigo, row.codigo)) {
        return res.json({ autorizado: true });
      }
    }
    res.json({ autorizado: false });
  } catch (err) {
    console.error('Error al autorizar descuento:', err);
    res.status(500).json({ message: 'Error al autorizar descuento', error: err.message });
  }
});

router.post("/ventas", async (req, res) => {
  try {
    const {
      codigo_venta,
      cliente_id,
      empleado_id,
      tipo_factura,
      metodo_pago,
      total,
      descripcion_compra,
      productos,
      fecha_venta,
      factura,
      comprobante_credito_fiscal,
      factura_exportacion,
      nota_credito,
      nota_debito,
      nota_remision,
      comprobante_liquidacion,
      comprobante_retencion,
      documento_contable_liquidacion,
      comprobante_donacion,
      factura_sujeto_excluido,
      descuento,
      codigo_autorizacion // Nuevo campo opcional para el código de autorización
    } = req.body;

    // Generar código automático si no se proporciona
    const finalCodigoVenta = codigo_venta || await generateCode(req.db, 'VGR', 'ventas', 'codigo_venta');

    // Validaciones básicas
    if (!empleado_id) return res.status(400).json({ message: "El ID del empleado es requerido" });
    
    const [empleado] = await req.db.query(
      `SELECT e.id, u.tipo_cuenta 
       FROM empleados e 
       LEFT JOIN usuarios u ON e.id = u.empleado_id 
       WHERE e.id = ?`, 
      [empleado_id]
    );
    if (empleado.length === 0) return res.status(400).json({ message: "Empleado no encontrado" });

    for (const producto of productos) {
      const [inventario] = await req.db.query("SELECT stock_existencia FROM inventario WHERE codigo = ?", [producto.codigo_producto]);
      if (inventario.length === 0) return res.status(404).json({ message: `Producto ${producto.codigo_producto} no encontrado` });
      if (inventario[0].stock_existencia < producto.cantidad) {
        return res.status(400).json({ message: `Stock insuficiente para el producto ${producto.codigo_producto}` });
      }
    }

    // Validación de descuento
    const descuentoValue = parseFloat(descuento) || 0.0;
    if (descuentoValue > 0) {
      const tipoCuenta = empleado[0].tipo_cuenta;
      if (tipoCuenta !== 'Admin' && tipoCuenta !== 'Root') {
        // Requiere código de autorización
        if (!codigo_autorizacion) {
          return res.status(403).json({ message: "Se requiere autorización para aplicar descuento" });
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
          return res.status(403).json({ message: "Código de autorización inválido" });
        }
      }
    }

    // Insertar venta
    const [ventaResult] = await req.db.query(
      `INSERT INTO ventas (
        codigo_venta, cliente_id, empleado_id, tipo_factura, metodo_pago, total, 
        descripcion_compra, fecha_venta, factura, comprobante_credito_fiscal, 
        factura_exportacion, nota_credito, nota_debito, nota_remision, 
        comprobante_liquidacion, comprobante_retencion, documento_contable_liquidacion, 
        comprobante_donacion, factura_sujeto_excluido, descuento
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        finalCodigoVenta, cliente_id, empleado_id, tipo_factura, metodo_pago, total,
        descripcion_compra, fecha_venta || new Date(), factura || null, comprobante_credito_fiscal || null,
        factura_exportacion || null, nota_credito || null, nota_debito || null, nota_remision || null,
        comprobante_liquidacion || null, comprobante_retencion || null, documento_contable_liquidacion || null,
        comprobante_donacion || null, factura_sujeto_excluido || null, descuentoValue
      ]
    );

    const ventaId = ventaResult.insertId;

    // Insertar detalles y actualizar stock
    for (const producto of productos) {
      await req.db.query(
        `INSERT INTO detalle_ventas (idVentas, codigo_producto, nombre, cantidad, precio_unitario, subtotal)
         VALUES (?, ?, ?, ?, ?, ?)`,
        [ventaId, producto.codigo_producto, producto.nombre, producto.cantidad, producto.precio_unitario, producto.subtotal]
      );
      await req.db.query(
        "UPDATE inventario SET stock_existencia = stock_existencia - ? WHERE codigo = ?",
        [producto.cantidad, producto.codigo_producto]
      );
    }

    res.status(201).json({ message: "Venta agregada correctamente", ventaId, codigo_venta: finalCodigoVenta });
  } catch (err) {
    console.error("Error al agregar la venta:", err);
    res.status(500).json({ message: "Error al agregar la venta", error: err.message });
  }
});

router.get("/ventas", async (req, res) => {
  const { page = 1, limit = 10 } = req.query;
  const offset = (page - 1) * limit;

  try {
    const query = `
      SELECT 
        v.idVentas, v.codigo_venta, v.fecha_venta, v.tipo_factura, v.metodo_pago, v.total,
        v.descripcion_compra, v.empleado_id, CONCAT(e.nombres, ' ', e.apellidos) AS empleado_nombre,
        c.nombre AS cliente_nombre, c.direccion AS direccion_cliente, c.dui, c.nit, c.tipo_cliente,
        c.registro_contribuyente, c.representante_legal, c.direccion_representante, c.razon_social,
        c.email, c.telefono, c.fecha_inicio, c.fecha_fin, c.porcentaje_retencion,
        v.factura, v.comprobante_credito_fiscal, v.factura_exportacion, v.nota_credito, v.nota_debito,
        v.nota_remision, v.comprobante_liquidacion, v.comprobante_retencion, v.documento_contable_liquidacion,
        v.comprobante_donacion, v.factura_sujeto_excluido, v.descuento,
        JSON_ARRAYAGG(
          JSON_OBJECT(
            'codigo', dv.codigo_producto, 
            'nombre', i.nombre, 
            'cantidad', dv.cantidad,
            'precio', dv.precio_unitario, 
            'costo', i.costo, 
            'numero_chasis', i.numero_chasis,
            'numero_motor', i.numero_motor, 
            'descripcion', i.descripcion,
            'categoria', cat.nombre, 
            'sucursal', suc.nombre, 
            'proveedor', prov.nombre_comercial
          )
        ) AS productos
      FROM ventas v
      LEFT JOIN clientes c ON v.cliente_id = c.idCliente
      LEFT JOIN empleados e ON v.empleado_id = e.id
      LEFT JOIN detalle_ventas dv ON v.idVentas = dv.idVentas
      LEFT JOIN inventario i ON dv.codigo_producto = i.codigo
      LEFT JOIN categoria cat ON i.categoria_id = cat.id
      LEFT JOIN sucursal suc ON i.sucursal_id = suc.id
      LEFT JOIN proveedores prov ON i.proveedor_id = prov.id
      GROUP BY v.idVentas
      ORDER BY v.fecha_venta DESC
      LIMIT ? OFFSET ?
    `;
    const [rows] = await req.db.query(query, [parseInt(limit), parseInt(offset)]);
    const [totalResult] = await req.db.query('SELECT COUNT(*) AS total FROM ventas');
    const total = totalResult[0].total;

    res.json({ ventas: rows, total, page: parseInt(page), limit: parseInt(limit), totalPages: Math.ceil(total / limit) });
  } catch (err) {
    console.error("Error al obtener ventas:", err);
    res.status(500).json({ error: err.message });
  }
});

router.put("/ventas/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { tipo_factura, metodo_pago, descripcion_compra } = req.body; // Solo aceptamos estos campos

    const [ventaActual] = await req.db.query("SELECT * FROM ventas WHERE idVentas = ?", [id]);
    if (ventaActual.length === 0) return res.status(404).json({ message: "Venta no encontrada" });

    // Actualizamos solo los campos permitidos
    await req.db.query(
      `UPDATE ventas SET 
         tipo_factura = ?, metodo_pago = ?, descripcion_compra = ?
       WHERE idVentas = ?`,
      [
        tipo_factura || ventaActual[0].tipo_factura,
        metodo_pago || ventaActual[0].metodo_pago,
        descripcion_compra || ventaActual[0].descripcion_compra,
        id
      ]
    );

    // Guardamos historial con los datos nuevos limitados
    const datosNuevos = {
      tipo_factura: tipo_factura || ventaActual[0].tipo_factura,
      metodo_pago: metodo_pago || ventaActual[0].metodo_pago,
      descripcion_compra: descripcion_compra || ventaActual[0].descripcion_compra,
    };

    await req.db.query(
      `INSERT INTO historial_cambios_ventas (venta_id, codigo_venta, datos_anteriores, datos_nuevos)
       VALUES (?, ?, ?, ?)`,
      [id, ventaActual[0].codigo_venta, JSON.stringify(ventaActual[0]), JSON.stringify(datosNuevos)]
    );

    res.json({ message: "Venta actualizada correctamente" });
  } catch (err) {
    console.error("Error al actualizar:", err);
    res.status(500).json({ message: "Error al actualizar", error: err.message });
  }
});

router.get("/ventas/:id/historial", async (req, res) => {
  try {
    const { id } = req.params;
    const [historial] = await req.db.query(
      `SELECT id, venta_id, codigo_venta, fecha_cambio, datos_anteriores, datos_nuevos
       FROM historial_cambios_ventas WHERE venta_id = ? ORDER BY fecha_cambio DESC`,
      [id]
    );
    res.json(historial);
  } catch (err) {
    console.error("Error al obtener historial:", err);
    res.status(500).json({ message: "Error al obtener historial", error: err.message });
  }
});

router.delete("/ventas/:id", async (req, res) => {
  try {
    const { id } = req.params;
    await req.db.query("DELETE FROM detalle_ventas WHERE idVentas = ?", [id]);
    const [result] = await req.db.query("DELETE FROM ventas WHERE idVentas = ?", [id]);
    if (result.affectedRows === 0) return res.status(404).json({ message: "Venta no encontrada" });
    res.json({ message: "Venta eliminada correctamente" });
  } catch (err) {
    console.error("Error al eliminar la venta:", err);
    res.status(500).json({ message: "Error al eliminar la venta", error: err.message });
  }
});



// ------------------ CLIENTES ------------------

router.get("/clientes", async (req, res) => {
  const { page = 1, limit = 10, q } = req.query;
  const offset = (page - 1) * limit;

  try {
    let query = `
      SELECT * FROM clientes
      WHERE 1=1
    `;
    const params = [];

    if (q) {
      query += " AND nombre LIKE ?";
      params.push(`%${q}%`);
    }

    query += " ORDER BY idCliente DESC LIMIT ? OFFSET ?";
    params.push(parseInt(limit), parseInt(offset));

    const [rows] = await req.db.query(query, params);
    const [totalResult] = await req.db.query("SELECT COUNT(*) AS total FROM clientes" + (q ? " WHERE nombre LIKE ?" : ""), q ? [`%${q}%`] : []);
    const total = totalResult[0].total;

    res.json({ clientes: rows, total, page: parseInt(page), limit: parseInt(limit), totalPages: Math.ceil(total / limit) });
  } catch (err) {
    console.error("Error al obtener clientes:", err);
    res.status(500).json({ message: "Error al obtener clientes", error: err.message });
  }
});

router.post("/clientes", async (req, res) => {
  try {
    const {
      nombre, direccion, dui, nit, tipo_cliente, registro_contribuyente,
      representante_legal, direccion_representante, razon_social, email,
      telefono, fecha_inicio, fecha_fin, porcentaje_retencion,
    } = req.body;

    // Validaciones obligatorias generales
    if (!nombre || !direccion || !nit || !registro_contribuyente || !email || !telefono) {
      return res.status(400).json({ message: "Todos los campos generales son requeridos" });
    }

    // Validaciones por tipo de cliente
    if ((tipo_cliente === 'Natural' || tipo_cliente === 'Consumidor Final') && !dui) {
      return res.status(400).json({ message: "DUI es requerido para Natural y Consumidor Final" });
    }
    if (tipo_cliente === 'Contribuyente Jurídico' && (!representante_legal || !direccion_representante)) {
      return res.status(400).json({ message: "Representante Legal y Dirección son requeridos" });
    }
    if (tipo_cliente === 'ONG' && !razon_social) {
      return res.status(400).json({ message: "Razón Social es requerida para ONG" });
    }

    let finalPorcentajeRetencion = porcentaje_retencion;
    if (tipo_cliente === 'Sujeto Excluido') {
      finalPorcentajeRetencion = 10.0;
    }

    const codigoCliente = await generateCode(req.db, 'CGR', 'clientes', 'codigo_cliente');

    const [result] = await req.db.query(
      `INSERT INTO clientes (
        codigo_cliente, nombre, direccion, dui, nit, tipo_cliente, registro_contribuyente, 
        representante_legal, direccion_representante, razon_social, email, telefono, 
        fecha_inicio, fecha_fin, porcentaje_retencion
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        codigoCliente, nombre, direccion, dui, nit, tipo_cliente, registro_contribuyente,
        representante_legal, direccion_representante, razon_social, email, telefono,
        fecha_inicio, fecha_fin, finalPorcentajeRetencion
      ]
    );

    res.status(201).json({
      message: "Cliente agregado correctamente",
      idCliente: result.insertId,
      codigo_cliente: codigoCliente,
    });
  } catch (err) {
    console.error("Error al agregar cliente:", err);
    res.status(500).json({ message: "Error al agregar cliente", error: err.message });
  }
});

router.put("/clientes/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { direccion, email, telefono } = req.body;

    const [clienteActual] = await req.db.query("SELECT * FROM clientes WHERE idCliente = ?", [id]);
    if (clienteActual.length === 0) return res.status(404).json({ message: "Cliente no encontrado" });

    const datosActualizados = {
      direccion: direccion || clienteActual[0].direccion,
      email: email || clienteActual[0].email,
      telefono: telefono || clienteActual[0].telefono,
    };

    await req.db.query(
      `UPDATE clientes SET 
         direccion = ?, email = ?, telefono = ?
       WHERE idCliente = ?`,
      [datosActualizados.direccion, datosActualizados.email, datosActualizados.telefono, id]
    );

    const datosNuevos = {
      direccion: datosActualizados.direccion,
      email: datosActualizados.email,
      telefono: datosActualizados.telefono,
    };

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
            'producto_nombre', i.nombre
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
      query += " AND (t.codigo_traslado LIKE ? OR i.nombre LIKE ?)";
      params.push(`%${search}%`, `%${search}%`);
    }
    if (codigo_sucursal_origen) {
      query += " AND t.codigo_sucursal_origen = ?";
      params.push(codigo_sucursal_origen);
    }

    // Ajustamos el GROUP BY para incluir todas las columnas no agregadas
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
      (search ? " AND (t.codigo_traslado LIKE ? OR i.nombre LIKE ?)" : "") +
      (codigo_sucursal_origen ? " AND t.codigo_sucursal_origen = ?" : ""),
      search && codigo_sucursal_origen ? [`%${search}%`, `%${search}%`, codigo_sucursal_origen] :
      search ? [`%${search}%`, `%${search}%`] : codigo_sucursal_origen ? [codigo_sucursal_origen] : []
    );
    const total = totalResult[0].total;

    res.json({ traslados: rows, total });
  } catch (err) {
    console.error("Error al obtener los traslados:", err);
    res.status(500).json({ message: "Error al obtener los traslados", error: err.message });
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
        i.categoria_id,
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

    if (categoria_id) {
      query += " AND i.categoria_id = ?";
      params.push(categoria_id);
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
    const [totalResult] = await req.db.query('SELECT COUNT(*) AS total FROM ofertas o INNER JOIN inventario i ON o.inventario_id = i.id WHERE 1=1' + 
      (categoria_id ? " AND i.categoria_id = ?" : "") + (nombre ? " AND i.nombre LIKE ?" : ""), 
      categoria_id && nombre ? [categoria_id, `%${nombre}%`] : categoria_id ? [categoria_id] : nombre ? [`%${nombre}%`] : []);
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
    const { categoria_id, nombre } = req.query;
    let query = "SELECT id, codigo, nombre, precio_venta, stock_existencia FROM inventario WHERE 1=1";
    const params = [];

    if (categoria_id) {
      query += " AND categoria_id = ?";
      params.push(categoria_id);
    }
    if (nombre) {
      query += " AND (nombre LIKE ? OR codigo LIKE ?)";
      params.push(`%${nombre}%`, `%${nombre}%`); // Busca en nombre o código
    }

    const [rows] = await req.db.query(query, params);
    res.status(200).json(rows);
  } catch (err) {
    console.error("Error al buscar inventario:", err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;


