import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Para formatear fecha y hora

void main() {
  runApp(HistorialApp());
}

class HistorialApp extends StatelessWidget {
  const HistorialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HistorialScreen(),
    );
  }
}

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  _HistorialScreenState createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
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
    final url = Uri.parse("http://localhost:3000/api/historial_ajustes");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          _historial =
              List<Map<String, dynamic>>.from(json.decode(response.body));
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

  // Función para formatear fecha y hora
  String _formatDateTime(String fecha) {
    try {
      DateTime dateTime = DateTime.parse(fecha);
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      return fecha; // Si hay error, mostrar sin cambios
    }
  }

  // Función para filtrar el historial en base a la búsqueda
  void _filterHistorial() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredHistorial = _historial.where((item) {
        String nombre = item["nombre"].toLowerCase();
        String descripcion = item["descripcion"].toLowerCase();
        String fecha = _formatDateTime(item["fecha"]).toLowerCase();
        return nombre.contains(query) ||
            descripcion.contains(query) ||
            fecha.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFAF0F8),
      appBar: AppBar(
        title:
            Text("Historial de Ajustes", style: TextStyle(color: Colors.black)),
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
                hintText: "Buscar por nombre, descripción o fecha...",
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
                        headingRowColor: WidgetStateColor.resolveWith(
                            (states) => Colors.white),
                        dataRowColor: WidgetStateColor.resolveWith(
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
                              label: Text("ID",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text("Código",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text("Nombre",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text("Descripción",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text("Precio",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text("Fecha",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text("Motivo",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: _filteredHistorial.map((item) {
                          return DataRow(cells: [
                            DataCell(Text(item["id"].toString())),
                            DataCell(Text(item["codigo"].toString())),
                            DataCell(Text(item["nombre"])),
                            DataCell(Text(item["descripcion"])),
                            DataCell(Text("\$${item["precio"]}")),
                            DataCell(Text(_formatDateTime(
                                item["fecha"]))), // Formatear fecha y hora
                            DataCell(Text(item["motivo"])),
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
