import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'registrar_proveedores_screen.dart';

class ProveedoresScreen extends StatefulWidget {
  const ProveedoresScreen({super.key});

  @override
  _ProveedoresScreenState createState() => _ProveedoresScreenState();
}

class _ProveedoresScreenState extends State<ProveedoresScreen> {
  List<Map<String, dynamic>> proveedores = [];
  List<Map<String, dynamic>> proveedoresFiltrados = [];
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
    _searchController.addListener(_filterProveedores);
  }

  Future<void> _fetchProveedores() async {
    final url = Uri.parse('http://localhost:3000/api/proveedores');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          proveedores = data.map((e) => e as Map<String, dynamic>).toList();
          proveedoresFiltrados = proveedores;
        });
      } else {
        throw Exception('Error al cargar los proveedores');
      }
    } catch (error) {
      print('Error al obtener los proveedores: $error');
    }
  }

  String _formatDate(String date) {
    try {
      final DateTime parsedDate = DateTime.parse(date).toLocal();
      final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm');
      return formatter.format(parsedDate);
    } catch (e) {
      return 'Fecha inválida';
    }
  }

  void _filterProveedores() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      proveedoresFiltrados = proveedores.where((proveedor) {
        return (proveedor['nombre'] as String).toLowerCase().contains(query);
      }).toList();
    });
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
      String nombre,
      String direccion,
      String contacto,
      String correo,
      String clasificacion,
      String tipoPersona,
      String leyTributaria) async {
    final url = Uri.parse('http://localhost:3000/api/proveedores/$id');
    final Map<String, dynamic> body = {
      'nombre': nombre,
      'direccion': direccion,
      'contacto': contacto,
      'correo': correo,
      'clasificacion': clasificacion,
      'tipo_persona': tipoPersona,
      'ley_tributaria': leyTributaria,
    };

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        await _showAlertDialog(
          'Éxito',
          'Proveedor actualizado exitosamente',
          Icons.check_circle,
          Colors.green,
        );
        // Después de actualizar, recarga la lista de proveedores
        _fetchProveedores();
      } else {
        await _showAlertDialog(
          'Error',
          'Error al actualizar el proveedor',
          Icons.error,
          Colors.red,
        );
      }
    } catch (e) {
      await _showAlertDialog(
        'Error',
        'Error al actualizar el proveedor: $e',
        Icons.error,
        Colors.red,
      );
    }
  }

  /// Muestra un diálogo modal para editar los datos de un proveedor.
Future<void> _showEditProveedorDialog(Map<String, dynamic> proveedorData) async {
  final TextEditingController nombreController =
      TextEditingController(text: proveedorData['nombre'] ?? '');
  final TextEditingController direccionController =
      TextEditingController(text: proveedorData['direccion'] ?? '');
  final TextEditingController contactoController =
      TextEditingController(text: proveedorData['contacto'] ?? '');
  final TextEditingController correoController =
      TextEditingController(text: proveedorData['correo'] ?? '');
  final TextEditingController leyTributariaController =
      TextEditingController(text: proveedorData['ley_tributaria'] ?? '');
  final TextEditingController clasificacionController =
      TextEditingController(text: proveedorData['clasificacion'] ?? '');

  String tipoPersonaValue = proveedorData['tipo_persona'] ?? 'Natural';
  String clasificacionValue = proveedorData['clasificacion'] ?? 'Microempresa';

  return showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setStateModal) {
          return AlertDialog(
            title: const Text(
              'Editar Proveedor',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField('Nombre', Icons.business, nombreController),
                  _buildTextField('Dirección', Icons.location_on, direccionController),
                  _buildTextField('Contacto', Icons.phone, contactoController),
                  _buildTextField('Correo', Icons.email, correoController),
                  _buildDropdown(
                    'Tipo de Persona',
                    Icons.person,
                    tipoPersonaValue,
                    ['Natural', 'Jurídica'],
                    (value) {
                      setStateModal(() {
                        tipoPersonaValue = value!;
                      });
                    },
                  ),
                  _buildDropdown(
                    'Clasificación',
                    Icons.category,
                    clasificacionValue,
                    ['Microempresa', 'PequenaEmpresa', 'MedianaEmpresa', 'GranEmpresa'],
                    (value) {
                      setStateModal(() {
                        clasificacionValue = value!;
                      });
                    },
                  ),
                  _buildTextField('Ley Tributaria', Icons.gavel, leyTributariaController),
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

                  if (nombreController.text.trim().isEmpty ||
                      direccionController.text.trim().isEmpty ||
                      contactoController.text.trim().isEmpty ||
                      correoController.text.trim().isEmpty ||
                      clasificacionController.text.trim().isEmpty ||
                      leyTributariaController.text.trim().isEmpty) {
                    await _showAlertDialog(
                      'Error',
                      'Todos los campos son obligatorios',
                      Icons.warning,
                      Colors.orange,
                    );
                    return;
                  }

                  await _updateProveedor(
                    proveedorData['id'],
                    nombreController.text.trim(),
                    direccionController.text.trim(),
                    contactoController.text.trim(),
                    correoController.text.trim(),
                    clasificacionValue,
                    tipoPersonaValue,
                    leyTributariaController.text.trim(),
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


  /// Genera un campo de texto con icono.
  Widget _buildTextField(
      String label, IconData icon, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        ),
        textInputAction: TextInputAction.next,
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
    // AppBar con título personalizado y botón de regreso
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                      columns: const [
                        DataColumn(
                            label: Text('Nombre',
                                style:
                                    TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Dirección',
                                style:
                                    TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Contacto',
                                style:
                                    TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Correo',
                                style:
                                    TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Clasificación',
                                style:
                                    TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Tipo Persona',
                                style:
                                    TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Ley Tributaria',
                                style:
                                    TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Acciones',
                                style:
                                    TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: proveedoresFiltrados
                          .map(
                            (proveedor) => DataRow(
                              cells: [
                                DataCell(Text(proveedor['nombre'] ?? '')),
                                DataCell(Text(proveedor['direccion'] ?? '')),
                                DataCell(Text(proveedor['contacto'] ?? '')),
                                DataCell(Text(proveedor['correo'] ?? '')),
                                DataCell(
                                    Text(proveedor['clasificacion'] ?? '')),
                                DataCell(
                                    Text(proveedor['tipo_persona'] ?? '')),
                                DataCell(
                                    Text(proveedor['ley_tributaria'] ?? '')),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.blue),
                                        onPressed: () =>
                                            _showEditProveedorDialog(
                                                proveedor),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () =>
                                            _confirmDelete(proveedor['id']),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
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

void _navegarARegistroProveedor() async {
  final resultado = await Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const RegistroProveedorScreen()),
  );

  if (resultado == true) {
    _fetchProveedores(); // Recargar proveedores si se agregó uno nuevo
  }
}

}
