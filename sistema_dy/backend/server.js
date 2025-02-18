// Importación de módulos
const express = require("express");
const mysql = require("mysql2/promise"); // MySQL con soporte para promesas
const cors = require("cors"); // Manejo de CORS
const bcrypt = require("bcryptjs"); // Encriptación de contraseñas
require("dotenv").config(); // Variables de entorno
const multer = require("multer"); // Subida de archivos
const path = require("path");
const fs = require("fs");


const app = express(); // Inicialización de Express

// Configuración de middlewares

app.use(cors()); // Habilita CORS para todas las 
app.use(express.json()); // Parsea cuerpos de solicitud JSON
// Configuración de las rutas estáticas para las imágenes
app.use("/uploads", express.static(path.join(__dirname, "uploads")));

// Crear directorio de uploads si no existe
const uploadsDir = path.join(__dirname, "uploads");
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}
// Configuración de Multer para almacenar archivos
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, uploadsDir); // Usa la variable uploadsDir
  },
  filename: function (req, file, cb) {
    cb(null, Date.now() + path.extname(file.originalname)); // Usa un nombre único para evitar conflictos
  },
});

const upload = multer({ storage: storage });



// Configuración de la base de datos usando variables de entorno
const dbConfig = {
  host: process.env.DB_HOST || "localhost", // Host de la DB
  user: process.env.DB_USER || "root", // Usuario de la DB
  password: process.env.DB_PASSWORD || "", // Contraseña
  database: process.env.DB_NAME || "sistema_dycris", // Nombre DB

  waitForConnections: true,
  connectionLimit: 10, // Máximo de conexiones simultáneas
  queueLimit: 0
};

const pool = mysql.createPool(dbConfig); // Pool de conexiones

// Middleware que inyecta la conexión a DB en cada request
app.use((req, res, next) => {
  req.db = pool;
  next();
});

// Verificación de conexión a la base de datos
pool.getConnection()
  .then(conn => {
    console.log("Conectado a MySQL");
    conn.release(); // Libera la conexión de prueba
  })
  .catch(err => {
    console.error("Error de conexión:", err.message);
  });





