const express = require("express");
const router = express.Router();
const path = require("path");
const fs = require("fs");
const multer = require("multer");

// Directorio para las imágenes subidas
const uploadsDir = path.join(__dirname, "../uploads");
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

// Configuración de Multer para almacenar archivos
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadsDir);
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + path.extname(file.originalname));
  },
});
const upload = multer({ storage });

/* ==================== RUTAS DE INVENTARIO ==================== */

// POST: Insertar un nuevo producto en inventario o actualizar existente
router.post("/inventario", async (req, res) => {
  try {
    // Imprimir los datos que llegan en la solicitud
    console.log(req.body);

    const {
      comprobante,
      fecha_ingreso,
      codigo_producto,
      producto,
      cantidad,
      comentario,
      proveedor,
      costo_unit,
      costo_total,
      retencion,
      sucursal,
      codigo,
      nombre,
      categoria,
      marca,
      descripcion,
      stock_existencia,
      precio_venta,
      numero_motor,
      numero_chasis,
      color,
      poliza,
    } = req.body;

    // Validar campos obligatorios
    if (!codigo || !nombre || !categoria || !sucursal || !proveedor || !poliza) {
      return res.status(400).json({
        message: "Campos obligatorios faltantes: código, nombre, categoría, sucursal, proveedor o póliza.",
      });
    }

    // Verificar si el producto ya existe en la misma sucursal
    const [existingProduct] = await req.db.query(
      "SELECT * FROM inventario WHERE codigo = ? AND sucursal = ?",
      [codigo, sucursal]
    );

    if (existingProduct.length > 0) {
      // Si el producto existe en la misma sucursal, actualizar stock y precio
      const newStock = existingProduct[0].stock_existencia + parseInt(cantidad);
      const newPrecioVenta = precio_venta || existingProduct[0].precio_venta;

      await req.db.query(
        "UPDATE inventario SET stock_existencia = ?, precio_venta = ? WHERE id = ?",
        [newStock, newPrecioVenta, existingProduct[0].id]
      );

      // Registrar la entrada en la tabla `entradas`
      await req.db.query(
        "INSERT INTO entradas (comprobante, fecha_ingreso, codigo_producto, producto, cantidad, comentario, proveedor, costo_unit, costo_total, retencion) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
        [comprobante, fecha_ingreso, codigo, nombre, cantidad, comentario, proveedor, costo_unit, costo_total, retencion]
      );

      return res.status(200).json({
        message: "Producto actualizado exitosamente",
        id: existingProduct[0].id,
      });
    } else {
      // Si el producto no existe en la sucursal, insertar un nuevo registro
      const [result] = await req.db.query(
        "INSERT INTO inventario (sucursal, codigo, nombre, categoria, marca, descripcion, stock_existencia, precio_venta, numero_motor, numero_chasis, color, poliza) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
        [sucursal, codigo, nombre, categoria, marca, descripcion, stock_existencia, precio_venta, numero_motor, numero_chasis, color, poliza]
      );

      // Registrar la entrada en la tabla `entradas`
      await req.db.query(
        "INSERT INTO entradas (comprobante, fecha_ingreso, codigo_producto, producto, cantidad, comentario, proveedor, costo_unit, costo_total, retencion) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
        [comprobante, fecha_ingreso, codigo, nombre, cantidad, comentario, proveedor, costo_unit, costo_total, retencion]
      );

      return res.status(201).json({
        message: "Producto insertado exitosamente",
        id: result.insertId,
      });
    }
  } catch (err) {
    res.status(500).json({ message: "Error interno del servidor", error: err.message });
  }
});

// GET: Obtener inventario (resumido o detallado)
router.get("/inventario", async (req, res) => {
  try {
    const tipo = req.query.tipo;
    let query = "SELECT * FROM inventario";

    if (tipo === "detallado") {
      query = `
        SELECT 
          id,
          codigo,
          nombre AS nombre,
          descripcion AS descripcion,
          numero_motor,
          numero_chasis,
          categoria,
          sucursal,
          marca,
          color,
          poliza,
          precio_venta,
          stock_existencia
        FROM inventario;
      `;
    } else if (tipo === "resumido") {
      query = `
        SELECT 
          nombre AS nombre,
          descripcion AS descripcion,
          marca,
          categoria,
          sucursal,
          SUM(stock_existencia) AS stock_total,
          AVG(precio_venta) AS precio_promedio
        FROM inventario
        GROUP BY nombre, descripcion, marca, categoria, sucursal, precio_venta;
      `;
    }

    const [results] = await req.db.query(query);
    res.json(results);
  } catch (err) {
    res.status(500).json({
      message: "Error al obtener inventario",
      error: err.message,
    });
  }
});

