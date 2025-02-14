import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class VentasScreen extends StatefulWidget {
  @override
  _VentasScreenState createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> {
  List ventas = [];

  @override
  void initState() {
    super.initState();
    fetchVentas();
  }

  Future<void> fetchVentas() async {
    final response =
        await http.get(Uri.parse('http://localhost:3000/api/ventas'));
    if (response.statusCode == 200) {
      setState(() {
        ventas = jsonDecode(response.body);
      });
    } else {
      print("Error al cargar ventas");
    }
  }

  Future<void> eliminarVenta(int id) async {
    final response =
        await http.delete(Uri.parse('http://localhost:3000/api/ventas/$id'));
    if (response.statusCode == 200) {
      setState(() {
        ventas.removeWhere((venta) => venta['id'] == id);
      });
    } else {
      print("Error al eliminar venta");
    }
  }

  void editarVenta(int id) {
    // Aquí iría la lógica para editar una venta
    print("Editar venta con ID: $id");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ventas')),
      body: ventas.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: ventas.length,
              itemBuilder: (context, index) {
                final venta = ventas[index];
                return Card(
                  child: ListTile(
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => editarVenta(venta['id']),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => eliminarVenta(venta['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
