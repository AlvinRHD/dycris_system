require('dotenv').config();
const express = require('express');
const cors = require('cors');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const mysql = require('mysql2/promise');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());
app.use(cors());

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

app.use((req, res, next) => {
  req.db = pool;
  next();
});

pool.getConnection()
  .then(conn => {
    console.log("Conectado a MySQL");
    conn.release();
  })
  .catch(err => {
    console.error("Error de conexión:", err.message);
  });

// ========== ENDPOINTS ==========

app.get("/check-db", async (req, res) => {
  try {
    const [result] = await req.db.query("SELECT NOW() AS db_time, @@system_time_zone AS timezone");
    res.json({
      success: true,
      dbTime: result[0].db_time,
      dbTimezone: result[0].timezone,
      serverTime: new Date()
    });
  } catch (err) {
    handleError(res, 500, "Error al verificar BD", err);
  }
});

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
    const isLegacy = !user.password.startsWith("$2a$");
    const passwordValid = isLegacy
      ? password === user.password
      : await bcrypt.compare(password, user.password);

    if (!passwordValid) {
      return res.status(401).json({ success: false, message: "Credenciales inválidas" });
    }

    const now = new Date();
    const tokenPayload = {
      id: user.id,
      usuario: user.usuario,
      nombre: user.nombre_completo,
      cargo: user.cargo,
      tipo_cuenta: user.tipo_cuenta,
      fecha_inicio: new Date(now.getTime() - (now.getTimezoneOffset() * 60000)).toISOString()
    };

    const token = jwt.sign(tokenPayload, process.env.JWT_SECRET, { expiresIn: '7d' });

    res.json({
      success: true,
      token: token,
      user: tokenPayload
    });

  } catch (err) {
    handleError(res, 500, "Error en el login", err);
  }
});

