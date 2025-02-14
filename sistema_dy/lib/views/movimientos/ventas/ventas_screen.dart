import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'agregar_venta_modal.dart';
import 'clientes/agregar_cliente_modal.dart';
import 'clientes/clientes_screen.dart';
import 'editar_venta_screen.dart';
import 'ventas_controller.dart';

class VentasScreen extends StatefulWidget {
  @override
  _VentasScreenState createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> {
  final VentasController _ventasController = VentasController();
  List<dynamic> ventas = [];
  List<dynamic> filteredVentas = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarVentas();
    _searchController.addListener(_filtrarVentas);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filtrarVentas() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredVentas = ventas.where((venta) {
        return venta['cliente_nombre']
                .toString()
                .toLowerCase()
                .contains(query) ||
            venta['codigo_producto'].toString().toLowerCase().contains(query) ||
            venta['descripcion_compra']
                .toString()
                .toLowerCase()
                .contains(query) ||
            venta['total'].toString().contains(query);
      }).toList();
    });
  }

// En _cargarVentas()
  Future<void> _cargarVentas() async {
    try {
      final listaVentas = await _ventasController.obtenerVentas();

      final ventasProcesadas = listaVentas.map<Map<String, dynamic>>((venta) {
        // Convertir valores numéricos con manejo de nulls
        return {
          'idVentas': venta['idVentas'],
          'fecha_venta': venta['fecha_venta'],
          'tipo_factura': venta['tipo_factura'],
          'metodo_pago': venta['metodo_pago'],
          'total': double.tryParse(venta['total']?.toString() ?? '0') ?? 0.0,
          'descripcion_compra': venta['descripcion_compra'],
          'cliente_nombre': venta['cliente_nombre'],
          'productos': (venta['productos'] as List).map((producto) {
            return {
              'codigo': producto['codigo'] ?? 'N/A',
              'nombre': producto['nombre'] ?? 'Producto sin nombre',
              'cantidad': producto['cantidad'] ?? 0,
              'precio':
                  double.tryParse(producto['precio']?.toString() ?? '0') ?? 0.0,
              'costo':
                  double.tryParse(producto['costo']?.toString() ?? '0') ?? 0.0,
            };
          }).toList(),
        };
      }).toList();

      setState(() {
        ventas = ventasProcesadas;
        filteredVentas = ventasProcesadas;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al procesar datos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editarVenta(Map<String, dynamic> venta) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditarVentaScreen(venta: venta),
      ),
    );

    if (result == true) {
      await _cargarVentas(); // Forzar recarga de datos
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Venta actualizada correctamente')),
      );
    }
  }

  void _eliminarVenta(int id) async {
    try {
      await _ventasController.eliminarVenta(id);
      _cargarVentas();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Venta eliminada correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar la venta: $e')),
      );
    }
  }

  void _mostrarDetalleVenta(Map<String, dynamic> venta) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Detalle Completo de Venta'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailItem('Código Venta:', venta['idVentas'].toString()),
                _buildDetailItem('Cliente:', venta['cliente_nombre']),
                _buildDetailItem(
                    'Fecha:',
                    DateFormat('dd/MM/yyyy')
                        .format(DateTime.parse(venta['fecha_venta']))),
                _buildDetailItem(
                    'Total:', '\$${venta['total']?.toStringAsFixed(2)}'),
                Divider(thickness: 2),
                Text('Detalles Técnicos:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                _buildDetailItem('Tipo Factura:', venta['tipo_factura']),
                _buildDetailItem('Método Pago:', venta['metodo_pago']),
                Divider(thickness: 2),
                Text('Productos:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...(venta['productos'] as List<dynamic>).map((producto) {
                  return Column(
                    children: [
                      _buildProductDetail('Código:', producto['codigo']),
                      _buildProductDetail('Nombre:', producto['nombre']),
                      _buildProductDetail(
                          'Cantidad:', producto['cantidad'].toString()),
                      _buildProductDetail('Costo Unitario:',
                          '\$${producto['costo']?.toStringAsFixed(2)}'),
                      _buildProductDetail('Precio Unitario:',
                          '\$${producto['precio']?.toStringAsFixed(2)}'),
                      _buildProductDetail('Subtotal:',
                          '\$${(producto['cantidad'] * producto['precio'])?.toStringAsFixed(2)}'),
                      Divider(),
                    ],
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cerrar', style: TextStyle(color: Colors.blue)),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w600)),
          SizedBox(width: 10),
          Text(value ?? 'N/A', style: TextStyle(color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildProductDetail(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
          SizedBox(width: 8),
          Text(value ?? 'N/A', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Ventas',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add), // Icono para agregar cliente
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => AgregarClienteModal(
                        onClienteAgregado: () {},
                      )),
            ),
          ),
          IconButton(
            icon: Icon(Icons.group),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ClientesScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar ventas...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: filteredVentas.isEmpty
                ? Center(child: Text("No hay ventas disponibles"))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 12,
                      columns: [
                        DataColumn(label: Text('Código')),
                        DataColumn(label: Text('Cliente')),
                        DataColumn(label: Text('Descripción')),
                        DataColumn(label: Text('Costo')),
                        DataColumn(label: Text('Precio')),
                        DataColumn(label: Text('Total')),
                        DataColumn(label: Text('Acciones')),
                      ],
                      rows: filteredVentas.map((venta) {
                        return DataRow(cells: [
                          DataCell(Text(venta['idVentas'].toString())),
                          DataCell(Text(venta['cliente_nombre'] ?? 'N/A')),
                          DataCell(Text(venta['descripcion_compra'] ?? 'N/A')),
                          DataCell(Text(
                              '\$${venta['productos'][0]['costo'].toStringAsFixed(2)}')),
                          DataCell(Text(
                              '\$${venta['productos'][0]['precio'].toStringAsFixed(2)}')),
                          DataCell(
                              Text('\$${venta['total'].toStringAsFixed(2)}')),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.visibility),
                                  onPressed: () => _mostrarDetalleVenta(venta),
                                ),
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () => _editarVenta(venta),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () =>
                                      _eliminarVenta(venta['idVentas']),
                                ),
                              ],
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AgregarVentaScreen()),
          );

          if (result == true) {
            _cargarVentas();
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
