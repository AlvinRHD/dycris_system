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

// GET: Obtener inventario (resumido o detallado)
router.get("/inventario", async (req, res) => {
  try {
    const tipo = req.query.tipo;
    let query = "SELECT * FROM inventario";

    if (tipo === "detallado") {
      query = `
        SELECT 
          i.id,
          i.codigo,
          i.imagen,
          i.nombre AS nombre,
          i.descripcion AS descripcion,
          i.numero_motor,
          i.numero_chasis,
          c.nombre AS categoria,
          s.nombre AS sucursal,
          p.nombre_comercial AS proveedores,
          i.costo,
          i.credito,
          i.precio_venta,
          i.stock_existencia,
          i.stock_minimo,
          i.fecha_ingreso,
          i.fecha_reingreso,
          i.numero_poliza,
          i.numero_lote
        FROM inventario i
        LEFT JOIN categoria c ON i.categoria_id = c.id
        LEFT JOIN sucursal s ON i.sucursal_id = s.id
        LEFT JOIN proveedores p ON i.proveedor_id = p.id;
      `;
    } else if (tipo === "resumido") {
      query = `
        SELECT 
          i.nombre AS nombre,
          i.descripcion AS descripcion,
          i.costo,
          i.precio_venta,
          c.nombre AS categoria,
          s.nombre AS sucursal,
          p.nombre_comercial AS proveedores,
          SUM(i.stock_existencia) AS stock_total
        FROM inventario i
        LEFT JOIN categoria c ON i.categoria_id = c.id
        LEFT JOIN sucursal s ON i.sucursal_id = s.id
        LEFT JOIN proveedores p ON i.proveedor_id = p.id
        GROUP BY i.nombre, i.descripcion, c.nombre, s.nombre, p.nombre_comercial, i.costo, i.precio_venta;
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
        numero_poliza,
        numero_lote,
        imagen,
        nombre,
        descripcion,
        stock_existencia
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
}) 

// PUT: Actualizar productos por nombre y descripción e insertar en historial
router.put("/inventario/edit", async (req, res) => {
  const { nombre, descripcion, precio_venta,  motivo, imagen } = req.body;
  const connection = await req.db.getConnection();
  try {
    await connection.beginTransaction();
    
    // Verificar si existen productos con el mismo nombre y descripción
    const [rows] = await connection.query("SELECT * FROM inventario WHERE nombre = ? AND descripcion = ?", [nombre, descripcion]);
    if (rows.length === 0) {
      await connection.rollback();
      return res.status(404).json({ message: "No se encontraron productos con el nombre y descripción proporcionados" });
    }

    // Actualizar todos los productos que coinciden
    const codigo = rows[0].codigo; // Suponiendo que todos los productos tienen el mismo código
    await connection.query(
      `UPDATE inventario SET 
        precio_venta = ?, 
        imagen = ? 
      WHERE nombre = ? AND descripcion = ?`,
      [precio_venta,  imagen, nombre, descripcion]
    );

    // Insertar registro en historial para cada producto actualizado
    for (const row of rows) {
      await connection.query(
        `INSERT INTO historial_ajustes (codigo, nombre, descripcion, precio, motivo) 
         VALUES (?, ?, ?, ?, ?)`,
        [row.codigo, nombre, descripcion, precio_venta,  motivo]
      );
    }

    await connection.commit();
    res.json({ message: "Productos y historial actualizados correctamente" });
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



// POST: Insertar un nuevo producto en inventario
router.post("/inventario", async (req, res) => {
  try {
    const {
      codigo,
      imagen, // Este campo es opcional
      nombre,
      descripcion,
      numero_motor,
      numero_chasis,
      costo,
      credito,
      precio_venta,
      stock_existencia,
      stock_minimo,
      fecha_ingreso,
      fecha_reingreso,
      numero_poliza,
      numero_lote,
      categoria_id,
      sucursal_id,
      proveedor_id,
    } = req.body;

    // Validar campos obligatorios
    if (!codigo || !nombre || !categoria_id || !sucursal_id || !proveedor_id) {
      return res.status(400).json({
        message: "Campos obligatorios faltantes: código, nombre, categoría, sucursal o proveedor.",
      });
    }

    // Verificar que no exista un producto con el mismo código o número de motor
    const [existingProduct] = await req.db.query(
      "SELECT * FROM inventario WHERE codigo = ? OR numero_motor = ?",
      [codigo, numero_motor]
    );
    if (existingProduct.length > 0) {
      return res.status(409).json({
        message: "El producto con ese código o número de motor ya existe.",
      });
    }

    // Construir la consulta de inserción
    const query = `
      INSERT INTO inventario 
      (codigo, ${imagen ? 'imagen,' : ''} nombre, descripcion, numero_motor, numero_chasis, costo, credito, 
      precio_venta, stock_existencia, stock_minimo, fecha_ingreso, fecha_reingreso, 
      numero_poliza, numero_lote, categoria_id, sucursal_id, proveedor_id) 
      VALUES (?, ${imagen ? '?, ' : ''} ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`;

    // Crear un array de valores a insertar
    const values = [
      codigo,
      ...(imagen ? [imagen] : []), // Agregar imagen solo si está presente
      nombre,
      descripcion,
      numero_motor,
      numero_chasis,
      costo,
      credito,
      precio_venta,
      stock_existencia,
      stock_minimo,
      fecha_ingreso,
      fecha_reingreso,
      numero_poliza,
      numero_lote,
      categoria_id,
      sucursal_id,
      proveedor_id,
    ];

    const [result] = await req.db.query(query, values);

    res.status(201).json({
      message: "Producto insertado exitosamente",
      id: result.insertId,
    });
  } catch (err) {
    res.status(500).json({ message: "Error interno del servidor", error: err.message });
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

// POST: Endpoint para cargar imágenes
router.post("/upload", upload.single("file"), (req, res) => {
  if (!req.file) {
    return res.status(400).send("No se ha cargado ninguna imagen");
  }
  res.status(200).json({
    imageUrl: `/uploads/${req.file.filename}`,
  });
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
    const { codigo, nombre, pais, departamento, ciudad, estado } = req.body;
    const [rows] = await req.db.query("SELECT * FROM sucursal WHERE id = ?", [id]);
    if (rows.length === 0) {
      return res.status(404).json({ message: "Sucursal no encontrada" });
    }
    await req.db.query(
      "UPDATE sucursal SET codigo = ?, nombre = ?, pais = ?, departamento = ?, ciudad = ?, estado = ? WHERE id = ?",
      [codigo, nombre, pais, departamento, ciudad, estado, id]
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
// GET: Obtener todos los proveedores
router.get("/proveedores", async (req, res) => {
  try {
    const query = `
      SELECT 
        p.id,
        p.nombre_comercial, 
        p.correo, 
        p.direccion, 
        p.telefono, 
        pn.nombre_propietario, 
        pn.dui,
        pj.razon_social,
        pj.nit,
        pj.nrc,
        pj.giro,
        pj.correspondencia,
        p.tipo_proveedor
      FROM proveedores p
      LEFT JOIN proveedores_naturales pn ON p.id = pn.proveedor_id
      LEFT JOIN proveedores_juridicos pj ON p.id = pj.proveedor_id;
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

// POST: Crear nuevo proveedor
router.post("/proveedores", async (req, res) => {
  const {
    nombre_comercial,
    correo,
    direccion,
    telefono,
    tipo_proveedor, // 'natural' o 'juridico'
    nombre_propietario,
    dui,
    razon_social,
    nit,
    nrc,
    giro,
    correspondencia
  } = req.body;

  const connection = await req.db.getConnection(); // Obtener conexión para transacción
  try {
    await connection.beginTransaction(); // Iniciar transacción

    // Insertar en la tabla 'proveedores' incluyendo el tipo de proveedor
    const [result] = await connection.query(
      "INSERT INTO proveedores (nombre_comercial, correo, direccion, telefono, tipo_proveedor) VALUES (?, ?, ?, ?, ?)",
      [nombre_comercial, correo, direccion, telefono, tipo_proveedor]
    );

    const proveedorId = result.insertId; // Obtener el ID insertado

    if (tipo_proveedor === "natural") {
      // Insertar en la tabla 'proveedores_naturales'
      await connection.query(
        "INSERT INTO proveedores_naturales (proveedor_id, nombre_propietario, dui) VALUES (?, ?, ?)",
        [proveedorId, nombre_propietario, dui]
      );
    } else if (tipo_proveedor === "juridico") {
      // Insertar en la tabla 'proveedores_juridicos'
      await connection.query(
        "INSERT INTO proveedores_juridicos (proveedor_id, razon_social, nit, nrc, giro, correspondencia) VALUES (?, ?, ?, ?, ?, ?)",
        [proveedorId, razon_social, nit, nrc, giro, correspondencia]
      );
    } else {
      throw new Error("Tipo de proveedor inválido");
    }

    await connection.commit(); // Confirmar transacción

    res.status(201).json({
      message: "Proveedor creado exitosamente",
      id: proveedorId,
    });
  } catch (err) {
    await connection.rollback(); // Revertir cambios en caso de error
    res
      .status(500)
      .json({ message: "Error interno del servidor", error: err.message });
  } finally {
    connection.release(); // Liberar conexión
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
    correspondencia
  } = req.body;

  try {
    // Actualizar datos generales del proveedor (común para ambos tipos)
    await req.db.query(
      `UPDATE proveedores SET 
        nombre_comercial = ?, 
        direccion = ?, 
        telefono = ?, 
        correo = ?
      WHERE id = ?`,
      [nombre_comercial, direccion, telefono, correo, id]
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
              dui = ?
            WHERE proveedor_id = ?`,
          [nombre_propietario, dui, id]
        );
      } else {
        // Si no existe, insertar
        await req.db.query(
          `INSERT INTO proveedores_naturales (proveedor_id, nombre_propietario, dui) 
            VALUES (?, ?, ?)`,
          [id, nombre_propietario, dui]
        );
      }
    } else if (tipo_proveedor === 'Juridico') {
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
              giro = ?, 
              correspondencia = ?
            WHERE proveedor_id = ?`,
          [razon_social, nit, nrc, giro, correspondencia, id]
        );
      } else {
        // Si no existe, insertar
        await req.db.query(
          `INSERT INTO proveedores_juridicos (proveedor_id, razon_social, nit, nrc, giro, correspondencia) 
            VALUES (?, ?, ?, ?, ?, ?)`,
          [id, razon_social, nit, nrc, giro, correspondencia]
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
// DELETE: Eliminar proveedor por ID
router.delete("/proveedores/:id", async (req, res) => {
  const proveedorId = req.params.id;
  const connection = await req.db.getConnection();

  try {
    await connection.beginTransaction(); // Iniciar transacción

    // Verificar el tipo de proveedor (natural o jurídico)
    const [result] = await connection.query(
      "SELECT tipo_proveedor FROM proveedores WHERE id = ?",
      [proveedorId]
    );

    if (result.length === 0) {
      throw new Error("Proveedor no encontrado");
    }

    const tipoProveedor = result[0].tipo_proveedor;

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


module.exports = router;
