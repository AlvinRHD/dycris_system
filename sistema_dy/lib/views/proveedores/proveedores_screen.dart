import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'registrar_proveedores_screen.dart';
import 'package:flutter/services.dart';

class ProveedoresScreen extends StatefulWidget {
  const ProveedoresScreen({super.key});

  @override
  _ProveedoresScreenState createState() => _ProveedoresScreenState();
}

class _ProveedoresScreenState extends State<ProveedoresScreen> {
  List<Map<String, dynamic>> proveedores = [];
  List<Map<String, dynamic>> get _proveedoresFiltrados {
    return proveedores.where((proveedor) {
      bool coincideTipo = _mostrarNaturales
          ? proveedor['tipo_proveedor'] == 'Natural'
          : proveedor['tipo_proveedor'] == 'Jurídico';
      String query = _searchController.text.toLowerCase();
      bool coincideBusqueda = proveedor['nombre_comercial']
              .toString()
              .toLowerCase()
              .contains(query) ||
          proveedor['nombre_propietario']
              .toString()
              .toLowerCase()
              .contains(query) ||
          proveedor['correo'].toString().toLowerCase().contains(query);
      return coincideTipo && coincideBusqueda;
    }).toList();
  }

  List<DataRow> _generarFilas() {
    return _proveedoresFiltrados.map((proveedor) {
      return DataRow(
        cells: _mostrarNaturales
            ? _celdasNaturales(proveedor)
            : _celdasJuridicos(proveedor),
      );
    }).toList();
  }

  void _filterProveedores() {
    setState(() {});
  }

  bool _mostrarNaturales = true;
  final TextEditingController _searchController = TextEditingController();

