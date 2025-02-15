// Carga variables de entorno desde un archivo .env
require("dotenv").config();

// Importa el módulo mysql2 (versión mejorada de mysql)
const mysql = require("mysql2");

// Configuración de la conexión usando variables de entorno
const connection = mysql.createConnection({
    host: process.env.DB_HOST,         // Host de la base de datos
    user: process.env.DB_USER,         // Usuario de la base de datos
    password: process.env.DB_PASSWORD, // Contraseña del usuario
    database: process.env.DB_NAME      // Nombre de la base de datos
});

// Intento de conexión a la base de datos
connection.connect((err) => {
    if (err) {
        // Manejo de errores detallado
        console.error("Error conectando a MySQL:", err);
        return;
    }
    // Mensaje de éxito
    console.log("Conectado a la base de datos MySQL");
});

// Exporta la conexión para uso en otros módulos
module.exports = connection;