import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Para formatear fecha y hora

void main() {
  runApp(HistorialIngresoApp());
}

class HistorialIngresoApp extends StatelessWidget {
  const HistorialIngresoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HistorialIngresoScreen(),
    );
  }
}

class HistorialIngresoScreen extends StatefulWidget {
  const HistorialIngresoScreen({super.key});

  @override
  _HistorialIngresoScreenState createState() => _HistorialIngresoScreenState();
}

class _HistorialIngresoScreenState extends State<HistorialIngresoScreen> {
  List<Map<String, dynamic>> _historial = [];
  List<Map<String, dynamic>> _filteredHistorial = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchHistorial();
    _searchController.addListener(_filterHistorial);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchHistorial() async {
    final url = Uri.parse("http://localhost:3000/api/entradas");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          _historial = List<Map<String, dynamic>>.from(
              json.decode(response.body).map((item) {
            return {
              "comprobante": item["comprobante"] ?? "",
              "fecha_ingreso": item["fecha_ingreso"] ?? "",
              "codigo_producto": item["codigo_producto"] ?? "",
              "producto": item["producto"] ?? "",
              "cantidad": item["cantidad"] ?? 0,
              "nombre_comercial": item["nombre_comercial"] ?? "",
              "costo_unit": item["costo_unit"] ?? 0.0,
              "costo_total": item["costo_total"] ?? 0.0,
            };
          }));
          _filteredHistorial =
              _historial; // Inicialmente, todos los datos visibles
          _isLoading = false;
        });
      } else {
        throw Exception("Error al obtener los datos");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Error: $e");
    }
  }

  // Función para formatear fecha
  String _formatDate(String fecha) {
    try {
      DateTime dateTime = DateTime.parse(fecha);
      return DateFormat('dd/MM/yyyy').format(dateTime);
    } catch (e) {
      return fecha; // Si hay error, mostrar sin cambios
    }
  }

  // Función para filtrar el historial en base a la búsqueda
  void _filterHistorial() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredHistorial = _historial.where((item) {
        String producto = item["producto"].toLowerCase();
        String proveedor = item["nombre_comercial"].toLowerCase();
        String fecha = _formatDate(item["fecha_ingreso"]).toLowerCase();
        return producto.contains(query) ||
            proveedor.contains(query) ||
            fecha.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFAF0F8),
      appBar: AppBar(
        title: Text("Historial de Ingresos",
            style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Buscar por producto, proveedor o fecha...",
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 20,
                        headingRowColor: MaterialStateProperty.resolveWith(
                            (states) => Colors.white),
                        dataRowColor: MaterialStateProperty.resolveWith(
                            (states) => Colors.white),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                spreadRadius: 2)
                          ],
                        ),
                        columns: [
                          DataColumn(
                              label: Text("Comprobante",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text("Fecha Ingreso",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text("Código Producto",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text("Producto",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text("Cantidad",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text("Proveedor",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text("Costo Unitario",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text("Costo Total",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: _filteredHistorial.map((item) {
                          return DataRow(cells: [
                            DataCell(Text(item["comprobante"])),
                            DataCell(Text(_formatDate(item["fecha_ingreso"]))),
                            DataCell(Text(item["codigo_producto"])),
                            DataCell(Text(item["producto"])),
                            DataCell(Text(item["cantidad"].toString())),
                            DataCell(Text(item["nombre_comercial"])),
                            DataCell(Text("\$${item["costo_unit"]}")),
                            DataCell(Text("\$${item["costo_total"]}")),
                          ]);
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
