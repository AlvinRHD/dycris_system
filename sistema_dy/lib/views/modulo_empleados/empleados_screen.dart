import 'dart:ui'; // Para PointerDeviceKind
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'editar_empleado_modal.dart';
import 'nuevo_empleado_modal.dart';

class EmpleadosScreen extends StatefulWidget {
  const EmpleadosScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _EmpleadosScreenState createState() => _EmpleadosScreenState();
}

class _EmpleadosScreenState extends State<EmpleadosScreen> {
  List<Map<String, dynamic>> empleados = [];
  List<Map<String, dynamic>> empleadosFiltrados = [];
  final TextEditingController _searchController = TextEditingController();

  // Variables para filtrar por sucursal
  String selectedSucursalFilter = 'Todas';
  List<String> sucursalesFilter = ['Todas'];

  // Variable para filtrar por estado
  String selectedEstadoFilter = 'Todos';
  final List<String> estadosFilter = ['Todos', 'Activo', 'Inactivo'];

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
    _fetchEmpleados();
    _searchController.addListener(_filterEmpleados);
  }

  Future<void> _fetchEmpleados() async {
    final url = Uri.parse('http://localhost:3000/api/empleados');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          empleados = data.map((e) => e as Map<String, dynamic>).toList();
          // Extraer las sucursales únicas de los empleados:
          Set<String> set = {};
          for (var empleado in empleados) {
            String suc = empleado['sucursal']?.toString() ?? '';
            if (suc.isNotEmpty) set.add(suc);
          }
          sucursalesFilter = ['Todas', ...set];
          // Inicialmente se muestran todos
          empleadosFiltrados = empleados;
        });
        _filterEmpleados();
      } else {
        throw Exception('Error al cargar los empleados');
      }
    } catch (error) {
      // ignore: avoid_print
      print('Error al obtener empleados: $error');
    }
  }

  void _filterEmpleados() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      empleadosFiltrados = empleados.where((empleado) {
        bool matchesSearch = (empleado['nombres']?.toString().toLowerCase() ?? '')
                .contains(query) ||
            (empleado['apellidos']?.toString().toLowerCase() ?? '')
                .contains(query) ||
            (empleado['codigo_empleado']?.toString().toLowerCase() ?? '')
                .contains(query);
        bool matchesSucursal = true;
        if (selectedSucursalFilter != 'Todas') {
          matchesSucursal = (empleado['sucursal']?.toString().toLowerCase() ?? '') ==
              selectedSucursalFilter.toLowerCase();
        }
        bool matchesEstado = true;
        if (selectedEstadoFilter != 'Todos') {
          matchesEstado = (empleado['estado']?.toString() ?? '') == selectedEstadoFilter;
        }
        return matchesSearch && matchesSucursal && matchesEstado;
      }).toList();
    });
  }

  ButtonStyle _alertButtonStyle() {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.pressed)) {
          return const Color.fromARGB(255, 18, 122, 234).withOpacity(0.15);
        }
        return Theme.of(context).dialogBackgroundColor;
      }),
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

  Future<void> _deleteEmpleado(int id) async {
    final url = Uri.parse('http://localhost:3000/api/empleados/$id');
    try {
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        await _showAlertDialog(
          'Éxito',
          'Empleado eliminado exitosamente',
          Icons.check_circle,
          Colors.green,
        );
        _fetchEmpleados();
      } else {
        await _showAlertDialog(
          'Error',
          'Error al eliminar el empleado',
          Icons.error,
          Colors.red,
        );
      }
    } catch (e) {
      await _showAlertDialog(
        'Error',
        'Error al eliminar el empleado: $e',
        Icons.error,
        Colors.red,
      );
    }
  }

  Future<void> _confirmDelete(int id) async {
    final empleado = empleados.firstWhere((e) => e['id'] == id);
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
        content: Text(
            '¿Está seguro de eliminar a ${empleado['nombres']} ${empleado['apellidos']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: _alertButtonStyle(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: _alertButtonStyle(),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _deleteEmpleado(empleado['id']);
    }
  }

  Future<void> _showEditEmpleadoDialog(Map<String, dynamic> empleadoData) async {
    await showDialog(
      context: context,
      builder: (context) => EditarEmpleadoModal(
        empleadoData: empleadoData,
        onEmpleadoUpdated: () {
          _fetchEmpleados();
          setState(() {});
        },
      ),
    );
  }

  void _showNuevoEmpleadoModal() {
    showDialog(
      context: context,
      builder: (context) => NuevoEmpleadoModal(
        onEmpleadoAdded: _fetchEmpleados,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gestión de Empleados',
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
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  )
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
                        hintText: 'Buscar empleado...',
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 14),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Dropdown para filtrar por sucursal
                  SizedBox(
                    width: 200,
                    child: DropdownButtonFormField<String>(
                      value: selectedSucursalFilter,
                      decoration:
                          _inputDecoration('Sucursal', Icons.location_city),
                      items: sucursalesFilter
                          .map((sucursal) => DropdownMenuItem(
                                value: sucursal,
                                child: Text(sucursal),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedSucursalFilter = value!;
                          _filterEmpleados();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Dropdown para filtrar por estado
                  SizedBox(
                    width: 200,
                    child: DropdownButtonFormField<String>(
                      value: selectedEstadoFilter,
                      decoration: _inputDecoration('Estado', Icons.toggle_on),
                      items: estadosFilter
                          .map((estado) => DropdownMenuItem(
                                value: estado,
                                child: Text(estado),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedEstadoFilter = value!;
                          _filterEmpleados();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _showNuevoEmpleadoModal,
                    icon: const Icon(Icons.person_add_alt_1, size: 20),
                    label: const Text('Nuevo Empleado'),
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
                    )
                  ],
                ),
                // Configuración para admitir desplazamiento con mouse
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                    },
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
                            (states) => Colors.grey[50]!,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black12),
                          ),
                          columns: const [
                            DataColumn(
                              label: Text('Código', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            DataColumn(
                              label: Text('Nombres', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            DataColumn(
                              label: Text('Apellidos', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            DataColumn(
                              label: Text('Dirección', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            DataColumn(
                              label: Text('Teléfono', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            DataColumn(
                              label: Text('Celular', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            DataColumn(
                              label: Text('DUI', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            DataColumn(
                              label: Text('Profesión', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            DataColumn(
                              label: Text('AFP', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            DataColumn(
                              label: Text('ISSS', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            DataColumn(
                              label: Text('Correo', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            DataColumn(
                              label: Text('Cargo', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            DataColumn(
                              label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            DataColumn(
                              label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                          rows: empleadosFiltrados.map((empleado) {
                            return DataRow(
                              cells: [
                                DataCell(Text(empleado['codigo_empleado'] ?? '')),
                                DataCell(Text(empleado['nombres'] ?? '')),
                                DataCell(Text(empleado['apellidos'] ?? '')),
                                DataCell(Text(empleado['direccion'] ?? '')),
                                DataCell(Text(empleado['telefono'] ?? '')),
                                DataCell(Text(empleado['celular'] ?? '')),
                                DataCell(Text(empleado['dui'] ?? '')),
                                DataCell(Text(empleado['profesion'] ?? '')),
                                DataCell(Text(empleado['afp'] ?? '')),
                                DataCell(Text(empleado['isss'] ?? '')),
                                DataCell(Text(empleado['correo'] ?? '')),
                                DataCell(Text(empleado['cargo'] ?? '')),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: empleado['estado'] == 'Activo'
                                          ? Colors.green[100]
                                          : Colors.red[100],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      empleado['estado'] ?? '',
                                      style: TextStyle(
                                        color: empleado['estado'] == 'Activo'
                                            ? Colors.green[800]
                                            : Colors.red[800],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _showEditEmpleadoDialog(empleado),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _confirmDelete(empleado['id']),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
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
}
