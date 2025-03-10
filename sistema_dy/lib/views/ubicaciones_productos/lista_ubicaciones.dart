import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sistema_dy/views/ubicaciones_productos/registrar_ubicacion.dart';

class ListaUbicaciones extends StatefulWidget {
  @override
  _ListaUbicacionesState createState() => _ListaUbicacionesState();
}

class _ListaUbicacionesState extends State<ListaUbicaciones> {
  late Future<List<dynamic>> ubicaciones;
  late Future<List<dynamic>> sucursales; // Nueva variable para las sucursales
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> ubicacionesFiltradas = [];
  List<dynamic> sucursalesFiltradas = []; // Para almacenar las sucursales

  @override
  void initState() {
    super.initState();
    ubicaciones = fetchUbicaciones();
    sucursales = fetchSucursales(); // Cargar sucursales
    _searchController.addListener(_filterUbicaciones);
  }

  Future<List<dynamic>> fetchUbicaciones() async {
    final url = Uri.parse("http://localhost:3000/api/ubicaciones_productos");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        ubicacionesFiltradas = data;
      });
      return data;
    } else {
      mostrarSnackBar("Error al cargar las ubicaciones", Colors.red);
      throw Exception("Error al cargar las ubicaciones");
    }
  }

  Future<List<dynamic>> fetchSucursales() async {
    final url = Uri.parse("http://localhost:3000/api/sucursal");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        sucursalesFiltradas = data; // Guardar las sucursales
      });
      return data;
    } else {
      mostrarSnackBar("Error al cargar las sucursales", Colors.red);
      throw Exception("Error al cargar las sucursales");
    }
  }

  void _filterUbicaciones() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      ubicacionesFiltradas = ubicacionesFiltradas.where((ubicacion) {
        return (ubicacion['ubicacion'] as String).toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> eliminarUbicacion(int id) async {
    bool confirmar = await mostrarDialogoConfirmacion(id);
    if (!confirmar) return;

    final url = Uri.parse("http://localhost:3000/api/ubicaciones_productos/$id");
    final response = await http.delete(url);

    if (response.statusCode == 200) {
      await fetchUbicaciones(); // Actualiza la lista después de eliminar
      mostrarSnackBar("Ubicación eliminada correctamente", Colors.green);
    } else {
      mostrarSnackBar("Error al eliminar la ubicación", Colors.red);
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
            content: Text("¿Estás seguro de que deseas eliminar esta ubicación?"),
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

  void editarUbicacion(Map<String, dynamic> ubicacion) {
    TextEditingController ubicacionController =
        TextEditingController(text: ubicacion["ubicacion"]);
    TextEditingController descripcionController =
        TextEditingController(text: ubicacion["descripcion"]);
    String? sucursalSeleccionada = ubicacion["sucursal_id"].toString(); // ID de la sucursal

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Editar Ubicación',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FutureBuilder<List<dynamic>>(
                  future: sucursales,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text("Error al cargar sucursales");
                    } else {
                      return _buildDropdown(
                        'Sucursal',
                        Icons.store,
                        sucursalSeleccionada,
                        snapshot.data!.map((sucursal) {
                          return {
                            'id': sucursal['id'],
                            'nombre': sucursal['nombre'],
                          };
                        }).toList(),
                        (value) {
                          setState(() {
                            sucursalSeleccionada = value;
                          });
                        },
                      );
                    }
                  },
                ),
                _buildTextField('Ubicación', Icons.location_on, ubicacionController),
                _buildTextField('Descripción', Icons.description, descripcionController),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                await actualizarUbicacion(
                    ubicacion["id"],
                    sucursalSeleccionada,
                    ubicacionController.text,
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

  Future<void> actualizarUbicacion(
      int id, String? sucursalId, String ubicacion, String descripcion) async {
    final url = Uri.parse("http://localhost:3000/api/ubicaciones_productos/$id");
    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "sucursal_id": sucursalId,
        "ubicacion": ubicacion,
        "descripcion": descripcion,
      }),
    );

    if (response.statusCode == 200) {
      await fetchUbicaciones(); // Actualiza la lista después de actualizar
      mostrarSnackBar("Ubicación actualizada correctamente", Colors.green);
    } else {
      mostrarSnackBar("Error al actualizar la ubicación", Colors.red);
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
          'Lista de Ubicaciones',
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
                        hintText: 'Buscar ubicación...',
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
                          builder: (context) => RegistrarUbicacion(
                              actualizarLista: fetchUbicaciones),
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
            // Contenedor con la tabla de ubicaciones
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
                              label: Text('Sucursal',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Ubicación',
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
                        rows: ubicacionesFiltradas
                            .map(
                              (ubicacion) => DataRow(
                                cells: [
                                  DataCell(Text(ubicacion['sucursal_nombre'] ?? '')),

                                  DataCell(Text(ubicacion['ubicacion'] ?? '')),
                                  DataCell(Text(ubicacion['descripcion'] ?? '')),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue),
                                          onPressed: () => editarUbicacion(ubicacion),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => eliminarUbicacion(ubicacion['id']),
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

  Widget _buildDropdown(String label, IconData icon, String? value,
      List<Map<String, dynamic>> items, ValueChanged<String?> onChanged) {
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
            value: item['id'].toString(), // Usar el ID de la sucursal
            child: Text(item['nombre']), // Mostrar el nombre de la sucursal
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}