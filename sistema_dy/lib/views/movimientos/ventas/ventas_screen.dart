import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'agregar_venta_modal.dart';

// Correct import for screen, not modal
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
            venta['idVentas'].toString().toLowerCase().contains(query) ||
            venta['descripcion_compra']
                .toString()
                .toLowerCase()
                .contains(query) ||
            venta['total'].toString().contains(query);
      }).toList();
    });
  }

  Future<void> _cargarVentas() async {
    try {
      final listaVentas = await _ventasController.obtenerVentas();

      final ventasProcesadas = listaVentas.map<Map<String, dynamic>>((venta) {
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
          content: Text('Error al cargar ventas: $e'),
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Ventas',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 4.0), // Reduced horizontal padding
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AgregarVentaScreen()),
                );
                if (result == true) {
                  _cargarVentas();
                }
              },
              icon: Icon(Icons.add, color: Colors.white),
              label:
                  Text("Agregar Venta", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 4.0), // Added padding for spacing
            child: ElevatedButton.icon(
              // Botón "Agregar Cliente" en AppBar
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        AgregarClienteModal(onClienteAgregado: () {})),
              ),
              icon: Icon(Icons.person_add_alt_1, color: Colors.white),
              label: Text("Agregar Cliente",
                  style: TextStyle(color: Colors.white)), // No text label
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[600], // Grey button for Add Client
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 8.0), // Padding for the last button
            child: ElevatedButton.icon(
              // Botón "Ver Clientes" en AppBar
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ClientesScreen()),
              ),
              icon: Icon(Icons.group, color: Colors.white),
              label: Text("Ver listado de clientes",
                  style: TextStyle(color: Colors.white)), // No text label
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.grey[600], // Grey button for View Clients
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 6),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        // Wrapped TextField with Container
                        decoration: BoxDecoration(
                          // BoxDecoration for rounded corners and background
                          borderRadius: BorderRadius.circular(
                              15.0), // More rounded search bar
                          color: Colors.grey[200],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Buscar ventas...',
                            prefixIcon: Icon(Icons.search, color: Colors.grey),
                            border: InputBorder
                                .none, // No border for TextField inside Container
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 20.0,
                                vertical: 8.0), // Reduced vertical padding
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Historial de Ventas',
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                  textAlign: TextAlign.left,
                ),
              ),
              Expanded(
                child: filteredVentas.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            "No hay ventas disponibles",
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 12,
                          headingRowColor: MaterialStateColor.resolveWith(
                              (states) => Colors.grey[200]!),
                          columns: const [
                            DataColumn(
                                label: Text('Código',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Cliente',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Descripción',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Costo',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Precio',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Total',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Acciones',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                          ],
                          rows: filteredVentas.map((venta) {
                            return DataRow(cells: [
                              DataCell(Text(venta['idVentas'].toString())),
                              DataCell(Text(venta['cliente_nombre'] ?? 'N/A')),
                              DataCell(
                                  Text(venta['descripcion_compra'] ?? 'N/A')),
                              DataCell(Text(
                                  '\$${venta['productos'][0]['costo'].toStringAsFixed(2)}')),
                              DataCell(Text(
                                  '\$${venta['productos'][0]['precio'].toStringAsFixed(2)}')),
                              DataCell(Text(
                                  '\$${venta['total'].toStringAsFixed(2)}')),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.visibility,
                                          color: Colors.grey[600]),
                                      onPressed: () =>
                                          _mostrarDetalleVenta(venta),
                                    ),
                                    IconButton(
                                      icon:
                                          Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _editarVenta(venta),
                                    ),
                                    IconButton(
                                      icon:
                                          Icon(Icons.delete, color: Colors.red),
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
        ),
      ),
    );
  }
}
