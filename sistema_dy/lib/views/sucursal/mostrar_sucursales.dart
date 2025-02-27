import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sistema_dy/views/sucursal/registrar_sucursal.dart';

class MostrarSucursales extends StatefulWidget {
  @override
  _MostrarSucursalesState createState() => _MostrarSucursalesState();
}

class _MostrarSucursalesState extends State<MostrarSucursales> {
  List<dynamic> sucursales = [];
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> sucursalesFiltradas = [];

  @override
  void initState() {
    super.initState();
    fetchSucursales();
    _searchController.addListener(_filterSucursales);
  }

  Future<void> fetchSucursales() async {
    try {
      final response =
          await http.get(Uri.parse('http://localhost:3000/api/sucursal'));

      if (response.statusCode == 200) {
        setState(() {
          sucursales = json.decode(response.body);
          sucursalesFiltradas = sucursales;
        });
      } else {
        throw Exception('Error al cargar sucursales');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void _filterSucursales() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      sucursalesFiltradas = sucursales.where((sucursal) {
        return (sucursal['nombre'] as String).toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> deleteSucursal(int id) async {
    final response =
        await http.delete(Uri.parse('http://localhost:3000/api/sucursal/$id'));

    if (response.statusCode == 200) {
      setState(() {
        sucursales.removeWhere((sucursal) => sucursal['id'] == id);
        sucursalesFiltradas = sucursales;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sucursal eliminada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (response.statusCode == 404) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sucursal no encontrada'),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar la sucursal'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void editSucursal(Map<String, dynamic> sucursal) {
    TextEditingController codigoController =
        TextEditingController(text: sucursal['codigo'] ?? '');
    TextEditingController nombreController =
        TextEditingController(text: sucursal['nombre'] ?? '');
    TextEditingController ciudadController =
        TextEditingController(text: sucursal['ciudad'] ?? '');
    TextEditingController departamentoController =
        TextEditingController(text: sucursal['departamento'] ?? '');
    TextEditingController paisController =
        TextEditingController(text: sucursal['pais'] ?? '');
    String estadoSeleccionado = sucursal['estado'] ?? 'Inactivo';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Editar Sucursal',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField('Código', Icons.code, codigoController),
                _buildTextField('Nombre', Icons.business, nombreController),
                _buildTextField(
                    'Ciudad', Icons.location_city, ciudadController),
                _buildTextField(
                    'Departamento', Icons.map, departamentoController),
                _buildTextField('País', Icons.public, paisController),
                _buildDropdown('Estado', Icons.toggle_on, estadoSeleccionado,
                    ["Activo", "Inactivo"], (value) {
                  setState(() {
                    estadoSeleccionado = value!;
                  });
                }),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                updateSucursal(
                  sucursal['id'],
                  codigoController.text,
                  nombreController.text,
                  ciudadController.text,
                  departamentoController.text,
                  paisController.text,
                  estadoSeleccionado,
                );
                Navigator.pop(context);
              },
              child: const Text('Guardar cambios'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> updateSucursal(int id, String codigo, String nombre,
      String ciudad, String departamento, String pais, String estado) async {
    final response = await http.put(
      Uri.parse('http://localhost:3000/api/sucursal/$id'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "codigo": codigo,
        "nombre": nombre,
        "ciudad": ciudad,
        "departamento": departamento,
        "pais": pais,
        "estado": estado,
      }),
    );

    if (response.statusCode == 200) {
      fetchSucursales();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sucursal actualizada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar la sucursal'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lista de Sucursales',
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
                        hintText: 'Buscar sucursal...',
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
                          builder: (context) => RegistrarSucursal(
                              actualizarLista: fetchSucursales),
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
            // Contenedor con la tabla de sucursales
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
                              label: Text('ID',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Código',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Nombre',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Ciudad',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Departamento',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('País',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Estado',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Acciones',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: sucursalesFiltradas.map((sucursal) {
                          return DataRow(cells: [
                            DataCell(Text(sucursal['id'].toString())),
                            DataCell(Text(sucursal['codigo'] ?? 'Sin código')),
                            DataCell(Text(sucursal['nombre'] ?? 'Sin nombre')),
                            DataCell(Text(sucursal['ciudad'] ?? 'Sin ciudad')),
                            DataCell(Text(sucursal['departamento'] ??
                                'Sin departamento')),
                            DataCell(Text(sucursal['pais'] ?? 'Sin país')),
                            DataCell(
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: sucursal['estado'] == 'Activo'
                                      ? Colors.green
                                      : Colors.red,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  sucursal['estado'] ?? 'Sin estado',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            DataCell(Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => editSucursal(sucursal),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Row(
                                          children: [
                                            Icon(Icons.warning,
                                                color: Colors.orange),
                                            SizedBox(width: 8),
                                            Text('Confirmar eliminación'),
                                          ],
                                        ),
                                        content: Text(
                                            '¿Estás seguro de que deseas eliminar esta sucursal?'),
                                        actions: [
                                          TextButton(
                                            child: Text('Cancelar'),
                                            onPressed: () =>
                                                Navigator.pop(context),
                                          ),
                                          TextButton(
                                            child: Text('Eliminar',
                                                style: TextStyle(
                                                    color: Colors.red)),
                                            onPressed: () {
                                              deleteSucursal(sucursal['id']);
                                              Navigator.pop(context);
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            )),
                          ]);
                        }).toList(),
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
}
