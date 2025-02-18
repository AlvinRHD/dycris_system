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

  @override
  void initState() {
    super.initState();
    fetchSucursales();
  }

  Future<void> fetchSucursales() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/api/sucursal'));

      if (response.statusCode == 200) {
        setState(() {
          sucursales = json.decode(response.body);
        });
      } else {
        throw Exception('Error al cargar sucursales');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> deleteSucursal(int id) async {
    final response = await http.delete(Uri.parse('http://localhost:3000/api/sucursal/$id'));

    if (response.statusCode == 200) {
      setState(() {
        sucursales.removeWhere((sucursal) => sucursal['id'] == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sucursal eliminada exitosamente')),
      );
    } else if (response.statusCode == 404) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sucursal no encontrada')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar la sucursal')),
      );
    }
  }

  void editSucursal(Map<String, dynamic> sucursal) {
    TextEditingController codigoController = TextEditingController(text: sucursal['codigo'] ?? '');
    TextEditingController nombreController = TextEditingController(text: sucursal['nombre'] ?? '');
    TextEditingController ciudadController = TextEditingController(text: sucursal['ciudad'] ?? '');
    TextEditingController departamentoController = TextEditingController(text: sucursal['departamento'] ?? '');
    TextEditingController paisController = TextEditingController(text: sucursal['pais'] ?? '');

    // Guardar el estado original
    String estadoActual = sucursal['estado'] ?? 'Inactivo';
    String estadoSeleccionado = estadoActual; // Cambiar a String no nullable

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Editar Sucursal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: codigoController, decoration: InputDecoration(labelText: 'Código')),
                TextField(controller: nombreController, decoration: InputDecoration(labelText: 'Nombre')),
                TextField(controller: ciudadController, decoration: InputDecoration(labelText: 'Ciudad')),
                TextField(controller: departamentoController, decoration: InputDecoration(labelText: 'Departamento')),
                TextField(controller: paisController, decoration: InputDecoration(labelText: 'País')),
                DropdownButton<String>(
                  value: estadoSeleccionado,
                  items: <String>['Activo', 'Inactivo'].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      estadoSeleccionado = newValue ?? estadoActual; // Asegúrate de que no sea nulo
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancelar'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text('Actualizar', style: TextStyle(color: Colors.blue)),
              onPressed: () {
                // Asegúrate de que estadoSeleccionado no sea nulo
                updateSucursal(
                  sucursal['id'],
                  codigoController.text,
                  nombreController.text,
                  ciudadController.text,
                  departamentoController.text,
                  paisController.text,
                  estadoSeleccionado, // Usar el estado seleccionado
                );
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> updateSucursal(int id, String codigo, String nombre, String ciudad, String departamento, String pais, String estado) async {
    final response = await http.put(
      Uri.parse('http://localhost:3000/api/sucursal/$id'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "codigo": codigo,
        "nombre": nombre,
        "ciudad": ciudad,
        "departamento": departamento,
        "pais": pais,
        "estado": estado, // Aquí se pasa el estado
      }),
    );

    if (response.statusCode == 200) {
      fetchSucursales();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sucursal actualizada correctamente')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar la sucursal')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Sucursales'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: fetchSucursales,
          ),
        ],
      ),
      body: sucursales.isEmpty
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Código')),
                  DataColumn(label: Text('Nombre')),
                  DataColumn(label: Text('Ciudad')),
                  DataColumn(label: Text('Departamento')),
                  DataColumn(label: Text('País')),
                  DataColumn(label: Text('Estado')),
                  DataColumn(label: Text('Acciones')),
                ],
                rows: sucursales.map((sucursal) {
                  return DataRow(cells: [
                    DataCell(Text(sucursal['id'].toString())),
                    DataCell(Text(sucursal['codigo'] ?? 'Sin código')),
                    DataCell(Text(sucursal['nombre'] ?? 'Sin nombre')),
                    DataCell(Text(sucursal['ciudad'] ?? 'Sin ciudad')),
                    DataCell(Text(sucursal['departamento'] ?? 'Sin departamento')),
                    DataCell(Text(sucursal['pais'] ?? 'Sin país')),
                    DataCell(
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: sucursal['estado'] == 'Activo' ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          sucursal['estado'] ?? 'Sin estado',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                                title: Text('Eliminar Sucursal'),
                                content: Text('¿Estás seguro de que deseas eliminar esta sucursal?'),
                                actions: [
                                  TextButton(
                                    child: Text('Cancelar'),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  TextButton(
                                    child: Text('Eliminar', style: TextStyle(color: Colors.red)),
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
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RegistrarSucursal(actualizarLista: fetchSucursales),
            ),
          );
        },
      ),
    );
  }
}