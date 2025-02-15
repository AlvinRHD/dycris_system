// ignore_for_file: curly_braces_in_flow_control_structures, duplicate_ignore

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NuevoEmpleadoModal extends StatefulWidget {
  final Function() onEmpleadoAdded;

  const NuevoEmpleadoModal({super.key, required this.onEmpleadoAdded});

  @override
  // ignore: library_private_types_in_public_api
  _NuevoEmpleadoModalState createState() => _NuevoEmpleadoModalState();
}

class _NuevoEmpleadoModalState extends State<NuevoEmpleadoModal> {
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final TextEditingController _nombresController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _profesionController = TextEditingController();
  final TextEditingController _duiController = TextEditingController();
  final TextEditingController _nitController = TextEditingController();
  final TextEditingController _afpController = TextEditingController();
  final TextEditingController _isssController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _celularController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _sueldoBaseController = TextEditingController();

  // Dropdowns
  String? _selectedCargo;
  String? _selectedLicencia = 'No posee licencia';
  String? _selectedSucursal;

  // Listas
  final List<String> _cargos = [
    'Administrador',
    'Gerente',
    'Cajero',
    'Vendedor',
    'Bodeguero'
  ];

  final List<String> _licencias = [
    'No posee licencia',
    'Licencia Motociclistas',
    'Licencia Particular',
    'Licencia Liviana',
    'Licencia Pesada',
    'Licencia Pesada-T'
  ];

  List<Map<String, dynamic>> _sucursales = [];

  @override
  void initState() {
    super.initState();
    _setupListeners();
    _fetchSucursales();
  }

  void _setupListeners() {
    _duiController.addListener(() => _formatDUI(_duiController));
    _nitController.addListener(() => _formatNIT(_nitController));
    _afpController.addListener(() => _formatAFP(_afpController));
    _isssController.addListener(() => _formatISSS(_isssController));
    _telefonoController.addListener(() => _formatPhone(_telefonoController));
    _celularController.addListener(() => _formatPhone(_celularController));
  }

  Future<void> _fetchSucursales() async {
    try {
      final response =
          await http.get(Uri.parse('http://localhost:3000/api/sucursales'));
      if (response.statusCode == 200) {
        setState(() {
          _sucursales =
              List<Map<String, dynamic>>.from(json.decode(response.body));
        });
      } else {
        _showErrorDialog('Error al cargar sucursales: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('Error al cargar sucursales: $e');
    }
  }

  // ----------------- Validaciones y Formateos -----------------

  // Validación del dígito verificador para DUI
  bool _validarDigitoVerificadorDUI(String dui) {
    final partes = dui.split('-');
    if (partes.length != 2) return false;
    final numero = partes[0];
    final verificador = int.tryParse(partes[1]) ?? -1;
    if (numero.length != 8 || verificador < 0 || verificador > 9) return false;
    const pesos = [9, 8, 7, 6, 5, 4, 3, 2];
    int suma = 0;
    for (int i = 0; i < 8; i++) {
      suma += int.parse(numero[i]) * pesos[i];
    }
    int modulo = suma % 10;
    int digitoValidador = modulo == 0 ? 0 : 10 - modulo;
    return digitoValidador == verificador;
  }

  // (La función _validarDigitoVerificadorNIT se mantiene, pero no se usa en la validación actual)
  // ignore: unused_element
  bool _validarDigitoVerificadorNIT(String nit) {
    final partes = nit.split('-');
    if (partes.length != 4) return false;
    final numero = partes.join('');
    if (numero.length != 14) return false;
    final verificador = int.tryParse(partes[3]) ?? -1;
    if (verificador < 0 || verificador > 9) return false;
    const factores = [3, 2, 7, 6, 5, 4, 3, 2, 7, 6, 5, 4, 3, 2];
    int suma = 0;
    for (int i = 0; i < 13; i++) {
      suma += int.parse(numero[i]) * factores[i];
    }
    int modulo = suma % 11;
    int digitoValidador = modulo <= 1 ? 0 : 11 - modulo;
    return digitoValidador == verificador;
  }

  // Formateo para DUI: máximo 9 dígitos (sin guiones) y se inserta el guión al llegar a 8
  void _formatDUI(TextEditingController controller) {
    final oldText = controller.text;
    String text = oldText.replaceAll('-', '');
    if (text.length > 9) text = text.substring(0, 9);
    String newText =
        text.length >= 8 ? '${text.substring(0, 8)}-${text.substring(8)}' : text;
    if (newText != oldText) {
      controller.value = controller.value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
        composing: TextRange.empty,
      );
    }
  }

  // Formateo para NIT: acepta 9 dígitos (homologado con DUI) o 14 dígitos (formato ####-######-###-#)
  void _formatNIT(TextEditingController controller) {
    final oldText = controller.text;
    String text = oldText.replaceAll('-', '');
    if (text.length > 14) text = text.substring(0, 14);
    String newText;
    if (text.length == 9) {
      newText = '${text.substring(0, 8)}-${text.substring(8)}';
    } else if (text.length == 14) {
      final part1 = text.substring(0, 4);
      final part2 = text.substring(4, 10);
      final part3 = text.substring(10, 13);
      final part4 = text.substring(13);
      newText = '$part1-$part2-$part3-$part4';
    } else {
      newText = text;
    }
    if (newText != oldText) {
      controller.value = controller.value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
        composing: TextRange.empty,
      );
    }
  }