// GET: Obtener detalles de un producto por nombre y descripción
router.get("/inventario/detalles", async (req, res) => {
  try {
    const { nombre, descripcion } = req.query;
    if (!nombre || !descripcion) {
      return res.status(400).json({ message: "Faltan parámetros requeridos" });
    }

    let query = `
      SELECT 
        id,
        codigo,
        numero_motor, 
        numero_chasis,
        poliza,
        nombre,
        descripcion,
        stock_existencia,
        precio_venta,
        color,
        marca,
        categoria,
        sucursal
      FROM inventario 
      WHERE nombre = ? AND descripcion = ?
    `;
    const params = [nombre, descripcion];

    const [results] = await req.db.query(query, params);
    res.json(results);
  } catch (err) {
    res.status(500).json({
      message: "Error al obtener detalles del producto",
      error: err.message,
    });
  }
});

// PUT: Actualizar productos por ID
router.put("/inventario/edit/:id", async (req, res) => {
  const { id } = req.params;
  const { nombre, descripcion, marca,  precio_venta, motivo } = req.body;
  const connection = await req.db.getConnection();
  try {
    await connection.beginTransaction();
    
    // Verificar si existe el producto por ID
    const [rows] = await connection.query("SELECT * FROM inventario WHERE id = ?", [id]);
    if (rows.length === 0) {
      await connection.rollback();
      return res.status(404).json({ message: "Producto no encontrado" });
    }

    // Actualizar el producto
    await connection.query(
      `UPDATE inventario SET 
        nombre = ?, 
        descripcion = ?, 
        marca = ?,  
        precio_venta = ? 
      WHERE id = ?`,
      [nombre, descripcion, marca, precio_venta, id]
    );

    // Insertar registro en historial
    await connection.query(
      `INSERT INTO historial_ajustes (codigo, nombre, descripcion, precio, motivo) 
       VALUES (?, ?, ?, ?, ?)`,
      [rows[0].codigo, nombre, descripcion, precio_venta, motivo]
    );

    await connection.commit();
    res.json({ message: "Producto y historial actualizados correctamente" });
  } catch (err) {
    await connection.rollback();
    res.status(500).json({
      message: "Error al actualizar los datos",
      error: err.message,
    });
  } finally {
    connection.release();
  }
});


// DELETE: Eliminar producto por ID
router.delete("/inventario/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const [result] = await req.db.query("DELETE FROM inventario WHERE id = ?", [id]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Producto no encontrado" });
    }
    res.json({ message: "Producto eliminado exitosamente" });
  } catch (err) {
    res.status(500).json({ message: "Error al eliminar producto", error: err.message });
  }
});


/* ==================== RUTAS DE Ubicacion ==================== */

// GET y POST: Obtener todas las ubicacion y crear una nueva
router.route("/ubicaciones_productos")
  .get(async (req, res) => {
    try {
      const [results] = await req.db.query("SELECT * FROM ubicaciones_productos");
      res.json(results);
    } catch (err) {
      res.status(500).json({ message: "Error al obtener ubicaciones", error: err.message });
    }
  })
  .post(async (req, res) => {
    try {
      // Aquí podrías agregar validación de campos si lo requieres
      const [result] = await req.db.query("INSERT INTO ubicaciones_productos SET ?", [req.body]);
      res.status(201).json({
        message: "Ubicacion creada",
        id: result.insertId,
      });
    } catch (err) {
      res.status(500).json({ message: "Error al crear Ubicacion", error: err.message });
    }
  });

// GET: Obtener ubicacion por ID
router.get("/ubicaciones_productos/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const [results] = await req.db.query("SELECT * FROM ubicaciones_productos WHERE id = ?", [id]);
    if (results.length === 0) {
      return res.status(404).json({ message: "Ubicacion no encontrada" });
    }
    res.json(results[0]);
  } catch (err) {
    res.status(500).json({ message: "Error al obtener Ubicacion", error: err.message });
  }
});

// PUT: Actualizar Ubicacion por ID
router.put("/ubicaciones_productos/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const {  sucursal_id, ubicacion, descripcion } = req.body;
    const [rows] = await req.db.query("SELECT * FROM ubicaciones_productos WHERE id = ?", [id]);
    if (rows.length === 0) {
      return res.status(404).json({ message: "Ubicacion no encontrada" });
    }
    await req.db.query(
      "UPDATE ubicaciones_productos SET  sucursal_id = ?, ubicacion = ?, descripcion = ? WHERE id = ?",
      [ sucursal_id, ubicacion, descripcion, id]
    );
    res.json({ message: "Ubicacion actualizada correctamente" });
  } catch (err) {
    res.status(500).json({ message: "Error al actualizar la Ubicacion", error: err.message });
  }
});