////////////inventario////////////////////
//Apis de el inventario:
//Obtener inventario
//APIS INVENTARIO
//Obtener inventario
app.get("/api/inventario", async (req, res) => {
  try {
    const tipo = req.query.tipo;

    let query = "SELECT * FROM inventario";

    if (tipo === "resumido") {
      query = "SELECT * FROM inventario";
    } else if (tipo === "detallado") {
      query = `
        SELECT 
    i.id,
    i.codigo,
    i.imagen,
    i.nombre AS inventario,
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
    handleError(res, 500, "Error al obtener inventario", err);
  }
});

// GET: Obtener producto por ID
app.get("/api/inventario/:id", async (req, res) => {
  try {
    const { id } = req.params; // ID del producto
    const [results] = await req.db.query(
      "SELECT * FROM inventario WHERE id = ?",
      [id]
    );

    if (results.length === 0) {
      return res.status(404).json({ message: "Producto no encontrado" });
    }

    res.json(results[0]); // Retorna el primer resultado (producto encontrado)
  } catch (err) {
    handleError(res, 500, "Error al obtener producto", err);
  }
});

app.put("/api/inventario/:id", async (req, res) => {
  const { id } = req.params;
  const {
    nombre,
    descripcion,
    precio_venta,
    stock_existencia,
    motivo,
    imagen,
  } = req.body;
  console.log("ID del producto:", id);
  console.log("Cuerpo de la solicitud:", req.body);

  const connection = await req.db.getConnection();

  try {
    await connection.beginTransaction();

    // Verificar si el producto existe
    const [rows] = await connection.query(
      "SELECT * FROM inventario WHERE id = ?",
      [id]
    );
    if (rows.length === 0) {
      await connection.rollback();
      return res.status(404).json({ message: "Producto no encontrado" });
    }

    const { codigo } = rows[0]; // Obtener el código del producto

    // Actualizar el producto en inventario, incluyendo la imagen
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

    // Registrar el ajuste en el historial
    await connection.query(
      `INSERT INTO historial_ajustes (codigo, nombre, descripcion, precio, stock, motivo) 
       VALUES (?, ?, ?, ?, ?, ?)`,
      [codigo, nombre, descripcion, precio_venta, stock_existencia, motivo]
    );

    await connection.commit(); // Confirmar la transacción
    res.json({ message: "Producto y historial actualizados correctamente" });
  } catch (err) {
    await connection.rollback(); // Revertir cambios en caso de error
    console.error("Error al actualizar producto y historial:", err);
    res
      .status(500)
      .json({ message: "Error al actualizar los datos", error: err.message });
  } finally {
    connection.release(); // Liberar conexión
  }
});

// Endpoint para cargar la imagen
app.post("/api/upload", upload.single("file"), (req, res) => {
  if (!req.file) {
    console.log("No se ha recibido el archivo");
    return res.status(400).send("No se ha cargado ninguna imagen");
  }

  console.log("Archivo recibido:", req.file);
  console.log(
    "Ruta donde se guardará:",
    path.join(uploadsDir, req.file.filename)
  );

  res.status(200).json({
    imageUrl: `/uploads/${req.file.filename}`,
  });
});

// DELETE: Eliminar producto por id
app.delete("/api/inventario/:id", async (req, res) => {
  try {
    const { id } = req.params; // Usar el parámetro id
    const [result] = await req.db.query(
      "DELETE FROM inventario WHERE id = ?",
      [id] // Usar id en la consulta SQL
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Producto no encontrado" });
    }

    res.json({ message: "Producto eliminado exitosamente" });
  } catch (err) {
    handleError(res, 500, "Error al eliminar producto", err);
  }
});

app.post("/api/inventario", async (req, res) => {
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
      categoria_id, // ID de la categoría
      sucursal_id, // ID de la sucursal
      proveedor_id, // ID del proveedor
    } = req.body;

    // Validar los campos requeridos
    if (!codigo || !nombre || !categoria_id || !sucursal_id || !proveedor_id) {
      return res
        .status(400)
        .json({
          message:
            "Campos obligatorios faltantes: código, nombre, categoría, sucursal o proveedor.",
        });
    }

    // Verificar si el producto ya existe
    const [existingProduct] = await req.db.query(
      "SELECT * FROM inventario WHERE codigo = ? OR numero_motor = ?",
      [codigo, numero_motor]
    );

    if (existingProduct.length > 0) {
      return res
        .status(409)
        .json({
          message: "El producto con ese código o número de motor ya existe.",
        });
    }

    // Insertar en la base de datos
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
    console.error("Error en el servidor:", err);
    res
      .status(500)
      .json({ message: "Error interno del servidor", error: err.message });
  }
});

// mostrar historial:
app.get("/api/historial_ajustes", async (req, res) => {
  try {
    const [results] = await pool.query("SELECT * FROM historial_ajustes");
    res.json(results);
  } catch (err) {
    handleError(res, 500, "Error al obtener el historial", err);
  }
});

// Obtener un historial específico por ID
app.get("/api/historial_ajustes/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const [results] = await pool.query(
      "SELECT * FROM historial_ajustes WHERE id = ?",
      [id]
    );

    if (results.length === 0) {
      return res.status(404).json({ message: "Historial no encontrado" });
    }

    res.json(results[0]);
  } catch (err) {
    handleError(res, 500, "Error al obtener historial", err);
}
}
);






/////////////sucursales////////////////////

// APIS SUCURSALES
app.route("/api/sucursal")
  .get(async (req, res) => {
    try {
      const [results] = await req.db.query("SELECT * FROM sucursal");
      res.json(results);
    } catch (err) {
      handleError(res, 500, "Error al obtener sucursales", err);
    }
  })
  .post(async (req, res) => {
    try {
      const requiredFields = [
        "codigo",
        "nombre",
        "pais",
        "departamento",
        "ciudad",
        "estado",
      ];
      validateFields(req.body, requiredFields); // Validación de campos

      const [result] = await req.db.query("INSERT INTO sucursal SET ?", [
        req.body,
      ]);

      res.status(201).json({
        message: "Sucursal creada",
        id: result.insertId, // Retorna ID de la nueva sucursal
      });
    } catch (err) {
      handleError(res, err.status || 500, err.message, err);
    }
  });

// GET: Obtener sucursal por ID
app.get("/api/sucursal/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const [results] = await req.db.query(
      "SELECT * FROM sucursal WHERE id = ?",
      [id]
    );

    if (results.length === 0) {
      return res.status(404).json({ message: "Sucursal no encontrada" });
    }

    res.json(results[0]);
  } catch (err) {
    handleError(res, 500, "Error al obtener sucursal", err);
  }
});

// PUT: Actualizar sucursal por ID
app.put("/api/sucursal/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { codigo, nombre, pais, departamento, ciudad, estado } = req.body;

    // Verificar si la sucursal existe
    const [rows] = await req.db.query("SELECT * FROM sucursal WHERE id = ?", [
      id,
    ]);
    if (rows.length === 0) {
      return res.status(404).json({ message: "Sucursal no encontrada" });
    }

    // Actualizar la sucursal
    await req.db.query(
      "UPDATE sucursal SET codigo = ?, nombre = ?, pais = ?, departamento = ?, ciudad = ?, estado = ? WHERE id = ?",
      [codigo, nombre, pais, departamento, ciudad, estado, id]
    );

    res.json({ message: "Sucursal actualizada correctamente" });
  } catch (err) {
    console.error("Error al actualizar sucursal:", err);
    res
      .status(500)
      .json({ message: "Error al actualizar la sucursal", error: err.message });
  }
});

// DELETE: Eliminar sucursal por ID
app.delete("/api/sucursal/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const [result] = await req.db.query("DELETE FROM sucursal WHERE id = ?", [
      id,
    ]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Sucursal no encontrada" });
    }

    res.json({ message: "Sucursal eliminada exitosamente" });
  } catch (err) {
    handleError(res, 500, "Error al eliminar sucursal", err);
  }
});



///categorias////
//api categoria

app.route("/api/categoria")
  .get(async (req, res) => {
    try {
      const [results] = await req.db.query("SELECT * FROM categoria");
      res.json(results);
    } catch (err) {
      handleError(res, 500, "Error al obtener categorias", err);
    }
  })
  .post(async (req, res) => {
    try {
      const requiredFields = ["nombre", "descripcion", "estado"];
      validateFields(req.body, requiredFields); // Validación de campos

      const [result] = await req.db.query("INSERT INTO categoria SET ?", [
        req.body,
      ]);

      res.status(201).json({
        message: "Categoria creada",
        id: result.insertId, // Retorna ID de la nueva categoria
      });
    } catch (err) {
      handleError(res, err.status || 500, err.message, err);
    }
  });

// GET: Obtener categoria por ID
app.get("/api/categoria/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const [results] = await req.db.query(
      "SELECT * FROM categoria WHERE id = ?",
      [id]
    );

    if (results.length === 0) {
      return res.status(404).json({ message: "Categoria no encontrada" });
    }

    res.json(results[0]);
  } catch (err) {
    handleError(res, 500, "Error al obtener Categoria", err);
  }
});

// PUT: Actualizar categoria por ID
app.put("/api/categoria/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { nombre, descripcion, fecha_creacion, estado } = req.body;

    // Verificar si la categoria existe
    const [rows] = await req.db.query("SELECT * FROM categoria WHERE id = ?", [
      id,
    ]);
    if (rows.length === 0) {
      return res.status(404).json({ message: "Categoria no encontrada" });
    }

    // Actualizar la categoria
    await req.db.query(
      "UPDATE categoria SET nombre = ?, descripcion = ?, fecha_creacion = ?, estado = ? WHERE id = ?",
      [nombre, descripcion, fecha_creacion, estado, id]
    );

    res.json({ message: "Categoria actualizada correctamente" });
  } catch (err) {
    console.error("Error al actualizar Categoria:", err);
    res.status(500).json({
      message: "Error al actualizar la categoria",
      error: err.message,
    });
  }
});

// DELETE: Eliminar sucursal por ID
app.delete("/api/categoria/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const [result] = await req.db.query("DELETE FROM categoria WHERE id = ?", [
      id,
    ]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "categoria no encontrada" });
    }

    res.json({ message: "Categoria eliminada exitosamente" });
  } catch (err) {
    handleError(res, 500, "Error al eliminar categoria", err);
  }
});

//////proveedores////
//APIS PROVEEDORES
// GET: Obtener todos los proveedores
app.get("/api/proveedores", async (req, res) => {
  try {
    const [results] = await req.db.query("SELECT * FROM proveedores");
    res.json(results); // Devuelve la lista de proveedores
  } catch (err) {
    handleError(res, 500, "Error al obtener proveedores", err);
  }
});

// POST: Crear nuevo proveedor
app.post("/api/proveedores", async (req, res) => {
  try {

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

    // Validar los campos requeridos
    validateFields(req.body, [
      "nombre",
      "direccion",
      "contacto",
      "correo",
      "clasificacion",
      "tipo_persona",
      "numero_factura_compra",
      "ley_tributaria",
    ]);

    // Insertar en la base de datos
    const [result] = await req.db.query(
      "INSERT INTO proveedores (nombre, direccion, contacto, correo, clasificacion, tipo_persona, numero_factura_compra, ley_tributaria) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
      [
        nombre,
        direccion,
        contacto,
        correo,
        clasificacion,
        tipo_persona,
        numero_factura_compra,
        ley_tributaria,
      ]
    );

    res.status(201).json({
      message: "Proveedor creado exitosamente",
      id: result.insertId,
    });
  } catch (err) {
    console.error("Error en el servidor:", err); // Imprimir el error en la consola
    res
      .status(500)
      .json({ message: "Error interno del servidor", error: err.message });
  }
});

// ACTUALIZAR PROVEEDORES
app.put("/api/proveedores/:id", async (req, res) => {
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

  try {
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
      [
        nombre,
        direccion,
        contacto,
        correo,
        clasificacion,
        tipo_persona,
        numero_factura_compra,
        ley_tributaria,
        id,
      ]
    );

    res.json({ message: "Proveedor actualizado correctamente" });
  } catch (err) {
    console.error("Error al actualizar proveedor:", err);
    res.status(500).json({
      message: "Error al actualizar el proveedor",
      error: err.message,
    });
  }
});

// Obtener proveedor por ID
app.get("/api/proveedores/:id", async (req, res) => {
  const { id } = req.params;

  try {
    const [proveedor] = await req.db.query(
      "SELECT * FROM proveedores WHERE id = ?",
      [id]
    );

    if (!proveedor.length) {
      return res.status(404).json({ message: "Proveedor no encontrado" });
    }

    res.json(proveedor[0]);
  } catch (err) {
    console.error("Error al obtener proveedor:", err);
    res
      .status(500)
      .json({ message: "Error al obtener el proveedor", error: err.message });
  }
});

// DELETE: Eliminar proveedor por ID
app.delete("/api/proveedores/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const [result] = await req.db.query(
      "DELETE FROM proveedores WHERE id = ?",
      [id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Proveedor no encontrado" });
    }

    res.json({ message: "Proveedor eliminado exitosamente" });
  } catch (err) {
    handleError(res, 500, "Error al eliminar proveedor", err);
  }
});



////historial de ajustes////
































// ███████╗███████╗ ██████╗██╗   ██╗██████╗ 
// ██╔════╝██╔════╝██╔════╝╚██╗ ██╔╝██╔══██╗
// ███████╗█████╗  ██║      ╚████╔╝ ██████╔╝
// ╚════██║██╔══╝  ██║       ╚██╔╝  ██╔══██╗
// ███████║███████╗╚██████╗   ██║   ██████╔╝
// ╚══════╝╚══════╝ ╚═════╝   ╚═╝   ╚═════╝ 
// Autenticación

app.post("/login", async (req, res) => {
  try {
    const { usuario, password } = req.body;
    validateFields({ usuario, password }, ['usuario', 'password']);
    
    const [users] = await req.db.query(
      "SELECT * FROM usuarios WHERE usuario = ? LIMIT 1",
      [usuario]
    );
    
    if (users.length === 0) {
      return res.status(404).json({ success: false, message: "Usuario no encontrado" });
    }
    
    const user = users[0];
    const isLegacy = !user.password.startsWith("$2a$"); // Detectar contraseña legacy
    const passwordValid = isLegacy 
      ? password === user.password // Comparación directa
      : await bcrypt.compare(password, user.password); // Comparación bcrypt
    
    if (!passwordValid) {
      return res.status(401).json({ success: false, message: "Credenciales inválidas" });
    }
    
    res.json({
      success: true,
      user: { // Datos seguros del usuario
        id: user.id,
        usuario: user.usuario,
        nombre: user.nombre_completo,
        rol: user.rol
      }
    });
    
  } catch (err) {
    handleError(res, 500, "Error en el login", err);
  }
});

// ██╗   ██╗███████╗███████╗██████╗ 
// ██║   ██║██╔════╝██╔════╝██╔══██╗
// ██║   ██║███████╗█████╗  ██████╔╝
// ██║   ██║╚════██║██╔══╝  ██╔══██╗
// ██║     ╚██████╔╝██║     ██║  ██║
// ╚═╝      ╚═════╝ ╚═╝     ╚═╝  ╚═╝
// Gestión de Usuarios

app.route("/api/usuarios")
  .get(async (req, res) => { // GET: Listar usuarios (sin datos sensibles)
    try {
      const [results] = await req.db.query(`
        SELECT nombre_completo, usuario, rol, 
               fecha_creacion, fecha_actualizacion 
        FROM usuarios
      `);
      res.json(results);
    } catch (err) {
      handleError(res, 500, "Error al obtener usuarios", err);
    }
  })
  .post(async (req, res) => {
    try {
      const { nombre_completo, usuario, password, rol } = req.body;
      validateFields(req.body, ['nombre_completo', 'usuario', 'password', 'rol']);
      
      // Verificar si el usuario ya existe
      const [existing] = await req.db.query(
        "SELECT usuario FROM usuarios WHERE usuario = ?", 
        [usuario]
      );
      
      if (existing.length > 0) {
        return res.status(409).json({ message: "El usuario ya existe" });
      }
      
      // Encriptar contraseña
      const hashedPassword = await bcrypt.hash(password, 12);
      
      // Insertar nuevo usuario
      const [result] = await req.db.query(`
        INSERT INTO usuarios 
        (nombre_completo, usuario, password, rol, fecha_creacion, fecha_actualizacion)
        VALUES (?, ?, ?, ?, NOW(), NOW())
      `, [nombre_completo, usuario, hashedPassword, rol]);
      
      res.status(201).json({
        message: "Usuario creado exitosamente",
        id: result.insertId
      });
      
    } catch (err) {
      handleError(res, err.status || 500, err.message, err);
    }
  });

// Nuevo endpoint DELETE para borrar usuario
app.delete("/api/usuarios/:usuario", async (req, res) => {
  try {
    const { usuario } = req.params;
    const [result] = await req.db.query(
      "DELETE FROM usuarios WHERE usuario = ?",
      [usuario]
    );
    
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Usuario no encontrado" });
    }
    
    res.json({ message: "Usuario eliminado exitosamente" });
  } catch (err) {
    handleError(res, 500, "Error al eliminar usuario", err);
  }
});

// Nuevo endpoint PUT para actualizar (editar) usuario
app.put("/api/usuarios/:usuario", async (req, res) => {
  try {
    const { usuario } = req.params;
    const { nombre_completo, password, rol } = req.body;
    if (!nombre_completo || !rol) {
      return res.status(400).json({ message: "Nombre completo y rol son requeridos" });
    }
    let updateFields = {
      nombre_completo,
      rol,
      fecha_actualizacion: new Date()
    };
    if (password && password.trim() !== "") {
      const hashedPassword = await bcrypt.hash(password, 12);
      updateFields.password = hashedPassword;
    }
    const [result] = await req.db.query("UPDATE usuarios SET ? WHERE usuario = ?", [updateFields, usuario]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Usuario no encontrado" });
    }
    res.json({ message: "Usuario actualizado exitosamente" });
  } catch (err) {
    handleError(res, 500, "Error al actualizar usuario", err);
  }
});

// ███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗
// ██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║
// █████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║
// ██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║
// ██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║
// ╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝
// Funciones de Utilidad

function validateFields(data, requiredFields) {
  const missing = requiredFields.filter(field => !data[field]);
  if (missing.length > 0) {
    const error = new Error(`Campos requeridos: ${missing.join(', ')}`);
    error.status = 400;
    throw error;
  }
}

function handleError(res, status, message, error) {
  console.error(`${message}:`, error.message);
  res.status(status).json({ 
    message,
    error: process.env.NODE_ENV === 'development'
      ? error.message 
      : undefined 
  });
}

















/////////////////////////////////////

/////////////////////////////MOVIMIENTOS/////////////////////////
/////////////////////////////MOVIMIENTOS/////////////////////////
////VENTAS AQUI EMPIEZAN DE MOVIMIENTOS/////////////////
// AGREGAR UNA VENTA
// AGREGAR UNA VENTA (actualizado)
app.post("/api/ventas", async (req, res) => {
  try {
    const {
      cliente_id,
      tipo_factura,
      metodo_pago,
      total,
      descripcion_compra,
      productos, // Array de productos: { codigo_producto, cantidad, precio_unitario }
      fecha_venta,
    } = req.body;

    // Validar stock antes de proceder
    for (const producto of productos) {
      const [inventario] = await req.db.query(
        "SELECT stock_existencia FROM inventario WHERE codigo = ?",
        [producto.codigo_producto]
      );

      if (inventario.length === 0) {
        return res.status(404).json({ message: `Producto ${producto.codigo_producto} no encontrado` });
      }

      if (inventario[0].stock_existencia < producto.cantidad) {
        return res.status(400).json({ message: `Stock insuficiente para el producto ${producto.codigo_producto}` });
      }
    }

    // Insertar la venta
    const [ventaResult] = await req.db.query(
      `INSERT INTO ventas (cliente_id, tipo_factura, metodo_pago, total, descripcion_compra, fecha_venta)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [cliente_id, tipo_factura, metodo_pago, total, descripcion_compra, fecha_venta]
    );

    const ventaId = ventaResult.insertId;

    // Insertar detalles de la venta y actualizar stock
    for (const producto of productos) {
      await req.db.query(
        `INSERT INTO detalle_ventas (idVentas, codigo_producto, nombre, cantidad, precio_unitario, subtotal)
         VALUES (?, ?, ?, ?, ?, ?)`,
        [ventaId, producto.codigo_producto, producto.nombre, producto.cantidad, producto.precio_unitario, producto.subtotal]
      );

      // Actualizar stock en inventario
      await req.db.query(
        "UPDATE inventario SET stock_existencia = stock_existencia - ? WHERE codigo = ?",
        [producto.cantidad, producto.codigo_producto]
      );
    }

    res.status(201).json({ message: "Venta agregada correctamente", ventaId });
  } catch (err) {
    console.error("Error al agregar la venta:", err);
    res.status(500).json({ message: "Error al agregar la venta", error: err.message });
  }
});


