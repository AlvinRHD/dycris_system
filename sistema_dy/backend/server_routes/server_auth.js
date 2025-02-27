// server_auth.js
const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const router = express.Router();

const { validateFields, handleError } = require('./utils');

// Endpoint para verificar la conexión a la BD
router.get('/check-db', async (req, res) => {
    try {
        const [result] = await req.db.query(
            "SELECT NOW() AS db_time, @@system_time_zone AS timezone"
        );
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

// Endpoint para login (acepta contraseñas encriptadas o en texto plano)
router.post('/login', async (req, res) => {
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
        // Verificar si la contraseña está encriptada con bcrypt.
        // Asumimos que las contraseñas encriptadas comienzan con "$2" (puede ser $2a$, $2b$, $2y$, etc.)
        const isBcrypt = user.password.startsWith("$2");
        const passwordValid = isBcrypt
            ? await bcrypt.compare(password, user.password)
            : password === user.password;

        if (!passwordValid) {
            return res.status(401).json({ success: false, message: "Credenciales inválidas" });
        }

        const now = new Date();
        const tokenPayload = {
            id: user.id,
            usuario: user.usuario,
            nombre: user.nombre_completo,
            cargo: user.cargo,
            tipo_cuenta: user.tipo_cuenta,
            empleado_id : user.empleado_id,
            fecha_inicio: new Date(now.getTime() - (now.getTimezoneOffset() * 60000)).toISOString()
        };

        const token = jwt.sign(tokenPayload, process.env.JWT_SECRET, { expiresIn: '1d' });

        res.json({
            success: true,
            token: token,
            user: tokenPayload
        });

    } catch (err) {
        handleError(res, 500, "Error en el login", err);
    }
});

module.exports = router;