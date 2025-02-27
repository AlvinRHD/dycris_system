// generarCodigo.js
const bcrypt = require('bcrypt');
const saltRounds = 10;
const codigoJefe = 'JEFE1234';

bcrypt.hash(codigoJefe, saltRounds, (err, hash) => {
  if (err) {
    console.error('Error al generar el hash:', err);
    return;
  }
  console.log('Hash generado:', hash);
  console.log(`Copia y pega esta consulta para insertar el código en tu base de datos:
  
  INSERT INTO codigos_autorizacion (codigo) VALUES ('${hash}');
  `);
});