app.get('/api/ventas', async (req, res) => {
  try {
    const query = `
      SELECT 
        v.idVentas,
        MAX(v.fecha_venta) AS fecha_venta,
        MAX(v.tipo_factura) AS tipo_factura,
        MAX(v.metodo_pago) AS metodo_pago,
        MAX(v.total) AS total,
        MAX(v.descripcion_compra) AS descripcion_compra,
        MAX(c.nombre) AS cliente_nombre,
        MAX(c.direccion) AS direccion_cliente,
        MAX(c.dui) AS dui,
        MAX(c.nit) AS nit,
        JSON_ARRAYAGG(
          JSON_OBJECT(
            'codigo', dv.codigo_producto,
            'nombre', i.nombre,
            'cantidad', dv.cantidad,
            'precio', dv.precio_unitario,
            'costo', i.costo
          )
        ) AS productos
      FROM ventas v
      LEFT JOIN clientes c ON v.cliente_id = c.idCliente
      LEFT JOIN detalle_ventas dv ON v.idVentas = dv.idVentas
      LEFT JOIN inventario i ON dv.codigo_producto = i.codigo
      GROUP BY v.idVentas
    `;

    const [rows] = await req.db.query(query);
    res.json(rows);
    
  } catch (err) {
    console.error("Error SQL:", err.sqlMessage);
    res.status(500).json({ error: err.message });
  }
});






