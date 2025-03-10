import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../navigation_bar.dart';
import 'agregar_venta_screen.dart';
import 'ventasTemporal/asignar_sucursal_manual_screen.dart';
import 'editar_venta_screen.dart';
import 'venta_widgets.dart';
import 'venta_api.dart';

class VentasScreen extends StatefulWidget {
  @override
  _VentasScreenState createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> {
  List<dynamic> ventas = [];
  List<dynamic> filteredVentas = [];
  final TextEditingController _searchController = TextEditingController();
  bool _mostrarTodosLosCampos = false;
  int _page = 1;
  int _limit = 10;
  int _total = 0;

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

  Future<void> _cargarVentas() async {
    try {
      final data = await VentaApi().getVentas(page: _page, limit: _limit);
      setState(() {
        ventas = data['ventas'] ?? [];
        filteredVentas = ventas;
        _total = data['total'] ?? 0;
      });
    } catch (e) {
      print('Error al cargar ventas: $e'); // Agregar log para depurar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar ventas: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _filtrarVentas() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredVentas = ventas.where((venta) {
        return (venta['cliente_nombre']
                    ?.toString()
                    .toLowerCase()
                    .contains(query) ??
                false) ||
            (venta['codigo_venta']?.toString().toLowerCase().contains(query) ??
                false) ||
            (venta['descripcion_compra']
                    ?.toString()
                    .toLowerCase()
                    .contains(query) ??
                false) ||
            (venta['total']?.toString().toLowerCase().contains(query) ??
                false) ||
            (venta['empleado_nombre']
                    ?.toString()
                    .toLowerCase()
                    .contains(query) ??
                false);
      }).toList();
    });
  }

  void _editarVenta(Map<String, dynamic> venta) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditarVentaScreen(venta: venta)),
    );
    if (result == true) {
      await _cargarVentas();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Venta actualizada correctamente')),
      );
    }
  }

  void _eliminarVenta(int id) async {
    try {
      await VentaApi().deleteVenta(id);
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

  void _asignarSucursalManual(Map<String, dynamic> venta) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => AsignarSucursalManualScreen(venta: venta)),
    );
    if (result == true) {
      _cargarVentas();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomNavigationBar(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Ventas', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar ventas...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding: EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => setState(
                        () => _mostrarTodosLosCampos = !_mostrarTodosLosCampos),
                    child: Text(
                        _mostrarTodosLosCampos ? "Ocultar" : "Mostrar Todo"),
                    style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 12)),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Expanded(
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  child: filteredVentas.isEmpty
                      ? Center(child: Text("No hay ventas disponibles"))
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: DataTable(
                              columnSpacing: 12,
                              dataRowHeight: 48,
                              headingRowHeight: 40,
                              columns: _mostrarTodosLosCampos
                                  ? [
                                      DataColumn(label: Text('Código')),
                                      DataColumn(label: Text('Cliente')),
                                      DataColumn(label: Text('Empleado')),
                                      DataColumn(label: Text('Fecha')),
                                      DataColumn(label: Text('Tipo DTE')),
                                      DataColumn(label: Text('Pago')),
                                      DataColumn(label: Text('Descripción')),
                                      DataColumn(label: Text('Total')),
                                      DataColumn(label: Text('Desc.')),
                                      DataColumn(label: Text('Sucursal')),
                                      DataColumn(label: Text('Acciones')),
                                    ]
                                  : [
                                      DataColumn(label: Text('Código')),
                                      DataColumn(label: Text('Cliente')),
                                      DataColumn(label: Text('Empleado')),
                                      DataColumn(label: Text('Descripción')),
                                      DataColumn(label: Text('Total')),
                                      DataColumn(label: Text('Desc.')),
                                      DataColumn(label: Text('Sucursal')),
                                      DataColumn(label: Text('Acciones')),
                                    ],
                              rows: filteredVentas.map((venta) {
                                final total = double.tryParse(
                                        venta['total']?.toString() ?? '0.0') ??
                                    0.0;
                                final descuento = double.tryParse(
                                        venta['descuento']?.toString() ??
                                            '0.0') ??
                                    0.0;

                                return DataRow(
                                  cells: _mostrarTodosLosCampos
                                      ? [
                                          DataCell(Text(
                                              venta['codigo_venta'] ?? 'N/A')),
                                          DataCell(Text(
                                              venta['cliente_nombre'] ??
                                                  'N/A')),
                                          DataCell(Text(
                                              venta['empleado_nombre'] ??
                                                  'N/A')),
                                          DataCell(Text(
                                            venta['fecha_venta'] != null
                                                ? DateFormat('dd/MM/yy').format(
                                                    DateTime.parse(
                                                        venta['fecha_venta']))
                                                : 'N/A',
                                          )),
                                          DataCell(
                                              Text(venta['tipo_dte'] ?? 'N/A')),
                                          DataCell(Text(
                                              venta['metodo_pago'] ?? 'N/A')),
                                          DataCell(Text(
                                              venta['descripcion_compra'] ??
                                                  'N/A')),
                                          DataCell(Text(
                                              '\$${total.toStringAsFixed(2)}')),
                                          DataCell(Text(
                                              '${descuento.toStringAsFixed(0)}%')),
                                          DataCell(Text(
                                              venta['sucursal_nombre'] ??
                                                  'N/A')),
                                          DataCell(_buildActionButtons(venta)),
                                        ]
                                      : [
                                          DataCell(Text(
                                              venta['codigo_venta'] ?? 'N/A')),
                                          DataCell(Text(
                                              venta['cliente_nombre'] ??
                                                  'N/A')),
                                          DataCell(Text(
                                              venta['empleado_nombre'] ??
                                                  'N/A')),
                                          DataCell(Text(
                                              venta['descripcion_compra'] ??
                                                  'N/A')),
                                          DataCell(Text(
                                              '\$${total.toStringAsFixed(2)}')),
                                          DataCell(Text(
                                              '${descuento.toStringAsFixed(0)}%')),
                                          DataCell(Text(
                                              venta['sucursal_nombre'] ??
                                                  'N/A')),
                                          DataCell(_buildActionButtons(venta)),
                                        ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                ),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _page > 1
                        ? () => setState(() {
                              _page--;
                              _cargarVentas();
                            })
                        : null,
                    child: Text("Anterior"),
                    style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 12)),
                  ),
                  SizedBox(width: 16),
                  Text("Página $_page de ${(_total / _limit).ceil()}"),
                  SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _page < (_total / _limit).ceil()
                        ? () => setState(() {
                              _page++;
                              _cargarVentas();
                            })
                        : null,
                    child: Text("Siguiente"),
                    style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> venta) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: 'Ver historial de cambios',
          child: IconButton(
            icon: Icon(Icons.history, size: 20),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => HistorialCambiosDialog(
                ventaId: venta['idVentas'],
                codigoVenta: venta['codigo_venta'],
              ),
            ),
          ),
        ),
        Tooltip(
          message: 'Ver detalles',
          child: IconButton(
            icon: Icon(Icons.visibility, size: 20),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => DetalleVentaDialog(venta: venta),
            ),
          ),
        ),
        Tooltip(
          message: 'Editar venta',
          child: IconButton(
            icon: Icon(Icons.edit, color: Colors.blue, size: 20),
            onPressed: () => _editarVenta(venta),
          ),
        ),
        Tooltip(
          message: 'Eliminar venta',
          child: IconButton(
            icon: Icon(Icons.delete, color: Colors.red, size: 20),
            onPressed: () => _eliminarVenta(venta['idVentas']),
          ),
        ),
        Tooltip(
          message: 'Asignar sucursal',
          child: IconButton(
            icon: Icon(Icons.store, color: Colors.orange, size: 20),
            onPressed: () => _asignarSucursalManual(venta),
          ),
        ),
      ],
    );
  }
}