  InputDecoration _inputDecoration(String labelText, IconData icon) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: Color(0xFF3C3C3C)),
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
      prefixIcon: Icon(icon, color: const Color(0xFF3C3C3C)),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      filled: true,
      fillColor: Colors.white,
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchProveedores();
  }

  Future<void> _fetchProveedores() async {
    final url = Uri.parse('http://localhost:3000/api/proveedores');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          proveedores = data.map((e) => e as Map<String, dynamic>).toList();
        });
      } else {
        throw Exception('Error al cargar los proveedores');
      }
    } catch (error) {
      print('Error al obtener los proveedores: $error');
    }
  }

  ButtonStyle _alertButtonStyle() {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.pressed)) {
            return const Color.fromARGB(255, 18, 122, 234).withOpacity(0.15);
          }
          return Theme.of(context).dialogBackgroundColor;
        },
      ),
      foregroundColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          return const Color(0xFF2A2D3E);
        },
      ),
      elevation: WidgetStateProperty.all(0),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 18)),
      overlayColor: WidgetStateProperty.all(Colors.transparent),
    );
  }

  Future<void> _showAlertDialog(
      String title, String message, IconData icon, Color iconColor) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: _alertButtonStyle(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Realiza la eliminación de un proveedor enviando una petición DELETE al API.
  /// Muestra un diálogo de alerta con el resultado de la operación.
  Future<void> _deleteProveedor(int id) async {
    final url = Uri.parse('http://localhost:3000/api/proveedores/$id');
    try {
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        // Al eliminar exitosamente se muestra un diálogo de éxito
        await _showAlertDialog(
          'Éxito',
          'Proveedor eliminado exitosamente',
          Icons.check_circle,
          Colors.green,
        );
        // Se recarga la lista de proveedores
        _fetchProveedores();
      } else {
        await _showAlertDialog(
          'Error',
          'Error al eliminar el proveedor',
          Icons.error,
          Colors.red,
        );
      }
    } catch (e) {
      await _showAlertDialog(
        'Error',
        'Error al eliminar el proveedor: $e',
        Icons.error,
        Colors.red,
      );
    }
  }

  /// Muestra un diálogo de confirmación antes de eliminar un proveedor.
  /// Si se confirma, se procede a llamar a [_deleteProveedor].
  Future<void> _confirmDelete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Confirmar eliminación'),
          ],
        ),
        content: Text('¿Está seguro de eliminar el proveedor'),
        actions: [
          // Botón "Cancelar" que cierra el diálogo sin eliminar
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: _alertButtonStyle(),
            child: const Text('Cancelar'),
          ),
          // Botón "Eliminar" que confirma la eliminación
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: _alertButtonStyle(),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _deleteProveedor(id);
    }
  }

  Future<void> _updateProveedor(
    int id,
    String nombre_propietario,
    String dui,
    String nombre_comercial,
    String correo,
    String direccion,
    String telefono,
  ) async {
    final url = Uri.parse('http://localhost:3000/api/proveedores/$id');
    final Map<String, dynamic> body = {
      'nombre_propietario': nombre_propietario,
      'dui': dui,
      'nombre_comercial': nombre_comercial,
      'correo': correo,
      'direccion': direccion,
      'telefono': telefono,
      'tipo_proveedor': "Natural",
    };

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        print('Respuesta del servidor: ${response.body}');
        await _showAlertDialog(
          'Éxito',
          'Proveedor actualizado exitosamente',
          Icons.check_circle,
          Colors.green,
        );
        // Después de actualizar, recarga la lista de proveedores
        _fetchProveedores();
      } else {
        print('Error en la actualización: ${response.body}');
        await _showAlertDialog(
          'Error',
          'Error al actualizar el proveedor 1 ',
          Icons.error,
          Colors.red,
        );
      }
    } catch (e) {
      await _showAlertDialog(
        'Error',
        'Error al actualizar el proveedor 2: $e',
        Icons.error,
        Colors.red,
      );
    }
  }

  Future<void> _updateProveedorJuridico(
    int id,
    String nombre_comercial,
    String correo,
    String direccion,
    String telefono,
    String razon_social,
    String nit,
    String nrc,
    String giro,
    String correspondencia,
  ) async {
    final url = Uri.parse('http://localhost:3000/api/proveedores/$id');
    final Map<String, dynamic> body = {
      'nombre_comercial': nombre_comercial,
      'correo': correo,
      'direccion': direccion,
      'telefono': telefono,
      'razon_social': razon_social,
      'nit': nit,
      'nrc': nrc,
      'giro': giro,
      'correspondencia': correspondencia,
      'tipo_proveedor': "Juridico",
    };

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        print('Respuesta del servidor: ${response.body}');
        await _showAlertDialog(
          'Éxito',
          'Proveedor jurídico actualizado exitosamente',
          Icons.check_circle,
          Colors.green,
        );
        _fetchProveedores();
      } else {
        print('Error en la actualización: ${response.body}');
        await _showAlertDialog(
          'Error',
          'Error al actualizar el proveedor jurídico',
          Icons.error,
          Colors.red,
        );
      }
    } catch (e) {
      await _showAlertDialog(
        'Error',
        'Error al actualizar el proveedor jurídico: $e',
        Icons.error,
        Colors.red,
      );
    }
  }

  /// Muestra un diálogo modal para editar los datos de un proveedor.
  Future<void> _showEditProveedorDialog(
      Map<String, dynamic> proveedorData) async {
    final TextEditingController propietarioController =
        TextEditingController(text: proveedorData['nombre_propietario'] ?? '');
    final TextEditingController duiController =
        TextEditingController(text: proveedorData['dui'] ?? '');
    final TextEditingController nombreController =
        TextEditingController(text: proveedorData['nombre_comercial'] ?? '');
    final TextEditingController correoController =
        TextEditingController(text: proveedorData['correo'] ?? '');
    final TextEditingController direccionController =
        TextEditingController(text: proveedorData['direccion'] ?? '');
    final TextEditingController telefonoController =
        TextEditingController(text: proveedorData['telefono'] ?? '');

    return showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return AlertDialog(
              title: const Text(
                'Editar Proveedor Natural',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Wrap(
                  spacing: 16, // Espaciado horizontal entre los elementos
                  runSpacing: 16, // Espaciado vertical entre las filas
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: _buildTextField('Nombre propietario',
                                Icons.person, propietarioController)),
                        SizedBox(width: 16),
                        Expanded(
                            child: _buildTextField('Nombre Comercial',
                                Icons.business, nombreController)),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                            child: _buildTextField(
                                'DUI', Icons.credit_card, duiController,
                                keyboardType: TextInputType.number,
                                inputFormatters: duiInputFormatters())),
                        SizedBox(width: 16),
                        Expanded(
                            child: _buildTextField(
                                'Correo', Icons.email, correoController,
                                keyboardType: TextInputType.emailAddress)),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                            child: _buildTextField('Dirección',
                                Icons.location_on, direccionController)),
                        SizedBox(width: 16),
                        Expanded(
                            child: _buildTextField(
                                'Teléfono', Icons.phone, telefonoController)),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    if (proveedorData['id'] == null) {
                      await _showAlertDialog(
                        'Error',
                        'No se pudo obtener el ID del proveedor',
                        Icons.error,
                        Colors.red,
                      );
                      return;
                    }

                    // Validación
                    if (nombreController.text.trim().isEmpty ||
                        propietarioController.text.trim().isEmpty ||
                        duiController.text.trim().isEmpty ||
                        direccionController.text.trim().isEmpty ||
                        telefonoController.text.trim().isEmpty ||
                        correoController.text.trim().isEmpty) {
                      await _showAlertDialog(
                        'Error',
                        'Todos los campos son obligatorios',
                        Icons.warning,
                        Colors.orange,
                      );
                      return;
                    }

                    // Validación de formato para DUI
                    if (!RegExp(r'^\d{8}-\d$')
                        .hasMatch(duiController.text.trim())) {
                      await _showAlertDialog(
                        'Error',
                        'El DUI debe tener el formato xxxxxxxx-x',
                        Icons.warning,
                        Colors.orange,
                      );
                      return;
                    }

                    // Validación de formato para correo electrónico
                    final RegExp emailRegex = RegExp(
                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                    );
                    if (!emailRegex.hasMatch(correoController.text.trim())) {
                      await _showAlertDialog(
                        'Error',
                        'Ingrese un correo electrónico válido',
                        Icons.warning,
                        Colors.orange,
                      );
                      return;
                    }
                    // Validación de longitud mínima para el teléfono
                    if (telefonoController.text.trim().length < 8) {
                      await _showAlertDialog(
                        'Error',
                        'El número de teléfono debe tener al menos 8 dígitos',
                        Icons.warning,
                        Colors.orange,
                      );
                      return;
                    }
                    await _updateProveedor(
                      proveedorData['id'],
                      propietarioController.text.trim(),
                      duiController.text.trim(),
                      nombreController.text.trim(),
                      correoController.text.trim(),
                      direccionController.text.trim(),
                      telefonoController.text.trim(),
                    );

                    Navigator.of(context).pop();
                  },
                  style: _alertButtonStyle(),
                  child: const Text('Guardar cambios'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: _alertButtonStyle(),
                  child: const Text('Cancelar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<TextInputFormatter> duiInputFormatters() {
    return [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(9), // Limita la longitud a 9 caracteres
      TextInputFormatter.withFunction((oldValue, newValue) {
        String newText = newValue.text;
        if (newText.length > 8) {
          // Si el texto tiene más de 8 caracteres, agregar un guion en la posición 8
          newText = newText.substring(0, 8) + '-' + newText.substring(8);
        }
        return TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        );
      }),
    ];
  }

  List<TextInputFormatter> nitInputFormatters() {
    return [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(14),
      TextInputFormatter.withFunction((oldValue, newValue) {
        String newText = newValue.text;
        if (newText.length > 4) {
          newText = newText.substring(0, 4) + '-' + newText.substring(4);
        }

        if (newText.length > 11) {
          newText = newText.substring(0, 11) + '-' + newText.substring(11);
        }

        if (newText.length > 15) {
          newText = newText.substring(0, 15) + '-' + newText.substring(15);
        }

        return TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        );
      }),
    ];
  }

  Future<void> _showEditProveedorJuridicoDialog(
      Map<String, dynamic> proveedorData) async {
    final TextEditingController nombreController =
        TextEditingController(text: proveedorData['nombre_comercial'] ?? '');
    final TextEditingController correoController =
        TextEditingController(text: proveedorData['correo'] ?? '');
    final TextEditingController direccionController =
        TextEditingController(text: proveedorData['direccion'] ?? '');
    final TextEditingController telefonoController =
        TextEditingController(text: proveedorData['telefono'] ?? '');
    final TextEditingController razonSocialController =
        TextEditingController(text: proveedorData['razon_social'] ?? '');
    final TextEditingController nitController =
        TextEditingController(text: proveedorData['nit'] ?? '');
    final TextEditingController nrcController =
        TextEditingController(text: proveedorData['nrc'] ?? '');
    final TextEditingController giroController =
        TextEditingController(text: proveedorData['giro'] ?? '');
    final TextEditingController correspondenciaController =
        TextEditingController(text: proveedorData['correspondencia'] ?? '');

    return showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return AlertDialog(
              title: const Text(
                'Editar Proveedor Jurídico',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Wrap(
                  spacing: 16, // Espaciado horizontal entre los elementos
                  runSpacing: 16, // Espaciado vertical entre los elementos
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: _buildTextField('Nombre Comercial',
                                Icons.store, nombreController)),
                        SizedBox(width: 16),
                        Expanded(
                            child: _buildTextField(
                                'Correo', Icons.email, correoController,
                                keyboardType: TextInputType.emailAddress)),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                            child: _buildTextField('Dirección',
                                Icons.location_on, direccionController)),
                        SizedBox(width: 16),
                        Expanded(
                            child: _buildTextField(
                                'Teléfono', Icons.phone, telefonoController)),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                            child: _buildTextField('Razón Social',
                                Icons.apartment, razonSocialController)),
                        SizedBox(width: 16),
                        Expanded(
                            child: _buildTextField(
                                'NIT', Icons.confirmation_number, nitController,
                                inputFormatters: nitInputFormatters())),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                            child: _buildTextField(
                                'NRC', Icons.assignment, nrcController)),
                        SizedBox(width: 16),
                        Expanded(
                            child: _buildTextField(
                                'Giro', Icons.work, giroController)),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                            child: _buildTextField(
                                'Correspondencia',
                                Icons.markunread_mailbox,
                                correspondenciaController)),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    if (proveedorData['id'] == null) {
                      await _showAlertDialog(
                        'Error',
                        'No se pudo obtener el ID del proveedor',
                        Icons.error,
                        Colors.red,
                      );
                      return;
                    }

                    // Validación
                    if (nombreController.text.trim().isEmpty ||
                        direccionController.text.trim().isEmpty ||
                        telefonoController.text.trim().isEmpty ||
                        correoController.text.trim().isEmpty ||
                        razonSocialController.text.trim().isEmpty ||
                        nitController.text.trim().isEmpty ||
                        nrcController.text.trim().isEmpty ||
                        giroController.text.trim().isEmpty) {
                      await _showAlertDialog(
                        'Error',
                        'Todos los campos son obligatorios',
                        Icons.warning,
                        Colors.orange,
                      );
                      return;
                    }

                    // Validación de formato para NIT
                    if (!RegExp(r'^\d{4}-\d{6}-\d{3}-\d$')
                        .hasMatch(nitController.text.trim())) {
                      await _showAlertDialog(
                        'Error',
                        'El NIT debe tener el formato xxxx-xxxxxx-xxx-x',
                        Icons.warning,
                        Colors.orange,
                      );
                      return;
                    }

                    // Validación de formato para correo electrónico
                    final RegExp emailRegex = RegExp(
                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                    );
                    if (!emailRegex.hasMatch(correoController.text.trim())) {
                      await _showAlertDialog(
                        'Error',
                        'Ingrese un correo electrónico válido',
                        Icons.warning,
                        Colors.orange,
                      );
                      return;
                    }
                    // Validación de longitud mínima para el teléfono
                    if (telefonoController.text.trim().length < 8) {
                      await _showAlertDialog(
                        'Error',
                        'El número de teléfono debe tener al menos 8 dígitos',
                        Icons.warning,
                        Colors.orange,
                      );
                      return;
                    }
                    // Validación para el NRC
                    if (nrcController.text.trim().length != 11 ||
                        !RegExp(r'^[A-Za-z0-9]{11}$')
                            .hasMatch(nrcController.text.trim())) {
                      await _showAlertDialog(
                        'Error',
                        'El NRC debe tener exactamente 11 caracteres alfanuméricos, sin guiones ni separadores.',
                        Icons.warning,
                        Colors.orange,
                      );
                      return;
                    }
                    await _updateProveedorJuridico(
                      proveedorData['id'],
                      nombreController.text.trim(),
                      correoController.text.trim(),
                      direccionController.text.trim(),
                      telefonoController.text.trim(),
                      razonSocialController.text.trim(),
                      nitController.text.trim(),
                      nrcController.text.trim(),
                      giroController.text.trim(),
                      correspondenciaController.text.trim(),
                    );
                    Navigator.of(context).pop();
                  },
                  style: _alertButtonStyle(),
                  child: const Text('Guardar cambios'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: _alertButtonStyle(),
                  child: const Text('Cancelar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(
    String label,
    IconData icon,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          prefixIcon: Icon(icon),
        ),
        keyboardType: keyboardType,
        inputFormatters: inputFormatters ??
            (label == 'Teléfono'
                ? [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(8),
                  ]
                : label == 'NRC'
                    ? [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[A-Za-z0-9]')),
                        LengthLimitingTextInputFormatter(11),
                      ]
                    : []),
        validator: (value) {
          if (value == null || value.isEmpty) {
            if (label == 'Correspondencia') {
              return null;
            }
            return 'Por favor ingrese $label';
          }
          if (label == 'DUI' && !RegExp(r'^\d{8}-\d$').hasMatch(value)) {
            return 'El DUI debe tener el formato xxxxxxxx-x';
          }
          if (label == 'NRC' &&
              !RegExp(r'^[A-Za-z0-9]{11}$').hasMatch(value ?? '')) {
            return 'El NRC debe tener 11 caracteres alfanuméricos.';
          }
          if (label == 'NIT' &&
              !RegExp(r'^\d{4}-\d{6}-\d{3}-\d$').hasMatch(value)) {
            return 'El NIT debe tener el formato xxxx-xxxxxx-xxx-x';
          }
          if (label == 'Teléfono' &&
              !RegExp(r'^\d{8}$').hasMatch(value ?? '')) {
            return 'El teléfono es invalido.';
          }
          if (label == 'Correo Electrónico') {
            final RegExp emailRegex = RegExp(
              r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
            );
            if (!emailRegex.hasMatch(value)) {
              return 'Ingrese un correo electrónico válido';
            }
          }
          return null;
        },
      ),
    );
  }

  /// Genera un menú desplegable con opciones.
  Widget _buildDropdown(String label, IconData icon, String value,
      List<String> items, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        ),
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  @override
  void dispose() {
    // Se libera el controlador de búsqueda al eliminarse el widget
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Proveedores Registrados',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(30),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: Colors.black,
              ),
            ),
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.grey[50],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Selector de tipo de proveedor
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Jurídicos"),
                Switch(
                  value: _mostrarNaturales,
                  onChanged: (value) {
                    setState(() {
                      _mostrarNaturales = value;
                    });
                  },
                  activeColor: const Color(
                      0xFFD4D8D4), // Color del botón cuando está activado
                  activeTrackColor: const Color(
                      0xFF281C70), // Color del fondo de la pista cuando está activado
                  inactiveThumbColor: const Color(
                      0xFFD4D8D4), // Color del botón cuando está desactivado
                  inactiveTrackColor: const Color(
                      0xFF281C70), // Color del fondo de la pista cuando está desactivado
                  thumbColor: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                      return Colors.white; // El color del botón no cambia
                    },
                  ),
                  thumbIcon: WidgetStateProperty.resolveWith<Icon>(
                    (Set<WidgetState> states) {
                      return const Icon(Icons.close, color: Colors.white);
                    },
                  ),
                ),
                const Text("Naturales"),
              ],
            ),

            const SizedBox(height: 16),

            // Barra de búsqueda
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Buscar proveedor...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        _filterProveedores();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _navegarARegistroProveedor,
                    icon: const Icon(Icons.add_business, size: 20),
                    label: const Text('Nuevo Proveedor'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A2D3E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Contenedor con la tabla de proveedores
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columnSpacing: 40,
                        horizontalMargin: 24,
                        headingRowHeight: 56,
                        dataRowHeight: 56,
                        headingRowColor: WidgetStateProperty.resolveWith<Color>(
                          (Set<WidgetState> states) => Colors.grey[50]!,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black12),
                        ),
                        columns: _mostrarNaturales
                            ? _columnasNaturales()
                            : _columnasJuridicos(),
                        rows: _generarFilas(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// Definir las columnas para proveedores naturales
  List<DataColumn> _columnasNaturales() {
    return const [
      DataColumn(
          label: Text('Nombre propietario',
              style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Dui', style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Nombre comercial',
              style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Correo', style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label:
              Text('Dirección', style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label:
              Text('Teléfono', style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Tipo proveedor',
              style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label:
              Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
    ];
  }

// Definir las columnas para proveedores jurídicos
  List<DataColumn> _columnasJuridicos() {
    return const [
      DataColumn(
          label: Text('Nombre comercial',
              style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Correo', style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label:
              Text('Dirección', style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label:
              Text('Teléfono', style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Razón social',
              style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('NIT', style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('NRC', style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Giro', style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Correspondencia',
              style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Tipo proveedor',
              style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label:
              Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
    ];
  }

  List<DataCell> _celdasNaturales(Map<String, dynamic> proveedor) {
    return [
      DataCell(Text(proveedor['nombre_propietario'] ?? '')),
      DataCell(Text(proveedor['dui'] ?? '')),
      DataCell(Text(proveedor['nombre_comercial'] ?? '')),
      DataCell(Text(proveedor['correo'] ?? '')),
      DataCell(Text(proveedor['direccion'] ?? '')),
      DataCell(Text(proveedor['telefono'] ?? '')),
      DataCell(Text(proveedor['tipo_proveedor'] ?? '')),
      _accionesProveedorNaturales(proveedor),
    ];
  }

  List<DataCell> _celdasJuridicos(Map<String, dynamic> proveedor) {
    return [
      DataCell(Text(proveedor['nombre_comercial'] ?? '')),
      DataCell(Text(proveedor['correo'] ?? '')),
      DataCell(Text(proveedor['direccion'] ?? '')),
      DataCell(Text(proveedor['telefono'] ?? '')),
      DataCell(Text(proveedor['razon_social'] ?? '')),
      DataCell(Text(proveedor['nit'] ?? '')),
      DataCell(Text(proveedor['nrc'] ?? '')),
      DataCell(Text(proveedor['giro'] ?? '')),
      DataCell(Text(proveedor['correspondencia'] ?? '')),
      DataCell(Text(proveedor['tipo_proveedor'] ?? '')),
      _accionesProveedorJuridicos(proveedor),
    ];
  }

// Acciones de editar y eliminar
  DataCell _accionesProveedorNaturales(Map<String, dynamic> proveedor) {
    return DataCell(
      Row(
        children: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () => _showEditProveedorDialog(proveedor),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _confirmDelete(proveedor['id']),
          ),
        ],
      ),
    );
  }

  DataCell _accionesProveedorJuridicos(Map<String, dynamic> proveedor) {
    return DataCell(
      Row(
        children: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () => _showEditProveedorJuridicoDialog(proveedor),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _confirmDelete(proveedor['id']),
          ),
        ],
      ),
    );
  }

  void _navegarARegistroProveedor() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegistroProveedorScreen()),
    );

    if (resultado == true) {
      _fetchProveedores();
    }
  }
}
