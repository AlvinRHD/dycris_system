// Importación de módulos
const express = require("express");
const mysql = require("mysql2/promise"); // MySQL con soporte para promesas
const cors = require("cors"); // Manejo de CORS
const bcrypt = require("bcryptjs"); // Encriptación de contraseñas
require("dotenv").config(); // Variables de entorno

const app = express(); // Inicialización de Express

// Configuración de middlewares
app.use(cors()); // Habilita CORS para todas las rutas
app.use(express.json()); // Parsea cuerpos de solicitud JSON

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

// ██████╗  ██████╗ ██╗   ██╗████████╗███████╗
// ██╔══██╗██╔═══██╗██║   ██║╚══██╔══╝██╔════╝
// ██████╔╝██║   ██║██║   ██║   ██║   █████╗  
// ██╔══██╗██║   ██║██║   ██║   ██║   ██╔══╝  
// ██║  ██║╚██████╔╝╚██████╔╝   ██║   ███████╗
// Rutas del Inventario

// GET: Obtener todos los productos
// POST: Crear nuevo producto
app.route("/api/inventario")
  .get(async (req, res) => {
    try {
      const [results] = await req.db.query("SELECT * FROM inventario");
      res.json(results);
    } catch (err) {
      handleError(res, 500, "Error al obtener inventario", err);
    }
  })
  .post(async (req, res) => {
    try {
      const requiredFields = ['codigo', 'nombre', 'categoria', 'sucursal', 'precio_compra', 'precio_venta', 'stock_existencia'];
      validateFields(req.body, requiredFields); // Validación de campos
      
      const [result] = await req.db.query("INSERT INTO inventario SET ?", [req.body]);
      
      res.status(201).json({
        message: "Producto creado",
        id: result.insertId // Retorna ID del nuevo producto
      });
    } catch (err) {
      handleError(res, err.status || 500, err.message, err);
    }
  });

  // GET: Obtener producto por ID
app.get("/api/inventario/:id", async (req, res) => {
  try {
    const { id } = req.params; // ID del producto
    const [results] = await req.db.query("SELECT * FROM inventario WHERE id = ?", [id]);
    
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
    codigo,
    nombre,
    descripcion,
    nro_motor,
    nro_chasis,
    categoria,
    sucursal,
    precio_compra,
    credito,
    precio_venta,
    stock_existencia,
    stock_minimo,
    fecha_ingreso,
    fecha_reingreso,
    nro_poliza,
    nro_lote
  } = req.body;

  try {
    // Verificar si el producto existe
    const [rows] = await req.db.query(
      "SELECT * FROM inventario WHERE id = ?",
      [id]
    );
    if (rows.length === 0) {
      return res.status(404).json({ message: "Producto no encontrado" });
    }

    // Actualizar el producto
    await req.db.query(
      `UPDATE inventario SET 
        codigo = ?, 
        nombre = ?, 
        descripcion = ?, 
        nro_motor = ?, 
        nro_chasis = ?, 
        categoria = ?, 
        sucursal = ?, 
        precio_compra = ?, 
        credito = ?, 
        precio_venta = ?, 
        stock_existencia = ?, 
        stock_minimo = ?, 
        fecha_ingreso = ?, 
        fecha_reingreso = ?, 
        nro_poliza = ?, 
        nro_lote = ? 
      WHERE id = ?`,
      [
        codigo, nombre, descripcion, nro_motor, nro_chasis, categoria, 
        sucursal, precio_compra, credito, precio_venta, stock_existencia, 
        stock_minimo, fecha_ingreso, fecha_reingreso, nro_poliza, nro_lote, id
      ]
    );

    res.json({ message: "Producto actualizado correctamente" });
  } catch (err) {
    console.error("Error al actualizar producto:", err);
    res.status(500).json({ message: "Error al actualizar el producto", error: err.message });
  }
});



// DELETE: Eliminar producto por código
app.delete("/api/inventario/:codigo", async (req, res) => {
  try {
    const { codigo } = req.params;
    const [result] = await req.db.query(
      "DELETE FROM inventario WHERE codigo = ?",
      [codigo]
    );
    
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Producto no encontrado" });
    }
    
    res.json({ message: "Producto eliminado exitosamente" });
  } catch (err) {
    handleError(res, 500, "Error al eliminar producto", err);
  }
});

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

// Inicio del servidor
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Servidor corriendo en http://localhost:${PORT}`);
});


////////////////////ACÁ EMPIEZA LA API DE MOVIMIENTOS///////////////////////
///VENTAS PUT
app.put("/api/ventas/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { cantidad, total, fecha, cliente } = req.body; // Asegúrate de enviar estos datos desde el frontend

    // Verificar si la venta existe
    const [ventaExistente] = await req.db.query("SELECT * FROM ventas WHERE id = ?", [id]);
    if (ventaExistente.length === 0) {
      return res.status(404).json({ message: "Venta no encontrada" });
    }

    // Actualizar la venta
    await req.db.query(
      `UPDATE ventas SET cantidad = ?, total = ?, fecha = ?, cliente = ? WHERE id = ?`,
      [cantidad, total, fecha, cliente, id]
    );

    res.json({ message: "Venta actualizada correctamente" });
  } catch (err) {
    console.error("Error al actualizar la venta:", err);
    res.status(500).json({ message: "Error al actualizar la venta", error: err.message });
  }
});


///VENTAS DELETE
app.delete("/api/ventas/:id", async (req, res) => {
  try {
    const { id } = req.params;

    const [result] = await req.db.query("DELETE FROM ventas WHERE id = ?", [id]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Venta no encontrada" });
    }

    res.json({ message: "Venta eliminada correctamente" });
  } catch (err) {
    console.error("Error al eliminar la venta:", err);
    res.status(500).json({ message: "Error al eliminar la venta", error: err.message });
  }
});
////////////////////ACÁ TERMINA LA API DE MOVIMIENTOS///////////////////////