// DELETE: Eliminar Ubicacion por ID
router.delete("/ubicaciones_productos/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const [result] = await req.db.query("DELETE FROM ubicaciones_productos WHERE id = ?", [id]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Ubicacion no encontrada" });
    }
    res.json({ message: "PUbicacion eliminada exitosamente" });
  } catch (err) {
    res.status(500).json({ message: "Error al eliminar Ubicacion", error: err.message });
  }
});

/* ==================== RUTAS DE HISTORIAL ==================== */

// GET: Obtener todo el historial de ajustes
router.get("/historial_ajustes", async (req, res) => {
  try {
    const [results] = await req.db.query("SELECT * FROM historial_ajustes");
    res.json(results);
  } catch (err) {
    res.status(500).json({ message: "Error al obtener el historial", error: err.message });
  }
});

// GET: Obtener historial por ID
router.get("/historial_ajustes/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const [results] = await req.db.query("SELECT * FROM historial_ajustes WHERE id = ?", [id]);
    if (results.length === 0) {
      return res.status(404).json({ message: "Historial no encontrado" });
    }
    res.json(results[0]);
  } catch (err) {
    res.status(500).json({ message: "Error al obtener historial", error: err.message });
  }
});

/* ==================== RUTAS DE Ingreso ==================== */

// GET: Obtener todo el historial de ingreso
router.get("/entradas", async (req, res) => {
  try {
    const query = `
      SELECT e.*, p.nombre_comercial 
      FROM entradas e
      LEFT JOIN proveedores p ON e.proveedor = p.id
    `;

    const [results] = await req.db.query(query);
    res.json(results);
  } catch (err) {
    res.status(500).json({ message: "Error al obtener las entradas", error: err.message });
  }
});


// GET: Obtener entradas por ID
router.get("/entradas/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const [results] = await req.db.query("SELECT * FROM entradas WHERE id = ?", [id]);
    if (results.length === 0) {
      return res.status(404).json({ message: "entradas no encontrado" });
    }
    res.json(results[0]);
  } catch (err) {
    res.status(500).json({ message: "Error al obtener entradas", error: err.message });
  }
});

/* ==================== RUTAS DE SUCURSALES ==================== */

// GET y POST: Obtener todas las sucursales y crear una nueva
router.route("/sucursal")
  .get(async (req, res) => {
    try {
      const [results] = await req.db.query("SELECT * FROM sucursal");
      res.json(results);
    } catch (err) {
      res.status(500).json({ message: "Error al obtener sucursales", error: err.message });
    }
  })
  .post(async (req, res) => {
    try {
      // Aquí podrías agregar validación de campos si lo requieres
      const [result] = await req.db.query("INSERT INTO sucursal SET ?", [req.body]);
      res.status(201).json({
        message: "Sucursal creada",
        id: result.insertId,
      });
    } catch (err) {
      res.status(500).json({ message: "Error al crear sucursal", error: err.message });
    }
  });

// GET: Obtener sucursal por ID
router.get("/sucursal/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const [results] = await req.db.query("SELECT * FROM sucursal WHERE id = ?", [id]);
    if (results.length === 0) {
      return res.status(404).json({ message: "Sucursal no encontrada" });
    }
    res.json(results[0]);
  } catch (err) {
    res.status(500).json({ message: "Error al obtener sucursal", error: err.message });
  }
});

// PUT: Actualizar sucursal por ID
router.put("/sucursal/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { codigo, nombre, pais, departamento, ciudad, direccion, telefono, gmail, estado } = req.body;
    const [rows] = await req.db.query("SELECT * FROM sucursal WHERE id = ?", [id]);
    if (rows.length === 0) {
      return res.status(404).json({ message: "Sucursal no encontrada" });
    }
    await req.db.query(
      "UPDATE sucursal SET codigo = ?, nombre = ?, pais = ?, departamento = ?, ciudad = ?, direccion = ?, telefono = ?, gmail = ?, estado = ? WHERE id = ?",
      [codigo, nombre, pais, departamento, ciudad, direccion, telefono, gmail, estado, id]
    );
    res.json({ message: "Sucursal actualizada correctamente" });
  } catch (err) {
    res.status(500).json({ message: "Error al actualizar la sucursal", error: err.message });
  }
});