app.route("/api/usuarios")
  .get(async (req, res) => {
    try {
      const [results] = await req.db.query(`
        SELECT nombre_completo, usuario, tipo_cuenta, cargo,
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
      const { nombre_completo, usuario, password, tipo_cuenta, cargo } = req.body;
      validateFields(req.body, ['nombre_completo', 'usuario', 'password', 'tipo_cuenta', 'cargo']);

      if (!['Admin', 'Normal'].includes(tipo_cuenta)) {
        return res.status(400).json({ message: 'Tipo de cuenta inválido' });
      }

      if (!['Administrador', 'Gerente', 'Cajero', 'Vendedor', 'Bodeguero'].includes(cargo)) {
        return res.status(400).json({ message: 'Cargo inválido' });
      }

      const [existingUser] = await req.db.query(
        "SELECT usuario FROM usuarios WHERE usuario = ? OR nombre_completo = ?",
        [usuario, nombre_completo]
      );

      if (existingUser.length > 0) {
        return res.status(409).json({
          message: existingUser[0].usuario === usuario
            ? "El usuario ya existe"
            : "El empleado ya tiene un usuario registrado"
        });
      }

      const hashedPassword = await bcrypt.hash(password, 12);

      const [result] = await req.db.query(`
        INSERT INTO usuarios 
        (nombre_completo, usuario, password, tipo_cuenta, cargo, fecha_creacion, fecha_actualizacion)
        VALUES (?, ?, ?, ?, ?, NOW(), NOW())
      `, [nombre_completo, usuario, hashedPassword, tipo_cuenta, cargo]);

      res.status(201).json({
        message: "Usuario creado exitosamente",
        id: result.insertId
      });

    } catch (err) {
      handleError(res, err.status || 500, err.message, err);
    }
  });

app.get("/api/empleados-sin-usuario", async (req, res) => {
  try {
    const [results] = await req.db.query(`
      SELECT 
        e.id,
        e.nombres,
        e.apellidos,
        e.cargo 
      FROM empleados e
      WHERE NOT EXISTS (
        SELECT 1 
        FROM usuarios u 
        WHERE 
            u.nombre_completo = CONCAT(e.nombres, ' ', e.apellidos)
      )
    `);
    res.json(results);
  } catch (err) {
    handleError(res, 500, "Error al obtener empleados sin usuario", err);
  }
});

// Endpoint modificado para eliminar empleado y el usuario asociado
app.delete("/api/empleados/:empleado", async (req, res) => {
  try {
    const { empleado } = req.params;
    // Primero, obtener el registro del empleado para conocer su nombre completo
    const [rows] = await req.db.query("SELECT nombres, apellidos FROM empleados WHERE id = ?", [empleado]);
    if (rows.length === 0) {
      return res.status(404).json({ message: "Empleado no encontrado" });
    }
    const fullName = rows[0].nombres + " " + rows[0].apellidos;

    // Eliminar el empleado
    const [result] = await req.db.query(
      "DELETE FROM empleados WHERE id = ?",
      [empleado]
    );
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Empleado no encontrado" });
    }
    // Eliminar el usuario asociado
    await req.db.query("DELETE FROM usuarios WHERE nombre_completo = ?", [fullName]);
    res.json({ message: "Empleado y usuario asociados eliminados exitosamente" });
  } catch (err) {
    handleError(res, 500, "Error al eliminar empleado", err);
  }
});

app.put("/api/usuarios/:usuario", async (req, res) => {
  try {
    const { usuario } = req.params;
    const { password, tipo_cuenta, cargo } = req.body;

    if (!tipo_cuenta || !['Admin', 'Normal'].includes(tipo_cuenta)) {
      return res.status(400).json({
        success: false,
        message: "Tipo de cuenta inválido"
      });
    }

    if (!cargo || !['Administrador', 'Gerente', 'Cajero', 'Vendedor', 'Bodeguero'].includes(cargo)) {
      return res.status(400).json({
        success: false,
        message: "Cargo inválido"
      });
    }

    const updateFields = {
      tipo_cuenta,
      cargo,
      fecha_actualizacion: new Date()
    };

    if (password && password.trim() !== "") {
      const validation = validatePasswordComplexity(password);
      if (!validation.isValid) {
        return res.status(400).json({
          success: false,
          message: validation.message
        });
      }
      updateFields.password = await bcrypt.hash(password, 12);
    }

    const [result] = await req.db.query(
      "UPDATE usuarios SET ? WHERE usuario = ?",
      [updateFields, usuario]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({
        success: false,
        message: "Usuario no encontrado"
      });
    }

    res.json({
      success: true,
      message: "Usuario actualizado exitosamente"
    });

  } catch (err) {
    handleError(res, 500, "Error al actualizar usuario", err);
  }
});

// ========== ENDPOINTS EMPLEADOS ==========

app.get("/api/sucursales", async (req, res) => {
  try {
    const [results] = await req.db.query("SELECT id, codigo FROM sucursal");
    res.json(results);
  } catch (err) {
    handleError(res, 500, "Error al obtener sucursales", err);
  }
});

app.route("/api/empleados")
  .get(async (req, res) => {
    try {
      const [results] = await req.db.query(`
        SELECT 
          id,
          nombres,
          apellidos,
          profesion,
          codigo_empleado,
          afp,
          isss,
          dui,
          nit,
          cargo,
          sucursal,
          telefono,
          celular,
          correo,
          direccion,
          sueldo_base,
          licencia,
          fecha_creacion,
          fecha_actualizacion
        FROM empleados
      `);
      res.json(results);
    } catch (err) {
      handleError(res, 500, "Error al obtener empleados", err);
    }
  })
  .post(async (req, res) => {
    try {
      const empleadoData = req.body;

      // Validación básica sin campo de fecha de nacimiento
      const requiredFields = [
        'nombres',
        'apellidos',
        'profesion',
        'cargo',
        'sucursal',
        'sueldo_base'
      ];
      validateFields(empleadoData, requiredFields);

      // Validar formato de datos
      const validationErrors = [];

      // Validar nombres y apellidos
      const nameRegex = /^[a-zA-Z0-9 áéíóúÁÉÍÓÚñÑ]{2,50}$/;
      if (!nameRegex.test(empleadoData.nombres)) validationErrors.push("Formato de nombres inválido");
      if (!nameRegex.test(empleadoData.apellidos)) validationErrors.push("Formato de apellidos inválido");

      // Validar DUI
      if (empleadoData.dui && !validarDUI(empleadoData.dui)) {
        validationErrors.push("DUI inválido");
      }

      // Validar NIT
      if (empleadoData.nit && !validarNIT(empleadoData.nit)) {
        validationErrors.push("NIT inválido");
      }

      // Validar licencia (si se requiere validación extra)
      if (empleadoData.licencia && empleadoData.licencia !== 'No posee licencia') {
        // Aquí puedes agregar validaciones adicionales para licencia
      }

      if (validationErrors.length > 0) {
        return res.status(400).json({ errors: validationErrors });
      }

      // Generar código de empleado
      const [ultimoCodigo] = await req.db.query(
        "SELECT codigo_empleado FROM empleados ORDER BY id DESC LIMIT 1"
      );
      const nuevoCodigo = generarCodigoEmpleado(ultimoCodigo[0]?.codigo_empleado);

      // Insertar en BD
      const [result] = await req.db.query(`INSERT INTO empleados SET ?`, {
        ...empleadoData,
        codigo_empleado: nuevoCodigo,
        fecha_creacion: new Date(),
        fecha_actualizacion: new Date()
      });

      res.status(201).json({
        message: "Empleado creado exitosamente",
        id: result.insertId
      });

    } catch (err) {
      handleError(res, err.status || 500, err.message, err);
    }
  });

app.put("/api/empleados/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const {
      profesion,
      cargo,
      sucursal,
      telefono,
      celular,
      correo,
      direccion,
      sueldo_base,
      licencia
    } = req.body;

    const updateFields = {
      ...(profesion !== undefined && { profesion }),
      ...(cargo !== undefined && { cargo }),
      ...(sucursal !== undefined && { sucursal }),
      ...(telefono !== undefined && { telefono }),
      ...(celular !== undefined && { celular }),
      ...(correo !== undefined && { correo }),
      ...(direccion !== undefined && { direccion }),
      ...(sueldo_base !== undefined && { sueldo_base }),
      ...(licencia !== undefined && { licencia }),
      fecha_actualizacion: new Date()
    };

    const [result] = await req.db.query("UPDATE empleados SET ? WHERE id = ?", [updateFields, id]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Empleado no encontrado" });
    }

    res.json({ message: "Empleado actualizado exitosamente" });
  } catch (err) {
    console.error("Error al actualizar empleado:", err.message);
    res.status(500).json({ message: "Error al actualizar empleado", error: err.message });
  }
});

// ========== FUNCIONES AUXILIARES ==========

const validarDUI = (dui) => {
  const regex = /^\d{8}-\d$/;
  if (!regex.test(dui)) return false;

  const [numero, verificador] = dui.split('-');
  const pesos = [9, 8, 7, 6, 5, 4, 3, 2];
  let suma = 0;

  for (let i = 0; i < 8; i++) {
    suma += parseInt(numero[i]) * pesos[i];
  }

  const modulo = suma % 10;
  const digitoValidador = modulo === 0 ? 0 : 10 - modulo;

  return parseInt(verificador) === digitoValidador;
};

const validarNIT = (nit) => {
  const regex = /^\d{4}-\d{6}-\d{3}-\d$/;
  if (!regex.test(nit)) return false;

  const partes = nit.split('-');
  const numero = partes.join('').slice(0, -1);
  const verificador = parseInt(partes[3]);

  let suma = 0;
  const factores = [3, 2, 7, 6, 5, 4, 3, 2, 7, 6, 5, 4, 3, 2];

  for (let i = 0; i < numero.length; i++) {
    suma += parseInt(numero[i]) * factores[i];
  }

  const modulo = suma % 11;
  const digitoValidador = modulo <= 1 ? 0 : 11 - modulo;

  return verificador === digitoValidador;
};

const generarCodigoEmpleado = (ultimoCodigo) => {
  const numero = ultimoCodigo
    ? parseInt(ultimoCodigo.split('-')[1]) + 1
    : 1;
  return `EMP-${numero.toString().padStart(4, '0')}`;
};

const validatePasswordComplexity = (password) => {
  const minLength = 8;
  const hasUpperCase = /[A-Z]/.test(password);
  const hasNumber = /[0-9]/.test(password);

  if (password.length < minLength) {
    return {
      isValid: false,
      message: "La contraseña debe tener al menos 8 caracteres"
    };
  }

  if (!hasUpperCase || !hasNumber) {
    return {
      isValid: false,
      message: "Debe contener al menos una mayúscula y un número"
    };
  }

  return { isValid: true };
};

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
    error: process.env.NODE_ENV === 'development' ? error.message : undefined
  });
}

app.listen(PORT, () => {
  console.log(`Servidor corriendo en http://localhost:${PORT}`);
});