  // Formateo para AFP/NUP: acepta 9 dígitos (homologado con DUI) o 12 dígitos (sin guiones)
  void _formatAFP(TextEditingController controller) {
    final oldText = controller.text;
    String text = oldText.replaceAll('-', '');
    if (text.length > 12) text = text.substring(0, 12);
    String newText =
        text.length == 9 ? '${text.substring(0, 8)}-${text.substring(8)}' : text;
    if (newText != oldText) {
      controller.value = controller.value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
        composing: TextRange.empty,
      );
    }
  }

  // Formateo para ISSS: se eliminan los guiones
  void _formatISSS(TextEditingController controller) {
    final oldText = controller.text;
    String newText = oldText.replaceAll('-', '');
    if (newText != oldText) {
      controller.value = controller.value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
        composing: TextRange.empty,
      );
    }
  }

  // Formateo para Teléfono/Celular: máximo 8 dígitos; se inserta guión después del cuarto dígito
  void _formatPhone(TextEditingController controller) {
    final oldText = controller.text;
    String text = oldText.replaceAll('-', '');
    if (text.length > 8) text = text.substring(0, 8);
    String newText =
        text.length >= 4 ? '${text.substring(0, 4)}-${text.substring(4)}' : text;
    if (newText != oldText) {
      controller.value = controller.value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
        composing: TextRange.empty,
      );
    }
  }

  // ----------------- Validaciones -----------------

  String? _validateDUI(String? value) {
    if (value?.isEmpty ?? true) return 'Requerido';
    if (!RegExp(r'^\d{8}-\d$').hasMatch(value!))
      return 'Formato inválido (########-#)';
    if (!_validarDigitoVerificadorDUI(value))
      return 'DUI no válido';
    return null;
  }

  // Validación de NIT: se aceptan ambos formatos sin verificar el dígito verificador
  String? _validateNIT(String? value) {
    if (value?.isEmpty ?? true) return 'Requerido';
    final cleanValue = value!.replaceAll('-', '');
    if (cleanValue.length == 9) {
      if (!RegExp(r'^\d{8}-\d$').hasMatch(value))
        return 'Formato inválido (########-#)';
      return null;
    } else if (cleanValue.length == 14) {
      if (!RegExp(r'^\d{4}-\d{6}-\d{3}-\d$').hasMatch(value))
        return 'Formato inválido (####-######-###-#)';
      return null;
    } else {
      return 'Debe ser formato DUI (########-#) o NIT (####-######-###-#)';
    }
  }

  String? _validateAFP(String? value) {
    if (value?.isEmpty ?? true) return 'Requerido';
    final cleanValue = value!.replaceAll('-', '');
    if (cleanValue.length == 9) {
      if (!RegExp(r'^\d{8}-\d$').hasMatch(value))
        return 'Formato inválido (########-#)';
      if (!_validarDigitoVerificadorDUI(value))
        return 'DUI no válido';
      return null;
    } else if (cleanValue.length == 12) {
      if (!RegExp(r'^\d{12}$').hasMatch(cleanValue))
        return 'NUP inválido (12 dígitos requeridos)';
      return null;
    } else {
      return 'Debe ser formato DUI (########-#) o NUP/AFP (12 dígitos)';
    }
  }

  String? _validateISSS(String? value) {
    if (value?.isEmpty ?? true) return 'Requerido';
    if (!RegExp(r'^\d+$').hasMatch(value!))
      return 'Solo se permiten dígitos (sin guiones)';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return null;
    final emailRegex = RegExp(
        r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$");
    if (!emailRegex.hasMatch(value)) return 'Correo electrónico inválido';
    return null;
  }

  String? _validateLicencia(String? value) {
    if (value == null) return 'Seleccione una opción';
    return null;
  }

  // ----------------- UI y Envío del Formulario -----------------

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF3C3C3C)),
      prefixIcon: Icon(icon, color: const Color(0xFF3C3C3C)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF3C3C3C)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF3C3C3C)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF2A2D3E)),
      ),
      // Se mantiene el contentPadding original para conservar la altura de los inputs
      contentPadding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      filled: true,
      fillColor: Colors.white,
      errorMaxLines: 3,
    );
  }

  // Ambos botones usarán el mismo estilo (color de fondo igual)
  ButtonStyle _buttonStyle(Color backgroundColor) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: const Color(0xFF2A2D3E),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF2A2D3E)),
      ),
      textStyle:
          const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.error, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text(
              'Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2A2D3E),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 16, color: Color(0xFF4A4A4A)),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        actionsPadding: const EdgeInsets.only(bottom: 20, right: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ButtonStyle(
              backgroundColor:
                  WidgetStateProperty.all(Colors.transparent),
              foregroundColor:
                  WidgetStateProperty.all(const Color(0xFF2A2D3E)),
              elevation: WidgetStateProperty.all(0),
              padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final empleadoData = {
          'nombres': _nombresController.text.trim(),
          'apellidos': _apellidosController.text.trim(),
          'profesion': _profesionController.text.trim(),
          'dui': _duiController.text,
          'nit': _nitController.text,
          'afp': _afpController.text.trim(),
          'isss': _isssController.text.trim(),
          'cargo': _selectedCargo,
          'sucursal': _selectedSucursal,
          'telefono': _telefonoController.text,
          'celular': _celularController.text,
          'correo': _correoController.text.trim(),
          'direccion': _direccionController.text.trim(),
          'sueldo_base': double.parse(_sueldoBaseController.text),
          'licencia': _selectedLicencia,
        };

        final response = await http.post(
          Uri.parse('http://localhost:3000/api/empleados'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(empleadoData),
        );

        if (response.statusCode == 201) {
          widget.onEmpleadoAdded();
          // ignore: use_build_context_synchronously
          Navigator.of(context).pop();
        } else {
          final errorData = json.decode(response.body);
          _showErrorDialog(
              errorData['errors']?.join('\n') ?? 'Error desconocido');
        }
      } on FormatException catch (_) {
        _showErrorDialog('Formato numérico inválido en sueldo base');
      } catch (e) {
        _showErrorDialog('Error de conexión: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      title: const Text(
        'Nuevo Empleado',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2A2D3E),
        ),
      ),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Agregamos espacio externo adicional antes de la primera fila sin modificar la altura interna de los inputs
                const SizedBox(height: 24),
                // Fila 1: Nombres (izquierda) y Cargo (derecha)
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        'Nombres*',
                        _nombresController,
                        Icons.person,
                        required: true,
                        validator: (value) {
                          if (value!.isEmpty) return 'Requerido';
                          if (!RegExp(r'^[a-zA-Z0-9 áéíóúÁÉÍÓÚñÑ]{2,50}$')
                              .hasMatch(value))
                            return 'Solo letras, números y espacios (2-50 caracteres)';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDropdown(
                        'Cargo*',
                        Icons.work,
                        _cargos,
                        _selectedCargo,
                        (v) => setState(() => _selectedCargo = v),
                        validator: (value) =>
                            value == null ? 'Seleccione cargo' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Fila 2: Apellidos (izquierda) y Sucursal (derecha)
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        'Apellidos*',
                        _apellidosController,
                        Icons.people,
                        required: true,
                        validator: (value) {
                          if (value!.isEmpty) return 'Requerido';
                          if (!RegExp(r'^[a-zA-Z0-9 áéíóúÁÉÍÓÚñÑ]{2,50}$')
                              .hasMatch(value))
                            return 'Solo letras, números y espacios (2-50 caracteres)';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDropdown(
                        'Sucursal*',
                        Icons.business,
                        _sucursales
                            .map((e) => e['codigo'].toString())
                            .toList(),
                        _selectedSucursal,
                        (v) => setState(() => _selectedSucursal = v),
                        validator: (value) =>
                            value == null ? 'Seleccione sucursal' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Fila 3: Licencia (izquierda) y Profesión (derecha)
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        'Licencia',
                        Icons.directions_car,
                        _licencias,
                        _selectedLicencia,
                        (v) => setState(() => _selectedLicencia = v),
                        validator: _validateLicencia,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        'Profesión*',
                        _profesionController,
                        Icons.school,
                        required: true,
                        validator: (value) {
                          if (value!.isEmpty) return 'Requerido';
                          if (value.length > 100) return 'Máximo 100 caracteres';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Fila 4: DUI (izquierda) y Sueldo Base (derecha)
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        'DUI*',
                        _duiController,
                        Icons.badge,
                        required: true,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: _validateDUI,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        'Sueldo Base*',
                        _sueldoBaseController,
                        Icons.attach_money,
                        required: true,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        validator: (value) {
                          if (value!.isEmpty) return 'Requerido';
                          final sueldo = double.tryParse(value);
                          if (sueldo == null) return 'Número inválido';
                          if (sueldo <= 0) return 'Debe ser mayor a 0';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Fila 5: NIT (izquierda) y Teléfono (derecha)
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        'NIT*',
                        _nitController,
                        Icons.note,
                        required: true,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: _validateNIT,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        'Teléfono',
                        _telefonoController,
                        Icons.phone,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value!.isNotEmpty &&
                              value.replaceAll('-', '').length != 8)
                            return '8 dígitos requeridos';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Fila 6: AFP/NUP (izquierda) y Celular (derecha)
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        'AFP/NUP*',
                        _afpController,
                        Icons.assignment_ind,
                        required: true,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: _validateAFP,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        'Celular',
                        _celularController,
                        Icons.phone_android,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value!.isNotEmpty &&
                              value.replaceAll('-', '').length != 8)
                            return '8 dígitos requeridos';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Fila 7: ISSS (izquierda) y Correo (derecha)
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        'ISSS*',
                        _isssController,
                        Icons.medical_services,
                        required: true,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: _validateISSS,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        'Correo',
                        _correoController,
                        Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Fila 8: Dirección (a lo ancho de ambas columnas)
                _buildTextField(
                  'Dirección*',
                  _direccionController,
                  Icons.location_on,
                  required: true,
                  validator: (value) {
                    if (value!.isEmpty) return 'Requerido';
                    if (value.length > 200) return 'Máximo 200 caracteres';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: _buttonStyle(Colors.grey[200]!),
          child: const Text('CANCELAR'),
        ),
        ElevatedButton(
          onPressed: _submitForm,
          style: _buttonStyle(Colors.grey[200]!),
          child: const Text('GUARDAR'),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool required = false,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: _inputDecoration(label, icon),
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: (value) {
          if (required && (value == null || value.isEmpty))
            return 'Campo requerido';
          return validator?.call(value);
        },
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    IconData icon,
    List<String> items,
    String? value,
    Function(String?) onChanged, {
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: _inputDecoration(label, icon),
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(item),
                ))
            .toList(),
        onChanged: onChanged,
        validator: validator,
        dropdownColor: Colors.white,
        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF3C3C3C)),
      ),
    );
  }

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    _profesionController.dispose();
    _duiController.dispose();
    _nitController.dispose();
    _afpController.dispose();
    _isssController.dispose();
    _telefonoController.dispose();
    _celularController.dispose();
    _correoController.dispose();
    _direccionController.dispose();
    _sueldoBaseController.dispose();
    super.dispose();
  }
}