// DELETE: Eliminar sucursal por ID
router.delete("/sucursal/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const [result] = await req.db.query("DELETE FROM sucursal WHERE id = ?", [id]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Sucursal no encontrada" });
    }
    res.json({ message: "Sucursal eliminada exitosamente" });
  } catch (err) {
    res.status(500).json({ message: "Error al eliminar sucursal", error: err.message });
  }
});


/* ==================== RUTAS DE CATEGORÍAS ==================== */

// GET y POST: Obtener todas las categorías y crear una nueva
router.route("/categoria")
  .get(async (req, res) => {
    try {
      const [results] = await req.db.query("SELECT * FROM categoria");
      res.json(results);
    } catch (err) {
      res.status(500).json({ message: "Error al obtener categorias", error: err.message });
    }
  })
  .post(async (req, res) => {
    try {
      // Agrega validación de campos si lo requieres
      const [result] = await req.db.query("INSERT INTO categoria SET ?", [req.body]);
      res.status(201).json({
        message: "Categoria creada",
        id: result.insertId,
      });
    } catch (err) {
      res.status(500).json({ message: "Error al crear categoria", error: err.message });
    }
  });

// GET: Obtener categoría por ID
router.get("/categoria/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const [results] = await req.db.query("SELECT * FROM categoria WHERE id = ?", [id]);
    if (results.length === 0) {
      return res.status(404).json({ message: "Categoria no encontrada" });
    }
    res.json(results[0]);
  } catch (err) {
    res.status(500).json({ message: "Error al obtener categoria", error: err.message });
  }
});

// PUT: Actualizar categoría por ID
router.put("/categoria/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { nombre, descripcion, fecha_creacion, estado } = req.body;
    const [rows] = await req.db.query("SELECT * FROM categoria WHERE id = ?", [id]);
    if (rows.length === 0) {
      return res.status(404).json({ message: "Categoria no encontrada" });
    }
    await req.db.query(
      "UPDATE categoria SET nombre = ?, descripcion = ?, fecha_creacion = ?, estado = ? WHERE id = ?",
      [nombre, descripcion, fecha_creacion, estado, id]
    );
    res.json({ message: "Categoria actualizada correctamente" });
  } catch (err) {
    res.status(500).json({ message: "Error al actualizar categoria", error: err.message });
  }
});

// DELETE: Eliminar categoría por ID
router.delete("/categoria/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const [result] = await req.db.query("DELETE FROM categoria WHERE id = ?", [id]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Categoria no encontrada" });
    }
    res.json({ message: "Categoria eliminada exitosamente" });
  } catch (err) {
    res.status(500).json({ message: "Error al eliminar categoria", error: err.message });
  }
});

/* ==================== RUTAS DE PROVEEDORES ==================== */
// GET: Obtener todos los proveedores
router.get("/proveedores", async (req, res) => {
  try {
    const query = `
      SELECT 
        p.id,
        p.tipo_proveedor,
        p.nombre_comercial, 
        p.correo, 
        p.direccion, 
        p.telefono, 
        p.giro, 
        p.correspondencia, 
        p.rubro,
        -- Datos de proveedores naturales
        pn.nombre_propietario, 
        pn.dui, 
        pn.nrc AS nrc_natural,
        -- Datos de proveedores jurídicos
        pj.razon_social, 
        pj.nit, 
        pj.nrc AS nrc_juridico, 
        pj.nombres_representante,
        pj.apellidos_representante,
        pj.direccion_representante,
        pj.telefono_representante,
        pj.dui_representante,
        pj.nit_representante,
        pj.correo_representante,
        -- Datos de proveedores excluidos
        pe.nombre_propietario AS nombre_propietario_excluido,
        pe.dui AS dui_excluido
      FROM proveedores p
      LEFT JOIN proveedores_naturales pn ON p.id = pn.proveedor_id
      LEFT JOIN proveedores_juridicos pj ON p.id = pj.proveedor_id
      LEFT JOIN proveedores_excluidos pe ON p.id = pe.proveedor_id;
    `;

    const [results] = await req.db.query(query);
    res.json(results);
  } catch (err) {
    res.status(500).json({
      message: "Error al obtener proveedores",
      error: err.message,
    });
  }
});