// ACTUALIZAR UNA VENTA (actualizado)
app.put("/api/ventas/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const {
      direccion_cliente,
      descripcion_compra,
      tipo_factura,
      metodo_pago
    } = req.body;

    await req.db.query(
      `UPDATE ventas SET 
        descripcion_compra = ?, 
        tipo_factura = ?, 
        metodo_pago = ?
       WHERE idVentas = ?`,
      [descripcion_compra, tipo_factura, metodo_pago, id]
    );

    // Actualizar dirección en clientes
    await req.db.query(
      `UPDATE clientes SET direccion = ? 
       WHERE idCliente = (
         SELECT cliente_id FROM ventas WHERE idVentas = ?
       )`,
      [direccion_cliente, id]
    );

    res.json({ message: "Venta actualizada correctamente" });
  } catch (err) {
    console.error("Error al actualizar:", err);
    res.status(500).json({ 
      message: "Error al actualizar", 
      error: err.message 
    });
  }
});



// ELIMINAR UNA VENTA
app.delete("/api/ventas/:id", async (req, res) => {
  try {
    const { id } = req.params;

    // Eliminar los detalles de la venta
    await req.db.query("DELETE FROM detalle_ventas WHERE idVentas = ?", [id]);

    // Eliminar la venta
    const [result] = await req.db.query("DELETE FROM ventas WHERE idVentas = ?", [id]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Venta no encontrada" });
    }

    res.json({ message: "Venta eliminada correctamente" });
  } catch (err) {
    console.error("Error al eliminar la venta:", err);
    res.status(500).json({ message: "Error al eliminar la venta", error: err.message });
  }
});

