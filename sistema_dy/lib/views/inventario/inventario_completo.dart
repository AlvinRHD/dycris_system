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

  void _showEditDialog(Map<String, dynamic> inventario) {
    final TextEditingController nombreController = TextEditingController(text: inventario['nombre']);
    final TextEditingController descripcionController = TextEditingController(text: inventario['descripcion']);
    final TextEditingController marcaController = TextEditingController(text: inventario['marca']);
    final TextEditingController precioController = TextEditingController(text: inventario['precio_venta'].toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Editar Producto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nombreController, decoration: InputDecoration(labelText: 'Nombre')),
              TextField(controller: descripcionController, decoration: InputDecoration(labelText: 'Descripción')),
              TextField(controller: marcaController, decoration: InputDecoration(labelText: 'Marca')),
              TextField(controller: precioController, decoration: InputDecoration(labelText: 'Precio')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (nombreController.text.isEmpty || precioController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Por favor, completa todos los campos.')));
                  return;
                }

                double? precio = double.tryParse(precioController.text);
                if (precio == null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('El precio debe ser un número válido.')));
                  return;
                }

                _editProduct(inventario['id'], nombreController.text, descripcionController.text, marcaController.text, precio);
                Navigator.of(context).pop();
              },
              child: Text('Guardar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editProduct(int id, String nombre, String descripcion, String marca, double precio) async {
    final url = Uri.parse('http://localhost:3000/api/inventario/edit/$id');
    try {
      final response = await http.put(url, body: json.encode({
        'nombre': nombre,
        'descripcion': descripcion,
        'marca': marca,
        'precio_venta': precio,
        'motivo': 'Edición de producto'
      }), headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 200) {
        setState(() {
          final index = inventario.indexWhere((item) => item['id'] == id);
          if (index != -1) {
            inventario[index] = {
              ...inventario[index],
              'nombre': nombre,
              'descripcion': descripcion,
              'marca': marca,
              'precio_venta': precio,
            };
          }
        });
      } else {
        throw Exception('Error al editar el producto');
      }
    } catch (error) {
      print('Error al editar el producto: $error');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al editar el producto.')));
    }
  }

  Future<void> _deleteProduct(int id) async {
    final url = Uri.parse('http://localhost:3000/api/inventario/$id');
    try {
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        _fetchInventarioCompleto(); // Refrescar la lista
      } else {
        throw Exception('Error al eliminar el producto');
      }
    } catch (error) {
      print('Error al eliminar el producto: $error');
    }
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
                border: Border.all(color: const Color.fromARGB(255, 160, 6, 6)),
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
                        DataColumn(label: Text('Código', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Nombre', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Descripción', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Marca', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Color', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Número Motor', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Número Chasis', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Precio Venta', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Categoría', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Sucursal', style: TextStyle(fontWeight: FontWeight.bold))), 
                        DataColumn(label: Text('Existencia', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Poliza', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: productosFiltrados.map((inventario) => DataRow(
                        cells: [
                          DataCell(Text(inventario['codigo'] ?? '')),
                          DataCell(Text(inventario['nombre'] ?? '')),
                          DataCell(Text(inventario['descripcion'] ?? '')),
                          DataCell(Text(inventario['marca'] ?? '')),
                          DataCell(Text(inventario['color'] ?? '')),
                          DataCell(Text(inventario['numero_motor'] ?? '')),
                          DataCell(Text(inventario['numero_chasis'] ?? '')),
                          DataCell(Text('\$${inventario['precio_venta']?.toString() ?? '0'}')),
                          DataCell(Text(inventario['categoria'] ?? '')),
                          DataCell(Text(inventario['sucursal'] ?? '')),
                          DataCell(Text(inventario['stock_existencia']?.toString() ?? '0')),
                          DataCell(Text(inventario['poliza'] ?? '')),
                          DataCell(Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () => _showEditDialog(inventario),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () => _deleteProduct(inventario['id']),
                              ),
                            ],
                          )),
                        ],
                      )).toList(),
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