router.post("/proveedores", async (req, res) => {
  // Imprimir el cuerpo de la solicitud para verificar los datos recibidos
  console.log("Datos recibidos en el cuerpo de la solicitud:", req.body);

  const {
    nombre_comercial,
    correo,
    direccion,
    telefono,
    tipo_proveedor,
    rubro,
    giro,
    correspondencia,
    // Datos de proveedores naturales
    nombre_propietario,
    dui,
    nrc_natural,
    // Datos de proveedores jurídicos
    razon_social,
    nit,
    nrc_juridico,
    nombres_representante,
    apellidos_representante,
    direccion_representante,
    telefono_representante,
    dui_representante,
    nit_representante,
    correo_representante,
    // Datos de proveedores excluidos
    nombre_propietario_excluido,
    dui_excluido,
  } = req.body;

  const connection = await req.db.getConnection();
  try {
    await connection.beginTransaction();

    // Insertar en la tabla 'proveedores'
    const [result] = await connection.query(
      "INSERT INTO proveedores (nombre_comercial, correo, direccion, telefono, tipo_proveedor, rubro, giro, correspondencia) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
      [nombre_comercial, correo, direccion, telefono, tipo_proveedor, rubro, giro, correspondencia]
    );

    const proveedorId = result.insertId;
    console.log("Proveedor creado con ID:", proveedorId);

    if (tipo_proveedor === "natural") {
      console.log("Insertando proveedor natural...");
      // Insertar en 'proveedores_naturales'
      await connection.query(
        "INSERT INTO proveedores_naturales (proveedor_id, nombre_propietario, dui, nrc) VALUES (?, ?, ?, ?)",
        [proveedorId, nombre_propietario, dui, nrc_natural]
      );
      console.log("Proveedor natural insertado correctamente.");
    } else if (tipo_proveedor === "juridico") {
      console.log("Insertando proveedor jurídico...");
      // Insertar en 'proveedores_juridicos'
      await connection.query(
        "INSERT INTO proveedores_juridicos (proveedor_id, razon_social, nit, nrc, nombres_representante, apellidos_representante, direccion_representante, telefono_representante, dui_representante, nit_representante, correo_representante) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
        [proveedorId, razon_social, nit, nrc_juridico, nombres_representante, apellidos_representante, direccion_representante, telefono_representante, dui_representante, nit_representante, correo_representante]
      );
      console.log("Proveedor jurídico insertado correctamente.");
    } else if (tipo_proveedor === "sujeto excluido") {
      console.log("Insertando proveedor excluido...");
      // Insertar en 'proveedores_excluidos'
      await connection.query(
        "INSERT INTO proveedores_excluidos (proveedor_id, nombre_propietario, dui) VALUES (?, ?, ?)",
        [proveedorId, nombre_propietario_excluido, dui_excluido]
      );
      console.log("Proveedor excluido insertado correctamente.");
    } else {
      throw new Error("Tipo de proveedor inválido");
    }

    await connection.commit();
    console.log("Transacción completada exitosamente.");

    res.status(201).json({
      message: "Proveedor creado exitosamente",
      id: proveedorId,
    });
  } catch (err) {
    await connection.rollback();
    console.error("Error en la transacción:", err.message);
    res.status(500).json({ message: "Error interno del servidor", error: err.message });
  } finally {
    connection.release();
    console.log("Conexión liberada.");
  }
});