///VENTAS AQUI TERMINA DE MOVIMIENTOS/////////////////
///////////////NUEVO ENDPOINT PARA INVENTARIO/////////////////////
// Nuevo endpoint para buscar por código exacto
app.get('/api/inventario/codigo/:codigo', async (req, res) => {
  try {
    const { codigo } = req.params;
    const [rows] = await req.db.query(
      "SELECT * FROM inventario WHERE codigo = ?",
      [codigo]
    );
    
    if (rows.length === 0) {
      return res.status(404).json({});
    }
    
    res.json(rows[0]);
  } catch (err) {
    console.error("Error buscando producto:", err);
    res.status(500).json({ error: err.message });
  }
});
///// CLIENTES  DE MOVIMIENTOS/////

// Obtener todos los clientes
app.get('/api/clientes', async (req, res) => {
  try {
    const [rows] = await req.db.query('SELECT * FROM clientes');
    res.json(rows);
  } catch (err) {
    console.error("Error al obtener clientes:", err);
    res.status(500).json({ message: "Error al obtener clientes", error: err.message });
  }
});


// Agregar un nuevo cliente
app.post('/api/clientes', async (req, res) => {
  try {
    const { nombre, direccion, dui, nit, tipo_cliente, registro_contribuyente, representante_legal, direccion_representante, razon_social, email, telefono, fecha_inicio, fecha_fin, porcentaje_retencion } = req.body;

    const [result] = await req.db.query(
      `INSERT INTO clientes (nombre, direccion, dui, nit, tipo_cliente, registro_contribuyente, representante_legal, direccion_representante, razon_social, email, telefono, fecha_inicio, fecha_fin, porcentaje_retencion) 
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [nombre, direccion, dui, nit, tipo_cliente, registro_contribuyente, representante_legal, direccion_representante, razon_social, email, telefono, fecha_inicio, fecha_fin, porcentaje_retencion]
    );

    res.status(201).json({ message: "Cliente agregado correctamente", idCliente: result.insertId });
  } catch (err) {
    console.error("Error al agregar cliente:", err);
    res.status(500).json({ message: "Error al agregar cliente", error: err.message });
  }
});


// Actualizar un cliente
app.put('/api/clientes/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { nombre, direccion, dui, nit, tipo_cliente, registro_contribuyente, representante_legal, direccion_representante, razon_social, email, telefono, fecha_inicio, fecha_fin, porcentaje_retencion } = req.body;

    const [result] = await req.db.query(
      `UPDATE clientes SET 
        nombre = ?, direccion = ?, dui = ?, nit = ?, tipo_cliente = ?, registro_contribuyente = ?, 
        representante_legal = ?, direccion_representante = ?, razon_social = ?, email = ?, telefono = ?, 
        fecha_inicio = ?, fecha_fin = ?, porcentaje_retencion = ? WHERE idCliente = ?`,
      [nombre, direccion, dui, nit, tipo_cliente, registro_contribuyente, representante_legal, direccion_representante, razon_social, email, telefono, fecha_inicio, fecha_fin, porcentaje_retencion, id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Cliente no encontrado" });
    }

    res.json({ message: "Cliente actualizado correctamente" });
  } catch (err) {
    console.error("Error al actualizar cliente:", err);
    res.status(500).json({ message: "Error al actualizar cliente", error: err.message });
  }
});


// Eliminar un cliente
app.delete('/api/clientes/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const [result] = await req.db.query('DELETE FROM clientes WHERE idCliente = ?', [id]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Cliente no encontrado" });
    }

    res.json({ message: "Cliente eliminado correctamente" });
  } catch (err) {
    console.error("Error al eliminar cliente:", err);
    res.status(500).json({ message: "Error al eliminar cliente", error: err.message });
  }
});


///// CLIENTES  DE MOVIMIENTOS, TERMINA AQUI/////
///// TRASLADOS /////

// Obtener todos los traslados
app.get('/api/traslados', async (req, res) => {
  try {
    const query = `
      SELECT 
        t.id, t.codigo_traslado, t.cantidad, t.fecha_traslado, t.estado,
        i.nombre AS producto_nombre,
        s1.nombre AS sucursal_origen,
        s2.nombre AS sucursal_destino,
        e.nombres AS empleado_nombre
      FROM traslados t
      INNER JOIN inventario i ON t.inventario_id = i.id
      INNER JOIN sucursal s1 ON t.origen_id = s1.id
      INNER JOIN sucursal s2 ON t.destino_id = s2.id
      INNER JOIN empleados e ON t.empleado_id = e.id
    `;

    const [rows] = await req.db.query(query);
    res.json(rows);
  } catch (err) {
    console.error("Error al obtener los traslados:", err);
    res.status(500).json({ message: "Error al obtener los traslados", error: err.message });
  }
});

// Filtrar traslados por fecha
app.get('/api/traslados/filtrar', async (req, res) => {
  try {
    const { fecha } = req.query;

    const query = `
      SELECT 
        t.id, t.codigo_traslado, t.cantidad, t.fecha_traslado, t.estado,
        i.nombre AS producto_nombre,
        s1.nombre AS sucursal_origen,
        s2.nombre AS sucursal_destino,
        e.nombres AS empleado_nombre
      FROM traslados t
      INNER JOIN inventario i ON t.inventario_id = i.id
      INNER JOIN sucursal s1 ON t.origen_id = s1.id
      INNER JOIN sucursal s2 ON t.destino_id = s2.id
      INNER JOIN empleados e ON t.empleado_id = e.id
      WHERE DATE(t.fecha_traslado) = ?
    `;

    const [rows] = await req.db.query(query, [fecha]);
    res.json(rows);
  } catch (err) {
    console.error("Error al filtrar los traslados por fecha:", err);
    res.status(500).json({ message: "Error al filtrar los traslados por fecha", error: err.message });
  }
});

// Agregar un nuevo traslado
app.post('/api/traslados', async (req, res) => {
  try {
    const {
      codigo_traslado,
      inventario_id,
      origen_id,
      destino_id,
      cantidad,
      empleado_id,
      estado,
    } = req.body;

    const [result] = await req.db.query(
      `INSERT INTO traslados (codigo_traslado, inventario_id, origen_id, destino_id, cantidad, empleado_id, estado)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [codigo_traslado, inventario_id, origen_id, destino_id, cantidad, empleado_id, estado]
    );

    res.status(201).json({ message: "Traslado agregado correctamente", id: result.insertId });
  } catch (err) {
    console.error("Error al agregar el traslado:", err);
    res.status(500).json({ message: "Error al agregar el traslado", error: err.message });
  }
});

