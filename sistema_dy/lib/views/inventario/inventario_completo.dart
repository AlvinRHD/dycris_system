import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class InventarioCompletoScreen extends StatefulWidget {
  const InventarioCompletoScreen({super.key});

  @override
  _InventarioCompletoScreenState createState() =>
      _InventarioCompletoScreenState();
}

class _InventarioCompletoScreenState extends State<InventarioCompletoScreen> {
  List<Map<String, dynamic>> inventario = [];
  List<Map<String, dynamic>> productosFiltrados = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchInventarioCompleto();
    _searchController.addListener(_filterProductosCompletos);
  }

  Future<void> _fetchInventarioCompleto() async {
    final url =
        Uri.parse('http://localhost:3000/api/inventario?tipo=detallado');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print("Datos recibidos: $data");
        setState(() {
          inventario = data.map((e) => e as Map<String, dynamic>).toList();
          productosFiltrados = inventario;
        });
      } else {
        throw Exception('Error al cargar el inventario');
      }
    } catch (error) {
      print('Error al obtener el inventario: $error');
    }
  }

  String _formatDate(String date) {
    try {
      final DateTime parsedDate = DateTime.parse(date);
      final DateFormat formatter = DateFormat('yyyy-MM-dd');
      return formatter.format(parsedDate);
    } catch (e) {
      return '';
    }
  }

  void _filterProductosCompletos() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      productosFiltrados = inventario.where((inventario) {
        return (inventario['nombre'] as String).toLowerCase().contains(query);
      }).toList();
    });
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
          'Productos Registrados',
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
                        hintText: 'Buscar producto...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Contenedor con la tabla de productos
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
                              label: Text('Código',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Imagen',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Nombre',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Descripcion',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Número Motor',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Número Chasis',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Categoría',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Sucursal',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Costo',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Crédito',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Precio Venta',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Existencia',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Stock Mínimo',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Fecha Ingreso',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Fecha Reingreso',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Número Póliza',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Número Lote',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Proveedor',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: productosFiltrados
                            .map(
                              (inventario) => DataRow(
                                cells: [
                                  DataCell(Text(inventario['codigo'] ?? '')),
                                  DataCell(
                                    Image.network(
                                      'http://localhost:3000' +
                                          (inventario['imagen'] ??
                                              '/uploads/empty.png'),
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                      errorBuilder: (BuildContext context,
                                          Object error,
                                          StackTrace? stackTrace) {
                                        return Image.network(
                                          'http://localhost:3000/uploads/empty.png',
                                          width: 70,
                                          height: 70,
                                          fit: BoxFit.cover,
                                        );
                                      },
                                    ),
                                  ),
                                  DataCell(Text(inventario['nombre'] ?? '')),
                                  DataCell(
                                      Text(inventario['descripcion'] ?? '')),
                                  DataCell(
                                      Text(inventario['numero_motor'] ?? '')),
                                  DataCell(
                                      Text(inventario['numero_chasis'] ?? '')),
                                  DataCell(Text(inventario['categoria'] ?? '')),
                                  DataCell(Text(inventario['sucursal'] ?? '')),
                                  DataCell(Text(
                                      inventario['costo']?.toString() ?? '0')),
                                  DataCell(Text(
                                      inventario['credito']?.toString() ??
                                          '0')),
                                  DataCell(Text(
                                      inventario['precio_venta']?.toString() ??
                                          '0')),
                                  DataCell(Text(inventario['stock_existencia']
                                          ?.toString() ??
                                      '0')),
                                  DataCell(Text(
                                      inventario['stock_minimo']?.toString() ??
                                          '0')),
                                  DataCell(Text(_formatDate(
                                      inventario['fecha_ingreso'] ?? ''))),
                                  DataCell(Text(_formatDate(
                                      inventario['fecha_reingreso'] ?? ''))),
                                  DataCell(
                                      Text(inventario['numero_poliza'] ?? '')),
                                  DataCell(
                                      Text(inventario['numero_lote'] ?? '')),
                                  DataCell(
                                      Text(inventario['proveedores'] ?? '')),
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
}