// PUT: Actualizar proveedor por ID
router.put('/proveedores/:id', async (req, res) => {
  const { id } = req.params;
  const { 
    nombre_comercial, 
    correo, 
    direccion, 
    telefono, 
    tipo_proveedor,
    nombre_propietario,
    dui,
    razon_social,
    nit,
    nrc,
    giro,
    correspondencia,
    rubro,  // Nuevo campo
    nrc_juridico, // Nuevo campo para jurídico
    nombres_representante, 
    apellidos_representante, 
    direccion_representante, 
    telefono_representante, 
    dui_representante, 
    nit_representante, 
    correo_representante,
  } = req.body;

  try {
    // Actualizar datos generales del proveedor (común para todos los tipos)
    await req.db.query(
      `UPDATE proveedores SET 
        nombre_comercial = ?, 
        direccion = ?, 
        telefono = ?, 
        correo = ?, 
        giro = ?, 
        correspondencia = ?, 
        rubro = ? 
      WHERE id = ?`,
      [nombre_comercial, direccion, telefono, correo, giro, correspondencia, rubro, id]
    );

    // Verificar el tipo de proveedor y realizar la acción correspondiente
    if (tipo_proveedor === 'Natural') {
      // Verificar si ya existe un registro en proveedores_naturales
      const [existingNatural] = await req.db.query(
        "SELECT id FROM proveedores_naturales WHERE proveedor_id = ?",
        [id]
      );

      if (existingNatural.length > 0) {
        // Si existe, actualizar
        await req.db.query(
          `UPDATE proveedores_naturales SET 
            nombre_propietario = ?, 
            dui = ?, 
            nrc = ? 
          WHERE proveedor_id = ?`,
          [nombre_propietario, dui, nrc, id]
        );
      } else {
        // Si no existe, insertar
        await req.db.query(
          `INSERT INTO proveedores_naturales (proveedor_id, nombre_propietario, dui, nrc) 
            VALUES (?, ?, ?, ?)`,
          [id, nombre_propietario, dui, nrc]
        );
      }
    } else if (tipo_proveedor === 'Jurídico') {
      // Verificar si ya existe un registro en proveedores_juridicos
      const [existingJuridico] = await req.db.query(
        "SELECT id FROM proveedores_juridicos WHERE proveedor_id = ?",
        [id]
      );

      if (existingJuridico.length > 0) {
        // Si existe, actualizar
        await req.db.query(
          `UPDATE proveedores_juridicos SET 
            razon_social = ?, 
            nit = ?, 
            nrc = ?, 
            nombres_representante = ?, 
            apellidos_representante = ?, 
            direccion_representante = ?, 
            telefono_representante = ?, 
            dui_representante = ?, 
            nit_representante = ?, 
            correo_representante = ? 
          WHERE proveedor_id = ?`,
          [razon_social, nit, nrc_juridico, nombres_representante, apellidos_representante, direccion_representante, telefono_representante, dui_representante, nit_representante, correo_representante, id]
        );
      } else {
        // Si no existe, insertar
        await req.db.query(
          `INSERT INTO proveedores_juridicos (proveedor_id, razon_social, nit, nrc, nombres_representante, apellidos_representante, direccion_representante, telefono_representante, dui_representante, nit_representante, correo_representante) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
          [id, razon_social, nit, nrc_juridico, nombres_representante, apellidos_representante, direccion_representante, telefono_representante, dui_representante, nit_representante, correo_representante]
        );
      }
    } else if (tipo_proveedor === 'Sujeto Excluido') {
      // Verificar si ya existe un registro en proveedores_excluidos
      const [existingExcluido] = await req.db.query(
        "SELECT id FROM proveedores_excluidos WHERE proveedor_id = ?",
        [id]
      );

      if (existingExcluido.length > 0) {
        // Si existe, actualizar
        await req.db.query(
          `UPDATE proveedores_excluidos SET 
            nombre_propietario = ?, 
            dui = ? 
          WHERE proveedor_id = ?`,
          [nombre_propietario, dui, id]
        );
      } else {
        // Si no existe, insertar
        await req.db.query(
          `INSERT INTO proveedores_excluidos (proveedor_id, nombre_propietario, dui) 
            VALUES (?, ?, ?)`,
          [id, nombre_propietario, dui]
        );
      }
    }

    res.json({ message: "Proveedor actualizado correctamente" });
  } catch (err) {
    res.status(500).json({
      message: "Error al actualizar proveedor",
      error: err.message,
    });
  }
});


// GET: Obtener proveedor por ID
router.get("/proveedores/:id", async (req, res) => {
  try {
    const { id } = req.params;

    const query = `
      SELECT * FROM proveedores WHERE id = ?;
    `;
    const [results] = await req.db.query(query, [id]);

    if (results.length === 0) {
      return res.status(404).json({ message: "Proveedor no encontrado" });
    }

    res.json(results[0]);
  } catch (err) {
    res.status(500).json({
      message: "Error al obtener el proveedor",
      error: err.message,
    });
  }
});


// DELETE: Eliminar proveedor por ID
router.delete("/proveedores/:id", async (req, res) => {
  const proveedorId = req.params.id;
  const connection = await req.db.getConnection();

  try {
    await connection.beginTransaction(); // Iniciar transacción

    // Verificar el tipo de proveedor (natural, jurídico o excluido)
    const [result] = await connection.query(
      "SELECT tipo_proveedor FROM proveedores WHERE id = ?",
      [proveedorId]
    );

    if (result.length === 0) {
      throw new Error("Proveedor no encontrado");
    }

    const tipoProveedor = result[0].tipo_proveedor;

    // Eliminar del proveedor dependiendo del tipo
    if (tipoProveedor === "Natural") {
      // Eliminar de la tabla proveedores_naturales si es natural
      await connection.query(
        "DELETE FROM proveedores_naturales WHERE proveedor_id = ?",
        [proveedorId]
      );
    } else if (tipoProveedor === "Jurídico") {
      // Eliminar de la tabla proveedores_juridicos si es jurídico
      await connection.query(
        "DELETE FROM proveedores_juridicos WHERE proveedor_id = ?",
        [proveedorId]
      );
    } else if (tipoProveedor === "Sujeto Excluido") {
      // Eliminar de la tabla proveedores_excluidos si es excluido
      await connection.query(
        "DELETE FROM proveedores_excluidos WHERE proveedor_id = ?",
        [proveedorId]
      );
    }

    // Finalmente eliminar de la tabla principal proveedores
    await connection.query(
      "DELETE FROM proveedores WHERE id = ?",
      [proveedorId]
    );

    await connection.commit(); // Confirmar eliminación

    res.status(200).json({ message: "Proveedor eliminado exitosamente" });
  } catch (err) {
    await connection.rollback(); // Revertir cambios en caso de error
    res.status(500).json({ message: "Error eliminando el proveedor", error: err.message });
  } finally {
    connection.release();
  }
});


/* ==================== RUTAS DE CATALOGO ==================== */

// GET y POST: Obtener todos los productos del catálogo y crear un nuevo producto
router.route("/catalogo")
  .get(async (req, res) => {
    try {
      // Obtener el parámetro de búsqueda, si existe
      const search = req.query.search ? req.query.search : '';

      // Consulta SQL con filtro de búsqueda
      const [results] = await req.db.query(`
        SELECT c.*, p.nombre AS presentacion_nombre, m.nombre AS marca_nombre, cat.nombre AS categoria_nombre
        FROM catalogo c
        LEFT JOIN presentacion p ON c.presentacion_id = p.id
        LEFT JOIN marca m ON c.marca_id = m.id
        LEFT JOIN categoria cat ON c.categoria_id = cat.id
        WHERE c.nombre_producto LIKE ? OR c.codigo LIKE ?  -- Filtrado por nombre o código
      `, [`%${search}%`, `%${search}%`]); // % es para búsqueda parcial

      res.json(results);
    } catch (err) {
      res.status(500).json({ message: "Error al obtener productos del catálogo", error: err.message });
    }
  })
  .post(upload.single("imagen"), async (req, res) => {
    console.log(req.file); // Verifica si la imagen se está recibiendo
    try {
      const { nombre_producto, codigo, presentacion_id, marca_id, categoria_id, descripcion } = req.body;
      const imagen = req.file ? req.file.filename : null; // Obtener el nombre del archivo subido
  
      const [result] = await req.db.query("INSERT INTO catalogo SET ?", {
        nombre_producto,
        codigo,
        presentacion_id,
        marca_id,
        categoria_id,
        descripcion,
        imagen,
      });
  
      res.status(201).json({
        message: "Producto creado",
        id: result.insertId,
      });
    } catch (err) {
      res.status(500).json({ message: "Error al crear producto", error: err.message });
    }
  });


// GET: Obtener producto por ID
router.get("/catalogo/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const [results] = await req.db.query(`
      SELECT c.*, p.nombre AS presentacion_nombre, m.nombre AS marca_nombre, cat.nombre AS categoria_nombre
      FROM catalogo c
      LEFT JOIN presentacion p ON c.presentacion_id = p.id
      LEFT JOIN marca m ON c.marca_id = m.id
      LEFT JOIN categoria cat ON c.categoria_id = cat.id
      WHERE c.id = ?
    `, [id]);
    
    if (results.length === 0) {
      return res.status(404).json({ message: "Producto no encontrado" });
    }
    res.json(results[0]);
  } catch (err) {
    res.status(500).json({ message: "Error al obtener producto", error: err.message });
  }
});

// PUT: Actualizar producto por ID
router.put("/catalogo/:id", upload.single("imagen"), async (req, res) => {
  try {
    const { id } = req.params;
    const { nombre_producto, codigo, presentacion_id, marca_id, categoria_id, descripcion } = req.body;
    
    // Obtener la imagen actual antes de actualizar
    const [rows] = await req.db.query("SELECT imagen FROM catalogo WHERE id = ?", [id]);
    if (rows.length === 0) {
      return res.status(404).json({ message: "Producto no encontrado" });
    }

    // Mantener la imagen actual si no se sube una nueva
    const imagen = req.file ? req.file.filename : rows[0].imagen;

    await req.db.query(
      "UPDATE catalogo SET nombre_producto = ?, codigo = ?, presentacion_id = ?, marca_id = ?, categoria_id = ?, descripcion = ?, imagen = ? WHERE id = ?",
      [nombre_producto, codigo, presentacion_id, marca_id, categoria_id, descripcion, imagen, id] 
    );

    res.json({ message: "Producto actualizado correctamente" });
  } catch (err) {
    res.status(500).json({ message: "Error al actualizar producto", error: err.message });
  }
});


// DELETE: Eliminar producto por ID
router.delete("/catalogo/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const [result] = await req.db.query("DELETE FROM catalogo WHERE id = ?", [id]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Producto no encontrado" });
    }
    res.json({ message: "Producto eliminado exitosamente" });
  } catch (err) {
    res.status(500).json({ message: "Error al eliminar producto", error: err.message });
  }
});


/* ==================== RUTAS DE PRESENTACION BASICA ==================== */

// GET y POST: Obtener todas las presentacion y crear una nueva
router.route("/presentacion")
  .get(async (req, res) => {
    try {
      const [results] = await req.db.query("SELECT * FROM presentacion");
      res.json(results);
    } catch (err) {
      res.status(500).json({ message: "Error al obtener presentacion", error: err.message });
    }
  })
  .post(async (req, res) => {
    try {
      // Aquí podrías agregar validación de campos si lo requieres
      const [result] = await req.db.query("INSERT INTO presentacion SET ?", [req.body]);
      res.status(201).json({
        message: "Presentacion creada",
        id: result.insertId,
      });
    } catch (err) {
      res.status(500).json({ message: "Error al crear presentacion", error: err.message });
    }
  });

// GET: Obtener presentacion por ID
router.get("/presentacion/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const [results] = await req.db.query("SELECT * FROM presentacion WHERE id = ?", [id]);
    if (results.length === 0) {
      return res.status(404).json({ message: "Presentacion no encontrada" });
    }
    res.json(results[0]);
  } catch (err) {
    res.status(500).json({ message: "Error al obtener sucursal", error: err.message });
  }
});

// PUT: Actualizar presentacion por ID
router.put("/presentacion/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { nombre, descripcion } = req.body;
    const [rows] = await req.db.query("SELECT * FROM presentacion WHERE id = ?", [id]);
    if (rows.length === 0) {
      return res.status(404).json({ message: "Presentacion no encontrada" });
    }
    await req.db.query(
      "UPDATE presentacion SET  nombre = ?, descripcion = ? WHERE id = ?",
      [ nombre, descripcion, id]
    );
    res.json({ message: "Presentacion actualizada correctamente" });
  } catch (err) {
    res.status(500).json({ message: "Error al actualizar la presentacion", error: err.message });
  }
});

// DELETE: Eliminar presentacion por ID
router.delete("/presentacion/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const [result] = await req.db.query("DELETE FROM presentacion WHERE id = ?", [id]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Presentacion no encontrada" });
    }
    res.json({ message: "Presentacion eliminada exitosamente" });
  } catch (err) {
    res.status(500).json({ message: "Error al eliminar presentacion", error: err.message });
  }
});



/* ==================== RUTAS DE MARCA ==================== */

// GET y POST: Obtener todas las MARCA y crear una nueva
router.route("/marca")
  .get(async (req, res) => {
    try {
      const [results] = await req.db.query("SELECT * FROM marca");
      res.json(results);
    } catch (err) {
      res.status(500).json({ message: "Error al obtener marca", error: err.message });
    }
  })
  .post(async (req, res) => {
    try {
      // Aquí podrías agregar validación de campos si lo requieres
      const [result] = await req.db.query("INSERT INTO marca SET ?", [req.body]);
      res.status(201).json({
        message: "Marca creada",
        id: result.insertId,
      });
    } catch (err) {
      res.status(500).json({ message: "Error al crear marca", error: err.message });
    }
  });

// GET: Obtener presentacion por ID
router.get("/marca/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const [results] = await req.db.query("SELECT * FROM marca WHERE id = ?", [id]);
    if (results.length === 0) {
      return res.status(404).json({ message: "Marca no encontrada" });
    }
    res.json(results[0]);
  } catch (err) {
    res.status(500).json({ message: "Error al obtener marca", error: err.message });
  }
});

// PUT: Actualizar marca por ID
router.put("/marca/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { nombre, descripcion } = req.body;
    const [rows] = await req.db.query("SELECT * FROM marca WHERE id = ?", [id]);
    if (rows.length === 0) {
      return res.status(404).json({ message: "marca no encontrada" });
    }
    await req.db.query(
      "UPDATE marca SET  nombre = ?, descripcion = ? WHERE id = ?",
      [ nombre, descripcion, id]
    );
    res.json({ message: "marca actualizada correctamente" });
  } catch (err) {
    res.status(500).json({ message: "Error al actualizar la marca", error: err.message });
  }
});

// DELETE: Eliminar marca por ID
router.delete("/marca/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const [result] = await req.db.query("DELETE FROM marca WHERE id = ?", [id]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Marca no encontrada" });
    }
    res.json({ message: "Marca eliminada exitosamente" });
  } catch (err) {
    res.status(500).json({ message: "Error al eliminar marca", error: err.message });
  }
});

module.exports = router;
