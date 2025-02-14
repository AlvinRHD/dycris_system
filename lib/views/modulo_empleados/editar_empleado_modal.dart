import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditarEmpleadoModal extends StatefulWidget {
  final Map<String, dynamic> empleadoData;
  final VoidCallback onEmpleadoUpdated;

  const EditarEmpleadoModal({
    super.key,
    required this.empleadoData,
    required this.onEmpleadoUpdated,
  });

  @override
  // ignore: library_private_types_in_public_api
  _EditarEmpleadoModalState createState() => _EditarEmpleadoModalState();
}

class _EditarEmpleadoModalState extends State<EditarEmpleadoModal> {
  final _formKey = GlobalKey<FormState>();

  // Controladores
  late TextEditingController profesionController;
  late TextEditingController telefonoController;
  late TextEditingController celularController;
  late TextEditingController correoController;
  late TextEditingController direccionController;
  late TextEditingController sueldoBaseController;

  // Dropdowns
  String? selectedCargo;
  String? selectedLicencia;
  String? selectedSucursal;

  // Listas
  final List<String> cargos = [
    'Administrador',
    'Gerente',
    'Cajero',
    'Vendedor',
    'Bodeguero'
  ];
  final List<String> licencias = [
    'Licencia Motociclistas',
    'Licencia Particular',
    'Licencia Liviana',
    'Licencia Pesada',
    'Licencia Pesada-T',
    'No posee licencia'
  ];
  List<Map<String, dynamic>> sucursales = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _fetchSucursales();
  }

  void _initializeControllers() {
    profesionController =
        TextEditingController(text: widget.empleadoData['profesion'] ?? '');
    telefonoController =
        TextEditingController(text: widget.empleadoData['telefono'] ?? '');
    celularController =
        TextEditingController(text: widget.empleadoData['celular'] ?? '');
    correoController =
        TextEditingController(text: widget.empleadoData['correo'] ?? '');
    direccionController =
        TextEditingController(text: widget.empleadoData['direccion'] ?? '');
    sueldoBaseController = TextEditingController(
        text: widget.empleadoData['sueldo_base']?.toString() ?? '');

    selectedCargo = widget.empleadoData['cargo'] ?? cargos.first;
    selectedLicencia = widget.empleadoData['licencia'] ?? licencias.last;
    selectedSucursal = widget.empleadoData['sucursal'] ?? '';
  }

  Future<void> _fetchSucursales() async {
    final url = Uri.parse('http://localhost:3000/api/sucursales');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          sucursales = data.map((e) => e as Map<String, dynamic>).toList();
          if (selectedSucursal != null && selectedSucursal!.isNotEmpty) {
            final existe = sucursales.any(
                (s) => s['codigo'].toString() == selectedSucursal);
            if (!existe) {
              sucursales.add({'id': null, 'codigo': selectedSucursal});
            }
          }
        });
      } else {
        await _showAlertDialog(
            "Error", "Error al cargar sucursales: ${response.statusCode}");
      }
    } catch (error) {
      await _showAlertDialog("Error", "Error al obtener sucursales: $error");
    }
  }

  @override
  void dispose() {
    profesionController.dispose();
    telefonoController.dispose();
    celularController.dispose();
    correoController.dispose();
    direccionController.dispose();
    sueldoBaseController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String labelText, IconData icon) {
    return InputDecoration(
      labelText: labelText,
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
        borderSide: const BorderSide(color: Color(0xFF3C3C3C)),
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      filled: true,
      fillColor: Colors.white,
    );
  }

  ButtonStyle _buttonStyle(Color backgroundColor) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: const Color(0xFF2A2D3E),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontSize: 18),
    );
  }

  ButtonStyle _alertButtonStyle() {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith<Color?>(
        (states) {
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.pressed)) {
            // ignore: deprecated_member_use
            return const Color.fromARGB(255, 18, 122, 234).withOpacity(0.15);
          }
          return Theme.of(context).dialogBackgroundColor;
        },
      ),
      foregroundColor: WidgetStateProperty.all(const Color(0xFF2A2D3E)),
      elevation: WidgetStateProperty.all(0),
      padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 18)),
      overlayColor: WidgetStateProperty.all(Colors.transparent),
    );
  }

  Future<void> _showAlertDialog(String title, String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
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
            onPressed: () => Navigator.of(context).pop(),
            style: _alertButtonStyle(),
            child: const Text(
              "OK",
              style: TextStyle(fontSize: 16, letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateEmpleado() async {
    if (!_formKey.currentState!.validate()) {
      await _showAlertDialog("Error", "Por favor complete todos los campos requeridos");
      return;
    }

    if (sueldoBaseController.text.isEmpty ||
        double.tryParse(sueldoBaseController.text) == null) {
      await _showAlertDialog("Error", "Ingrese un sueldo base válido");
      return;
    }

    final url = Uri.parse('http://localhost:3000/api/empleados/${widget.empleadoData['id']}');
    final body = json.encode({
      'profesion': profesionController.text.trim(),
      'cargo': selectedCargo,
      'sucursal': selectedSucursal,
      'telefono': telefonoController.text.trim(),
      'celular': celularController.text.trim(),
      'correo': correoController.text.trim(),
      'direccion': direccionController.text.trim(),
      'sueldo_base': sueldoBaseController.text.trim(),
      'licencia': selectedLicencia,
    });
    
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      
      if (response.statusCode == 200) {
        await _showAlertDialog("Éxito", "Empleado actualizado exitosamente");
        widget.onEmpleadoUpdated();
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop();
      } else {
        final errorData = json.decode(response.body);
        await _showAlertDialog("Error", errorData['message'] ?? "Error desconocido");
      }
    } catch (e) {
      await _showAlertDialog("Error", "Error de conexión: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      title: const Text(
        'Editar Empleado',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Columna Izquierda (8 campos)
                Expanded(
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      _buildInfoField('Nombres', widget.empleadoData['nombres'], Icons.person),
                      _buildInfoField('Apellidos', widget.empleadoData['apellidos'], Icons.person_outline),
                      _buildInfoField('Código Empleado', widget.empleadoData['codigo_empleado'], Icons.badge),
                      _buildDropdown('Cargo', Icons.work_outline, cargos, selectedCargo, 
                          (value) => setState(() => selectedCargo = value)),
                      _buildEditableField('Profesión', profesionController, Icons.work),
                      _buildInfoField('DUI', widget.empleadoData['dui'], Icons.document_scanner),
                      _buildInfoField('NIT', widget.empleadoData['nit'], Icons.document_scanner_outlined),
                      _buildInfoField('ISSS', widget.empleadoData['isss'], Icons.account_balance_wallet),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Columna Derecha (8 campos)
                Expanded(
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      _buildDropdown(
                        'Sucursal', 
                        Icons.location_city, 
                        sucursales.map((e) => e['codigo'].toString()).toList(), 
                        selectedSucursal, 
                        (value) => setState(() => selectedSucursal = value)
                      ),
                      _buildEditableField('Dirección', direccionController, Icons.location_on),
                      _buildEditableField('Teléfono', telefonoController, Icons.phone),
                      _buildEditableField('Celular', celularController, Icons.smartphone),
                      _buildEditableField('Correo', correoController, Icons.email),
                      _buildEditableField('Sueldo Base', sueldoBaseController, Icons.attach_money, isNumber: true),
                      _buildDropdown('Licencia', Icons.card_membership, licencias, selectedLicencia, 
                          (value) => setState(() => selectedLicencia = value)),
                      _buildInfoField('AFP', widget.empleadoData['afp'], Icons.account_balance),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: _updateEmpleado,
          style: _buttonStyle(Colors.grey[200]!),
          child: const Text('Guardar cambios'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: _buttonStyle(Colors.grey[200]!),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }

  Widget _buildInfoField(String label, dynamic value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        initialValue: value?.toString() ?? '',
        decoration: _inputDecoration(label, icon),
        enabled: false,
      ),
    );
  }

  Widget _buildEditableField(
    String label, 
    TextEditingController controller, 
    IconData icon, {
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: _inputDecoration(label, icon),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    IconData icon,
    List<String> items,
    String? value,
    Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: _inputDecoration(label, icon),
        items: items.map((item) => DropdownMenuItem(
          value: item,
          child: Text(item),
        )).toList(),
        onChanged: onChanged,
        validator: (value) => value == null ? 'Seleccione $label' : null,
      ),
    );
  }
}
