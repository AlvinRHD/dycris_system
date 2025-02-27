// server_empleados.js
const express = require('express');
const router = express.Router();

const { handleError, validateFields, validarDUI, generarCodigoEmpleado } = require('./utils');

// GET /api/sucursales - Obtener sucursales
router.get('/sucursales', async (req, res) => {
    try {
        const [results] = await req.db.query("SELECT id, codigo FROM sucursal");
        res.json(results);
    } catch (err) {
        handleError(res, 500, "Error al obtener sucursales", err);
    }
});

// GET /api/empleados-sin-usuario - Empleados sin usuario asignado (solo activos)
router.get('/empleados-sin-usuario', async (req, res) => {
    try {
        const [results] = await req.db.query(`
            SELECT 
                e.id,
                e.nombres,
                e.apellidos,
                e.cargo 
            FROM empleados e
            WHERE e.estado = 'Activo'
                AND NOT EXISTS (
                    SELECT 1 
                    FROM usuarios u 
                    WHERE u.empleado_id = e.id
                )
        `);
        res.json(results);
    } catch (err) {
        handleError(res, 500, "Error al obtener empleados sin usuario", err);
    }
});

// Rutas para empleados (GET y POST) - /api/empleados
router.route('/empleados')
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
                    cargo,
                    sucursal,
                    telefono,
                    celular,
                    correo,
                    direccion,
                    estado,
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

            // Validación básica de campos requeridos
            const requiredFields = [
                'nombres',
                'apellidos',
                'profesion',
                'cargo',
                'sucursal',
                'sueldo_base'
            ];
            validateFields(empleadoData, requiredFields);

            // Validaciones de formato
            const validationErrors = [];
            const nameRegex = /^[a-zA-Z0-9 áéíóúÁÉÍÓÚñÑ]{2,50}$/;
            if (!nameRegex.test(empleadoData.nombres)) validationErrors.push("Formato de nombres inválido");
            if (!nameRegex.test(empleadoData.apellidos)) validationErrors.push("Formato de apellidos inválido");

            if (empleadoData.dui && !validarDUI(empleadoData.dui)) {
                validationErrors.push("DUI inválido");
            }

            // Se eliminó la validación de NIT ya que la columna fue removida

            if (empleadoData.licencia && empleadoData.licencia !== 'No posee licencia') {
                // Aquí podrías agregar validaciones adicionales para la licencia
            }

            if (validationErrors.length > 0) {
                return res.status(400).json({ errors: validationErrors });
            }

            // Generar código de empleado
            const [ultimoCodigo] = await req.db.query(
                "SELECT codigo_empleado FROM empleados ORDER BY id DESC LIMIT 1"
            );
            const nuevoCodigo = generarCodigoEmpleado(ultimoCodigo[0]?.codigo_empleado);

            // Insertar empleado en la BD (si no se envía estado se usará el default 'Activo')
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

// PUT /api/empleados/:id - Actualizar empleado
router.put('/empleados/:id', async (req, res) => {
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
            licencia,
            estado
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
            ...(estado !== undefined && { estado }),
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

// DELETE /api/empleados/:empleado - Eliminar usuario asociado e inactivar empleado
router.delete('/empleados/:empleado', async (req, res) => {
    try {
        const { empleado } = req.params;
        // Verificar que el empleado exista
        const [rows] = await req.db.query("SELECT id FROM empleados WHERE id = ?", [empleado]);
        if (rows.length === 0) {
            return res.status(404).json({ message: "Empleado no encontrado" });
        }

        // Eliminar el usuario asociado inmediatamente
        await req.db.query("DELETE FROM usuarios WHERE empleado_id = ?", [empleado]);

        // Marcar el empleado como 'Inactivo'
        const [result] = await req.db.query(
            "UPDATE empleados SET estado = 'Inactivo', fecha_actualizacion = ? WHERE id = ?",
            [new Date(), empleado]
        );

        if (result.affectedRows === 0) {
            return res.status(404).json({ message: "Empleado no encontrado" });
        }

        res.json({ message: "Empleado marcado como Inactivo y usuario eliminado" });
    } catch (err) {
        handleError(res, 500, "Error al inactivar empleado", err);
    }
});

module.exports = router;