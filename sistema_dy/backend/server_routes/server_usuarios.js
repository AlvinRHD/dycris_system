const express = require('express');
const bcrypt = require('bcrypt');
const router = express.Router();

const { validateFields, handleError, validatePasswordComplexity } = require('./utils');

// GET /api/usuarios - Listar usuarios de empleados activos
router.get('/', async (req, res) => {
    try {
        const [results] = await req.db.query(`
            SELECT 
                u.nombre_completo, 
                u.usuario, 
                u.tipo_cuenta, 
                u.cargo, 
                u.fecha_creacion, 
                u.fecha_actualizacion 
            FROM usuarios u
            INNER JOIN empleados e ON u.empleado_id = e.id
            WHERE e.estado = 'Activo'
        `);
        res.json(results);
    } catch (err) {
        handleError(res, 500, "Error al obtener usuarios", err);
    }
});

// POST /api/usuarios - Crear un nuevo usuario (obtiene cargo y empleado_id del empleado)
router.post('/', async (req, res) => {
    try {
        // Se espera el campo "nombre_completo" en el body, que se usará para buscar en empleados.
        const { nombre_completo, usuario, password, tipo_cuenta } = req.body;
        validateFields(req.body, ['nombre_completo', 'usuario', 'password', 'tipo_cuenta']);

        if (!['Admin', 'Normal'].includes(tipo_cuenta)) {
            return res.status(400).json({ message: 'Tipo de cuenta inválido' });
        }

        // Buscar en la tabla empleados usando la concatenación de nombres y apellidos
        const [employee] = await req.db.query(
            "SELECT id, cargo FROM empleados WHERE CONCAT(nombres, ' ', apellidos) = ?",
            [nombre_completo]
        );
        if (employee.length === 0) {
            return res.status(404).json({ message: "Empleado no encontrado" });
        }
        const employeeId = employee[0].id;
        const employeeCargo = employee[0].cargo || 'Administrador';

        // Verificar que el usuario o el empleado no estén ya registrados
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
            (nombre_completo, usuario, password, tipo_cuenta, cargo, empleado_id, fecha_creacion, fecha_actualizacion)
            VALUES (?, ?, ?, ?, ?, ?, NOW(), NOW())
        `, [nombre_completo, usuario, hashedPassword, tipo_cuenta, employeeCargo, employeeId]);

        res.status(201).json({
            message: "Usuario creado exitosamente",
            id: result.insertId
        });

    } catch (err) {
        handleError(res, err.status || 500, err.message, err);
    }
});

// PUT /api/usuarios/:usuario - Actualizar usuario (solo se permite modificar tipo de cuenta y contraseña)
router.put('/:usuario', async (req, res) => {
    try {
        const { usuario } = req.params;
        const { password, tipo_cuenta } = req.body;

        if (!tipo_cuenta || !['Admin', 'Normal'].includes(tipo_cuenta)) {
            return res.status(400).json({
                success: false,
                message: "Tipo de cuenta inválido"
            });
        }

        // Se actualiza únicamente el tipo de cuenta y la contraseña (si se proporciona),
        // dejando sin cambios los campos cargo y empleado_id
        const updateFields = {
            tipo_cuenta,
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

// DELETE /api/usuarios/:usuario - Eliminar usuario
router.delete('/:usuario', async (req, res) => {
    try {
        const { usuario } = req.params;

        // Verificar si el usuario existe antes de eliminarlo
        const [existingUser] = await req.db.query("SELECT * FROM usuarios WHERE usuario = ?", [usuario]);
        if (existingUser.length === 0) {
            return res.status(404).json({ message: "Usuario no encontrado" });
        }

        const [result] = await req.db.query("DELETE FROM usuarios WHERE usuario = ?", [usuario]);
        if (result.affectedRows === 0) {
            return res.status(400).json({ message: "No se pudo eliminar el usuario" });
        }

        res.json({ message: "Usuario eliminado exitosamente" });

    } catch (err) {
        handleError(res, 500, "Error al eliminar usuario", err);
    }
});

module.exports = router;
