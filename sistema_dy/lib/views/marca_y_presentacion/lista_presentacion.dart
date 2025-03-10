import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sistema_dy/views/marca_y_presentacion/registrar_presentacion.dart';
import 'dart:convert';

class ListaPresentaciones extends StatefulWidget {
  @override
  _ListaPresentacionesState createState() => _ListaPresentacionesState();
}

class _ListaPresentacionesState extends State<ListaPresentaciones> {
  late Future<List<dynamic>> presentaciones;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> presentacionesFiltradas = [];

  @override
  void initState() {
    super.initState();
    presentaciones = fetchPresentaciones();
    _searchController.addListener(_filterPresentaciones);
  }

  Future<List<dynamic>> fetchPresentaciones() async {
    final url = Uri.parse("http://localhost:3000/api/presentacion");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        presentacionesFiltradas = data;
      });
      return data;
    } else {
      throw Exception("Error al cargar las presentaciones");
    }
  }

  void _filterPresentaciones() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      presentacionesFiltradas = presentacionesFiltradas.where((presentacion) {
        return (presentacion['nombre'] as String).toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> eliminarPresentacion(int id) async {
    bool confirmar = await mostrarDialogoConfirmacion(id);
    if (!confirmar) return;

    final url = Uri.parse("http://localhost:3000/api/presentacion/$id");
    final response = await http.delete(url);

    if (response.statusCode == 200) {
      setState(() {
        presentaciones = fetchPresentaciones();
      });
      mostrarSnackBar("Presentación eliminada correctamente", Colors.green);
    } else {
      mostrarSnackBar("Error al eliminar la presentación", Colors.red);
    }
  }

  Future<bool> mostrarDialogoConfirmacion(int id) async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 8),
                Text('Confirmar eliminación'),
              ],
            ),
            content: Text("¿Estás seguro de que deseas eliminar esta presentación?"),
            actions: [
              TextButton(
                child: Text("Cancelar"),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: Text("Eliminar", style: TextStyle(color: Colors.red)),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ) ??
        false;
  }

  void editarPresentacion(Map<String, dynamic> presentacion) {
    TextEditingController nombreController =
        TextEditingController(text: presentacion["nombre"]);
    TextEditingController descripcionController =
        TextEditingController(text: presentacion["descripcion"]);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Editar Presentación',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField('Nombre', Icons.business, nombreController),
                _buildTextField(
                    'Descripción', Icons.description, descripcionController),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                await actualizarPresentacion(
                    presentacion["id"],
                    nombreController.text,
                    descripcionController.text);
                Navigator.of(context).pop();
              },
              child: const Text('Guardar cambios'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> actualizarPresentacion(int id, String nombre, String descripcion) async {
    final url = Uri.parse("http://localhost:3000/api/presentacion/$id");
    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "nombre": nombre,
        "descripcion": descripcion,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        presentaciones = fetchPresentaciones();
      });
      mostrarSnackBar("Presentación actualizada correctamente", Colors.green);
    } else {
      mostrarSnackBar("Error al actualizar la presentación", Colors.red);
    }
  }

  void mostrarSnackBar(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mensaje),
      backgroundColor: color,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lista de Presentaciones',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
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
                        hintText: 'Buscar presentación...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RegistrarPresentacion(
                              actualizarLista: fetchPresentaciones),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_to_photos, size: 20),
                    label: const Text('Agregar nuevo'),
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
            // Contenedor con la tabla de presentaciones
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
                        dataRowHeight: 80,
                        headingRowColor:
                            MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) => Colors.grey[50]!,
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
                              label: Text('Descripción',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Acciones',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: presentacionesFiltradas
                            .map(
                              (presentacion) => DataRow(
                                cells: [
                                  DataCell(Text(presentacion['nombre'] ?? '')),
                                  DataCell(
                                      Text(presentacion['descripcion'] ?? '')),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit,
                                              color: Colors.blue),
                                          onPressed: () =>
                                              editarPresentacion(presentacion),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () => eliminarPresentacion(
                                              presentacion['id']),
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
}