// Actualizar un traslado
app.put('/api/traslados/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const {
      codigo_traslado,
      inventario_id,
      origen_id,
      destino_id,
      cantidad,
      empleado_id,
      estado,
    } = req.body;

    const [result] = await req.db.query(
      `UPDATE traslados 
       SET codigo_traslado = ?, inventario_id = ?, origen_id = ?, destino_id = ?, cantidad = ?, empleado_id = ?, estado = ?
       WHERE id = ?`,
      [codigo_traslado, inventario_id, origen_id, destino_id, cantidad, empleado_id, estado, id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Traslado no encontrado" });
    }

    res.json({ message: "Traslado actualizado correctamente" });
  } catch (err) {
    console.error("Error al actualizar el traslado:", err);
    res.status(500).json({ message: "Error al actualizar el traslado", error: err.message });
  }
});

// Eliminar un traslado
app.delete('/api/traslados/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const [result] = await req.db.query('DELETE FROM traslados WHERE id = ?', [id]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Traslado no encontrado" });
    }

    res.json({ message: "Traslado eliminado correctamente" });
  } catch (err) {
    console.error("Error al eliminar el traslado:", err);
    res.status(500).json({ message: "Error al eliminar el traslado", error: err.message });
  }
});



///// OFERTAS /////

// Obtener todas las ofertas
app.get('/api/ofertas', async (req, res) => {
  try {
    const query = `
      SELECT 
        o.id, o.descuento, o.fecha_inicio, o.fecha_fin, o.estado,
        i.codigo, i.nombre AS producto_nombre, i.precio_venta
      FROM ofertas o
      INNER JOIN inventario i ON o.inventario_id = i.id
    `;

    const [rows] = await req.db.query(query);
    res.json(rows);
  } catch (err) {
    console.error("Error al obtener las ofertas:", err);
    res.status(500).json({ message: "Error al obtener las ofertas", error: err.message });
  }
});

