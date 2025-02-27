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
          i.descripcion,
          i.numero_motor,
          i.numero_chasis,
          c.nombre AS categoria,
          s.nombre AS sucursal,
          p.nombre AS proveedores,
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

// GET: Obtener producto por ID
router.get("/inventario/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const [results] = await req.db.query("SELECT * FROM inventario WHERE id = ?", [id]);
    if (results.length === 0) {
      return res.status(404).json({ message: "Producto no encontrado" });
    }
    res.json(results[0]);
  } catch (err) {
    res.status(500).json({
      message: "Error al obtener producto",
      error: err.message,
    });
  }
});

// PUT: Actualizar producto por ID e insertar en historial
router.put("/inventario/:id", async (req, res) => {
  const { id } = req.params;
  const { nombre, descripcion, precio_venta, stock_existencia, motivo, imagen } = req.body;
  const connection = await req.db.getConnection();
  try {
    await connection.beginTransaction();
    // Verificar si el producto existe
    const [rows] = await connection.query("SELECT * FROM inventario WHERE id = ?", [id]);
    if (rows.length === 0) {
      await connection.rollback();
      return res.status(404).json({ message: "Producto no encontrado" });
    }
    const { codigo } = rows[0];
    // Actualizar producto
    await connection.query(
      `UPDATE inventario SET 
        nombre = ?, 
        descripcion = ?, 
        precio_venta = ?, 
        stock_existencia = ?, 
        imagen = ? 
      WHERE id = ?`,
      [nombre, descripcion, precio_venta, stock_existencia, imagen, id]
    );
    // Insertar registro en historial
    await connection.query(
      `INSERT INTO historial_ajustes (codigo, nombre, descripcion, precio, stock, motivo) 
       VALUES (?, ?, ?, ?, ?, ?)`,
      [codigo, nombre, descripcion, precio_venta, stock_existencia, motivo]
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

// POST: Insertar un nuevo producto en inventario
router.post("/inventario", async (req, res) => {
  try {
    const {
      codigo,
      imagen,
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

    const [result] = await req.db.query(
      `INSERT INTO inventario 
      (codigo, imagen, nombre, descripcion, numero_motor, numero_chasis, costo, credito, 
      precio_venta, stock_existencia, stock_minimo, fecha_ingreso, fecha_reingreso, 
      numero_poliza, numero_lote, categoria_id, sucursal_id, proveedor_id) 
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        codigo,
        imagen,
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
      ]
    );

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
router.get("/proveedores", async (req, res) => {
  try {
    const [results] = await req.db.query("SELECT * FROM proveedores");
    res.json(results);
  } catch (err) {
    res.status(500).json({ message: "Error al obtener proveedores", error: err.message });
  }
});

// POST: Crear nuevo proveedor
router.post("/proveedores", async (req, res) => {
  try {
    const {
      nombre,
      direccion,
      contacto,
      correo,
      clasificacion,
      tipo_persona,
      numero_factura_compra = "0",
      ley_tributaria,
    } = req.body;
    // Puedes agregar validaciones de campos aquí si lo necesitas
    const [result] = await req.db.query(
      "INSERT INTO proveedores (nombre, direccion, contacto, correo, clasificacion, tipo_persona, numero_factura_compra, ley_tributaria) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
      [nombre, direccion, contacto, correo, clasificacion, tipo_persona, numero_factura_compra, ley_tributaria]
    );
    res.status(201).json({
      message: "Proveedor creado exitosamente",
      id: result.insertId,
    });
  } catch (err) {
    res.status(500).json({ message: "Error interno del servidor", error: err.message });
  }
});

// PUT: Actualizar proveedor por ID
router.put("/proveedores/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const {
      nombre,
      direccion,
      contacto,
      correo,
      clasificacion,
      tipo_persona,
      numero_factura_compra,
      ley_tributaria,
    } = req.body;
    await req.db.query(
      `UPDATE proveedores SET 
        nombre = ?, 
        direccion = ?, 
        contacto = ?, 
        correo = ?, 
        clasificacion = ?, 
        tipo_persona = ?, 
        numero_factura_compra = ?, 
        ley_tributaria = ? 
      WHERE id = ?`,
      [nombre, direccion, contacto, correo, clasificacion, tipo_persona, numero_factura_compra, ley_tributaria, id]
    );
    res.json({ message: "Proveedor actualizado correctamente" });
  } catch (err) {
    res.status(500).json({ message: "Error al actualizar proveedor", error: err.message });
  }
});

// GET: Obtener proveedor por ID
router.get("/proveedores/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const [results] = await req.db.query("SELECT * FROM proveedores WHERE id = ?", [id]);
    if (results.length === 0) {
      return res.status(404).json({ message: "Proveedor no encontrado" });
    }
    res.json(results[0]);
  } catch (err) {
    res.status(500).json({ message: "Error al obtener el proveedor", error: err.message });
  }
});

// DELETE: Eliminar proveedor por ID
router.delete("/proveedores/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const [result] = await req.db.query("DELETE FROM proveedores WHERE id = ?", [id]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Proveedor no encontrado" });
    }
    res.json({ message: "Proveedor eliminado exitosamente" });
  } catch (err) {
    res.status(500).json({ message: "Error al eliminar proveedor", error: err.message });
  }
});

module.exports = router;
