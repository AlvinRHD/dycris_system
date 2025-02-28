require('dotenv').config();
const express = require('express');
const cors = require('cors');
const mysql = require('mysql2/promise');
const path = require('path');
const multer = require("multer");
const fs = require("fs");
const cron = require('node-cron'); // Importar node-cron para programar tareas

const app = express();
const PORT = process.env.PORT || 3000;

// Middlewares
app.use(express.json());
app.use(cors());

// Servir la carpeta "uploads"
app.use("/uploads", express.static(path.join(__dirname, "uploads")));

// Crear pool de conexiones a MySQL
const pool = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  timezone: 'local',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

// Middleware para adjuntar el pool a cada request
app.use((req, res, next) => {
  req.db = pool;
  next();
});

// Verificar conexión a MySQL
pool.getConnection()
  .then(conn => {
    if (process.env.NODE_ENV !== 'production') {
      console.log("✅ Conectado a MySQL");
    }
    conn.release();
  })
  .catch(err => {
    console.error("❌ Error de conexión:", err.message);
  });

// Importar rutas
const authRoutes = require('./server_routes/server_auth');
const usuariosRoutes = require('./server_routes/server_usuarios');
const empleadosRoutes = require('./server_routes/server_empleados');
const inventarioRoutes = require("./server_routes/server_inventario");
const movimientosRoutes = require("./server_routes/server_movimientos");
const movimimientosTemporalesRouter = require("./server_routes/server_movimientos_temporales");

// Montar rutas de la API
app.use('/', authRoutes);
app.use('/api/usuarios', usuariosRoutes);
app.use('/api', empleadosRoutes);
app.use("/api", inventarioRoutes);
app.use("/api", movimientosRoutes);
app.use("/api", movimimientosTemporalesRouter);

// Cron job: Ejecutar cada 2 minutos para pruebas
// Eliminar físicamente empleados inactivos cuya fecha_actualizacion sea anterior a la fecha actual menos 5 minutos.
cron.schedule('*/2 * * * *', async () => {
  try {
      const fiveMinutesAgo = new Date();
      fiveMinutesAgo.setMinutes(fiveMinutesAgo.getMinutes() - 120);
      const [result] = await pool.query(
          "DELETE FROM empleados WHERE estado = 'Inactivo' AND fecha_actualizacion < ?",
          [fiveMinutesAgo]
      );
      console.log(`Eliminados ${result.affectedRows} empleados inactivos con más de 120 minutos.`);
  } catch (err) {
      console.error("Error al eliminar empleados inactivos:", err);
  }
});

// Rutas para producción: servir archivos estáticos de Flutter Web
app.use(express.static(path.join(__dirname, 'flutter_sistema')));

app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'flutter_sistema', 'index.html'));
});

// Iniciar servidor (el cron job ya se habrá configurado y se ejecutará en paralelo)
app.listen(PORT, () => {
  if (process.env.NODE_ENV !== 'production') {
    console.log(`🚀 Servidor corriendo en http://localhost:${PORT}`);
  }
});
