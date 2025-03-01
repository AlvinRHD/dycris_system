import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../navigation_bar.dart';
import 'agregar_venta_screen.dart';
import 'asignar_sucursal_manual_screen.dart';
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

// Nuevo botón "Mandar a Sucursal" temporal, lo vamos a eliminar
  void _asignarSucursalManual(Map<String, dynamic> venta) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AsignarSucursalManualScreen(venta: venta),
      ),
    );
    if (result == true) {
      _cargarVentas(); // Refrescar la lista después de asignar
    }
  }
// Nuevo botón "Mandar a Sucursal" temporal, lo vamos a eliminar

  Future<void> _cargarVentas() async {
    try {
      final data = await VentaApi().getVentas(page: _page, limit: _limit);
      setState(() {
        ventas = data['ventas'];
        filteredVentas = ventas;
        _total = data['total'];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error al cargar ventas: $e'),
            backgroundColor: Colors.red),
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

  @override
  Widget build(BuildContext context) {
    return CustomNavigationBar(
        child: Scaffold(
      appBar: AppBar(
        title: Text('Ventas', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AgregarVentaScreen()),
                );
                if (result == true) _cargarVentas();
              },
              icon: Icon(Icons.add),
              label: Text("Agregar Venta"),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => setState(
                      () => _mostrarTodosLosCampos = !_mostrarTodosLosCampos),
                  child: Text(_mostrarTodosLosCampos
                      ? "Ocultar Campos"
                      : "Mostrar Todos"),
                ),
              ],
            ),
            SizedBox(height: 10),
            Expanded(
              child: filteredVentas.isEmpty
                  ? Center(child: Text("No hay ventas disponibles"))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: _mostrarTodosLosCampos
                            ? [
                                DataColumn(label: Text('Código')),
                                DataColumn(label: Text('Cliente')),
                                DataColumn(label: Text('Empleado')),
                                DataColumn(label: Text('Fecha')),
                                DataColumn(label: Text('Tipo Factura')),
                                DataColumn(label: Text('Método Pago')),
                                DataColumn(label: Text('Descripción')),
                                DataColumn(label: Text('Total')),
                                DataColumn(label: Text('Descuento')),
                                DataColumn(label: Text('Sucursal')),
                                DataColumn(label: Text('Factura')), // Nuevo
                                DataColumn(
                                    label: Text('Crédito Fiscal')), // Nuevo
                                DataColumn(
                                    label:
                                        Text('Factura Exportación')), // Nuevo
                                DataColumn(
                                    label: Text('Nota Crédito')), // Nuevo
                                DataColumn(label: Text('Nota Débito')), // Nuevo
                                DataColumn(
                                    label: Text('Nota Remisión')), // Nuevo
                                DataColumn(label: Text('Liquidación')), // Nuevo
                                DataColumn(label: Text('Retención')), // Nuevo
                                DataColumn(
                                    label:
                                        Text('Contable Liquidación')), // Nuevo
                                DataColumn(label: Text('Donación')), // Nuevo
                                DataColumn(
                                    label: Text('Sujeto Excluido')), // Nuevo
                                DataColumn(label: Text('Acciones')),
                              ]
                            : [
                                DataColumn(label: Text('Código')),
                                DataColumn(label: Text('Cliente')),
                                DataColumn(label: Text('Empleado')),
                                DataColumn(label: Text('Descripción')),
                                DataColumn(label: Text('Total')),
                                DataColumn(label: Text('Descuento')),
                                DataColumn(label: Text('Sucursal')),
                                DataColumn(label: Text('Acciones')),
                              ],
                        rows: filteredVentas.map((venta) {
                          final total = double.tryParse(
                                  venta['total']?.toString() ?? '0.0') ??
                              0.0;
                          final descuento = double.tryParse(
                                  venta['descuento']?.toString() ?? '0.0') ??
                              0.0;

                          return DataRow(
                            cells: _mostrarTodosLosCampos
                                ? [
                                    DataCell(
                                        Text(venta['codigo_venta'] ?? 'N/A')),
                                    DataCell(
                                        Text(venta['cliente_nombre'] ?? 'N/A')),
                                    DataCell(Text(
                                        venta['empleado_nombre'] ?? 'N/A')),
                                    DataCell(Text(
                                      venta['fecha_venta'] != null
                                          ? DateFormat('dd/MM/yyyy').format(
                                              DateTime.parse(
                                                  venta['fecha_venta']))
                                          : 'N/A',
                                    )),
                                    DataCell(
                                        Text(venta['tipo_factura'] ?? 'N/A')),
                                    DataCell(
                                        Text(venta['metodo_pago'] ?? 'N/A')),
                                    DataCell(Text(
                                        venta['descripcion_compra'] ?? 'N/A')),
                                    DataCell(
                                        Text('\$${total.toStringAsFixed(2)}')),
                                    DataCell(Text(
                                        '${descuento.toStringAsFixed(2)}%')),
                                    DataCell(Text(
                                        venta['sucursal_nombre'] ?? 'N/A')),
                                    DataCell(Text(
                                        venta['factura'] ?? 'N/A')), // Nuevo
                                    DataCell(Text(
                                        venta['comprobante_credito_fiscal'] ??
                                            'N/A')), // Nuevo
                                    DataCell(Text(
                                        venta['factura_exportacion'] ??
                                            'N/A')), // Nuevo
                                    DataCell(Text(venta['nota_credito'] ??
                                        'N/A')), // Nuevo
                                    DataCell(Text(venta['nota_debito'] ??
                                        'N/A')), // Nuevo
                                    DataCell(Text(venta['nota_remision'] ??
                                        'N/A')), // Nuevo
                                    DataCell(Text(
                                        venta['comprobante_liquidacion'] ??
                                            'N/A')), // Nuevo
                                    DataCell(Text(
                                        venta['comprobante_retencion'] ??
                                            'N/A')), // Nuevo
                                    DataCell(Text(venta[
                                            'documento_contable_liquidacion'] ??
                                        'N/A')), // Nuevo
                                    DataCell(Text(
                                        venta['comprobante_donacion'] ??
                                            'N/A')), // Nuevo
                                    DataCell(Text(
                                        venta['factura_sujeto_excluido'] ??
                                            'N/A')), // Nuevo
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.history),
                                            onPressed: () => showDialog(
                                              context: context,
                                              builder: (_) =>
                                                  HistorialCambiosDialog(
                                                ventaId: venta['idVentas'],
                                                codigoVenta:
                                                    venta['codigo_venta'],
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.visibility),
                                            onPressed: () => showDialog(
                                              context: context,
                                              builder: (_) =>
                                                  DetalleVentaDialog(
                                                      venta: venta),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.edit,
                                                color: Colors.blue),
                                            onPressed: () =>
                                                _editarVenta(venta),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete,
                                                color: Colors.red),
                                            onPressed: () => _eliminarVenta(
                                                venta['idVentas']),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.store,
                                                color: Colors.orange),
                                            onPressed: () =>
                                                _asignarSucursalManual(venta),
                                          ), // Nuevo botón "Mandar a Sucursal"temporal, lo vamos a eliminar
                                        ],
                                      ),
                                    ),
                                  ]
                                : [
                                    DataCell(
                                        Text(venta['codigo_venta'] ?? 'N/A')),
                                    DataCell(
                                        Text(venta['cliente_nombre'] ?? 'N/A')),
                                    DataCell(Text(
                                        venta['empleado_nombre'] ?? 'N/A')),
                                    DataCell(Text(
                                        venta['descripcion_compra'] ?? 'N/A')),
                                    DataCell(
                                        Text('\$${total.toStringAsFixed(2)}')),
                                    DataCell(Text(
                                        '${descuento.toStringAsFixed(2)}%')),
                                    DataCell(Text(venta['sucursal_nombre'] ??
                                        'N/A')), //columna agregada para mostrar la venta a sucursal por defecto
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.history),
                                            onPressed: () => showDialog(
                                              context: context,
                                              builder: (_) =>
                                                  HistorialCambiosDialog(
                                                ventaId: venta['idVentas'],
                                                codigoVenta:
                                                    venta['codigo_venta'],
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.visibility),
                                            onPressed: () => showDialog(
                                              context: context,
                                              builder: (_) =>
                                                  DetalleVentaDialog(
                                                      venta: venta),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.edit,
                                                color: Colors.blue),
                                            onPressed: () =>
                                                _editarVenta(venta),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete,
                                                color: Colors.red),
                                            onPressed: () => _eliminarVenta(
                                                venta['idVentas']),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.store,
                                                color: Colors.orange),
                                            onPressed: () =>
                                                _asignarSucursalManual(venta),
                                          ), // Nuevo botón "Mandar a Sucursal" lo vamos a eliminar
                                        ],
                                      ),
                                    ),
                                  ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
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
                ),
                SizedBox(width: 20),
                Text("Página $_page de ${(_total / _limit).ceil()}"),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _page < (_total / _limit).ceil()
                      ? () => setState(() {
                            _page++;
                            _cargarVentas();
                          })
                      : null,
                  child: Text("Siguiente"),
                ),
              ],
            ),
          ],
        ),
      ),
    ));
  }
}
