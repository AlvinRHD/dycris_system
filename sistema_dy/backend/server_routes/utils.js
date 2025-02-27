// utils.js

// Valida que existan los campos requeridos
const validateFields = (data, requiredFields) => {
    const missing = requiredFields.filter(field => !data[field]);
    if (missing.length > 0) {
        const error = new Error(`Campos requeridos: ${missing.join(', ')}`);
        error.status = 400;
        throw error;
    }
};

// Manejo de errores
const handleError = (res, status, message, error) => {
    console.error(`${message}:`, error.message);
    res.status(status).json({
        message,
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
};

// Validación de DUI
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

// Validación de NIT sin verificación de dígito
const validarNIT = (nit) => {
    const regex = /^\d{4}-\d{6}-\d{3}-\d$/;
    return regex.test(nit);
};

// Genera un código de empleado basado en el último código
const generarCodigoEmpleado = (ultimoCodigo) => {
    const numero = ultimoCodigo
        ? parseInt(ultimoCodigo.split('-')[1]) + 1
        : 1;
    return `EMP-${numero.toString().padStart(4, '0')}`;
};

// Valida la complejidad de la contraseña
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

module.exports = {
    validateFields,
    handleError,
    validarDUI,
    validarNIT,
    generarCodigoEmpleado,
    validatePasswordComplexity
};
