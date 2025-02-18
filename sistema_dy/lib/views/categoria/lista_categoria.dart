import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sistema_dy/views/categoria/registrar_categoria.dart';

class ListaCategorias extends StatefulWidget {
  @override
  _ListaCategoriasState createState() => _ListaCategoriasState();
}

class _ListaCategoriasState extends State<ListaCategorias> {
  late Future<List<dynamic>> categorias;

  @override
  void initState() {
    super.initState();
    categorias = fetchCategorias();
  }

  Future<List<dynamic>> fetchCategorias() async {
    final url = Uri.parse("http://localhost:3000/api/categoria");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error al cargar las categorías");
    }
  }

  Future<void> eliminarCategoria(int id) async {
    bool confirmar = await mostrarDialogoConfirmacion(id);
    if (!confirmar) return;

    final url = Uri.parse("http://localhost:3000/api/categoria/$id");
    final response = await http.delete(url);

    if (response.statusCode == 200) {
      setState(() {
        categorias = fetchCategorias();
      });
      mostrarSnackBar("Categoría eliminada correctamente", Colors.green);
    } else {
      mostrarSnackBar("Error al eliminar la categoría", Colors.red);
    }
  }

  Future<bool> mostrarDialogoConfirmacion(int id) async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Confirmar eliminación"),
            content:
                Text("¿Estás seguro de que deseas eliminar esta categoría?"),
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

  void editarCategoria(Map<String, dynamic> categoria) {
    TextEditingController nombreController =
        TextEditingController(text: categoria["nombre"]);
    TextEditingController descripcionController =
        TextEditingController(text: categoria["descripcion"]);
    String estadoSeleccionado = categoria["estado"]; // Guardar el estado actual

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Editar Categoría"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: InputDecoration(labelText: "Nombre"),
              ),
              TextField(
                controller: descripcionController,
                decoration: InputDecoration(labelText: "Descripción"),
              ),
              DropdownButtonFormField(
                value: estadoSeleccionado,
                items: ["Activo", "Inactivo"].map((estado) {
                  return DropdownMenuItem(value: estado, child: Text(estado));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    estadoSeleccionado =
                        value.toString(); // Actualizar el estado seleccionado
                  });
                },
                decoration: InputDecoration(labelText: "Estado"),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text("Cancelar"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text("Guardar", style: TextStyle(color: Colors.blue)),
              onPressed: () async {
                await actualizarCategoria(
                    categoria["id"],
                    nombreController.text,
                    descripcionController.text,
                    estadoSeleccionado);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> actualizarCategoria(
      int id, String nombre, String descripcion, String estado) async {
    final url = Uri.parse("http://localhost:3000/api/categoria/$id");
    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "nombre": nombre,
        "descripcion": descripcion,
        "estado": estado,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        categorias = fetchCategorias();
      });
      mostrarSnackBar("Categoría actualizada correctamente", Colors.green);
    } else {
      mostrarSnackBar("Error al actualizar la categoría", Colors.red);
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
        title: Text("Lista de Categorías"),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                categorias = fetchCategorias();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: categorias,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error al cargar datos"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No hay categorías registradas"));
          } else {
            return Padding(
              padding: EdgeInsets.all(10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 30,
                  border: TableBorder.all(color: Colors.grey),
                  columns: [
                    DataColumn(
                        label: Text("Nombre",
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text("Descripción",
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text("Estado",
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text("Acciones",
                            style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: snapshot.data!.map<DataRow>((categoria) {
                    return DataRow(cells: [
                      DataCell(Text(categoria["nombre"])),
                      DataCell(Text(categoria["descripcion"])),
                      DataCell(
                        Text(
                          categoria["estado"],
                          style: TextStyle(
                            color: categoria["estado"] == "Activo"
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataCell(Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              editarCategoria(categoria);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              eliminarCategoria(categoria["id"]);
                            },
                          ),
                        ],
                      )),
                    ]);
                  }).toList(),
                ),
              ),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RegistrarCategoria(),
            ),
          );
        },
      ),
    );
  }
}