// Agregar una nueva oferta
app.post('/api/ofertas', async (req, res) => {
  try {
    const { inventario_id, descuento, fecha_inicio, fecha_fin } = req.body;

    const [result] = await req.db.query(
      `INSERT INTO ofertas (inventario_id, descuento, fecha_inicio, fecha_fin)
       VALUES (?, ?, ?, ?)`,
      [inventario_id, descuento, fecha_inicio, fecha_fin]
    );

    res.status(201).json({ message: "Oferta agregada correctamente", id: result.insertId });
  } catch (err) {
    console.error("Error al agregar la oferta:", err);
    res.status(500).json({ message: "Error al agregar la oferta", error: err.message });
  }
});

// Actualizar una oferta
app.put('/api/ofertas/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { inventario_id, descuento, fecha_inicio, fecha_fin, estado } = req.body;

    const [result] = await req.db.query(
      `UPDATE ofertas 
       SET inventario_id = ?, descuento = ?, fecha_inicio = ?, fecha_fin = ?, estado = ?
       WHERE id = ?`,
      [inventario_id, descuento, fecha_inicio, fecha_fin, estado, id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Oferta no encontrada" });
    }

    res.json({ message: "Oferta actualizada correctamente" });
  } catch (err) {
    console.error("Error al actualizar la oferta:", err);
    res.status(500).json({ message: "Error al actualizar la oferta", error: err.message });
  }
});

// Eliminar una oferta
app.delete('/api/ofertas/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const [result] = await req.db.query('DELETE FROM ofertas WHERE id = ?', [id]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Oferta no encontrada" });
    }

    res.json({ message: "Oferta eliminada correctamente" });
  } catch (err) {
    console.error("Error al eliminar la oferta:", err);
    res.status(500).json({ message: "Error al eliminar la oferta", error: err.message });
  }
});

// Inicio del servidor
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Servidor corriendo en http://localhost:${PORT}`);
});