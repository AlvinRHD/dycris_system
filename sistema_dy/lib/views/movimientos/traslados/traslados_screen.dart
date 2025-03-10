import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:sistema_dy/views/navigation_bar.dart';
import 'agregar_traslado_screen.dart';
import 'editar_traslado_screen.dart';
import 'traslados_api.dart';
import 'traslados_widgets.dart';
import 'traslado_pdf.dart';

class TrasladosScreen extends StatefulWidget {
  @override
  _TrasladosScreenState createState() => _TrasladosScreenState();
}

class _TrasladosScreenState extends State<TrasladosScreen> {
  List<Map<String, dynamic>> traslados = [];
  List<dynamic> sucursales = [];
  String? selectedSucursal;
  final TextEditingController searchController = TextEditingController();
  int _page = 1;
  int _limit = 10;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _cargarTraslados();
    _cargarSucursales();
    searchController.addListener(_filtrarTraslados);
  }

  Future<void> _cargarTraslados() async {
    try {
      final response = await TrasladosApi().getTraslados(
        searchQuery: searchController.text,
        sucursalOrigen: selectedSucursal,
        page: _page,
        limit: _limit,
      );
      setState(() {
        traslados = List<Map<String, dynamic>>.from(response['traslados']);
        _total = response['total'];
      });
    } catch (e) {
      _mostrarMensaje('Error al cargar traslados: $e', esError: true);
    }
  }

  Future<void> _cargarSucursales() async {
    try {
      final loadedSucursales = await TrasladosApi().getSucursales();
      setState(() {
        sucursales = loadedSucursales;
      });
    } catch (e) {
      _mostrarMensaje('Error al cargar sucursales: $e', esError: true);
      setState(() {
        sucursales = [];
      });
    }
  }

  Future<void> _marcarCompletado(int id) async {
    try {
      await TrasladosApi().updateTraslado(id, {'estado': 'Completado'});
      _mostrarMensaje('Traslado marcado como completado');
      _cargarTraslados();
    } catch (e) {
      _mostrarMensaje('Error al marcar como completado: $e', esError: true);
    }
  }

  void _filtrarTraslados() {
    setState(() {
      _page = 1;
      _cargarTraslados();
    });
  }

  void _editarTraslado(Map<String, dynamic> traslado) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => EditarTrasladoScreen(traslado: traslado)),
    );
    if (result == true) {
      _cargarTraslados();
      _mostrarMensaje('Traslado actualizado correctamente');
    }
  }

  void _eliminarTraslado(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text('Confirmar eliminación',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text('¿Está seguro de que desea eliminar este traslado?',
            style: TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar',
                style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () async {
              try {
                await TrasladosApi().deleteTraslado(id);
                Navigator.pop(context);
                _cargarTraslados();
                _mostrarMensaje('Traslado eliminado correctamente');
              } catch (e) {
                Navigator.pop(context);
                _mostrarMensaje('Error al eliminar traslado: $e',
                    esError: true);
              }
            },
            child: Text('Eliminar',
                style: TextStyle(fontSize: 14, color: Colors.red[600])),
          ),
        ],
      ),
    );
  }

  void _mostrarMensaje(String mensaje, {bool esError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensaje,
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        backgroundColor: esError ? Colors.red[600] : Colors.green[600],
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomNavigationBar(
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text('Gestión de Traslados',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          backgroundColor: Colors.grey[50],
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black87),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AgregarTrasladoScreen()),
                  );
                  if (result == true) _cargarTraslados();
                },
                icon: Icon(Icons.add, size: 18, color: Colors.white),
                label: Text("Nuevo Traslado",
                    style: TextStyle(fontSize: 14, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(child: _buildSearchField()),
                  SizedBox(width: 12),
                  Expanded(child: _buildSucursalDropdown()),
                ],
              ),
            ),
            Expanded(child: _buildDataTable()),
            SizedBox(height: 12),
            _buildPagination(),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: 'Buscar por código o producto...',
          hintStyle: TextStyle(fontSize: 14, color: Colors.grey[600]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        style: TextStyle(fontSize: 14, color: Colors.black87),
      ),
    );
  }

  Widget _buildSucursalDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: selectedSucursal,
        decoration: InputDecoration(
          labelText: 'Filtrar por Sucursal Origen',
          labelStyle: TextStyle(fontSize: 12, color: Colors.grey[600]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        items: [
          DropdownMenuItem(
              value: null,
              child:
                  Text('Todas las sucursales', style: TextStyle(fontSize: 14))),
          ...sucursales.map((s) => DropdownMenuItem<String>(
                value: s['codigo'].toString(),
                child: Text(s['nombre'] ?? s['codigo'].toString(),
                    style: TextStyle(fontSize: 14)),
              )),
        ],
        onChanged: (value) {
          setState(() {
            selectedSucursal = value;
            _page = 1;
            _cargarTraslados();
          });
        },
      ),
    );
  }

  Widget _buildDataTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: traslados.isEmpty
          ? Center(
              child: Text("No hay traslados disponibles",
                  style: TextStyle(color: Colors.grey[600], fontSize: 14)))
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                dataRowHeight: 60,
                headingRowHeight: 40,
                columns: [
                  DataColumn(
                      label: Text('Código',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text('Productos',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text('Origen',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text('Destino',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text('Empleado',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text('Fecha',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text('Estado',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text('Acciones',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold))),
                ],
                rows: traslados.map((traslado) {
                  return DataRow(cells: [
                    DataCell(Text(
                        traslado['codigo_traslado']?.toString() ?? 'N/A',
                        style: TextStyle(fontSize: 14))),
                    DataCell(DetalleTrasladoWidget(
                        productos: traslado['productos'] ?? [])),
                    DataCell(Text(
                        traslado['sucursal_origen']?.toString() ??
                            traslado['codigo_sucursal_origen'] ??
                            'N/A',
                        style: TextStyle(fontSize: 14))),
                    DataCell(Text(
                        traslado['sucursal_destino']?.toString() ??
                            traslado['codigo_sucursal_destino'] ??
                            'N/A',
                        style: TextStyle(fontSize: 14))),
                    DataCell(Text(traslado['empleado']?.toString() ?? 'N/A',
                        style: TextStyle(fontSize: 14))),
                    DataCell(traslado['fecha_traslado'] != null
                        ? Text(
                            DateFormat('dd/MM/yyyy HH:mm').format(
                                DateTime.parse(traslado['fecha_traslado'])),
                            style: TextStyle(fontSize: 14))
                        : Text('N/A', style: TextStyle(fontSize: 14))),
                    DataCell(
                      GestureDetector(
                        onTap: traslado['estado'] != 'Completado'
                            ? () => _marcarCompletado(traslado['id'])
                            : null,
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          decoration: BoxDecoration(
                            color: traslado['estado'] == 'Completado'
                                ? Colors.green[100]
                                : traslado['estado'] == 'Cancelado'
                                    ? Colors.red[100]
                                    : Colors.yellow[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            traslado['estado']?.toString() ?? 'N/A',
                            style: TextStyle(
                              fontSize: 14,
                              color: traslado['estado'] == 'Completado'
                                  ? Colors.green[600]
                                  : traslado['estado'] == 'Cancelado'
                                      ? Colors.red[600]
                                      : Colors.yellow[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.history, color: Colors.grey[600]),
                            onPressed: () => showDialog(
                              context: context,
                              builder: (_) => HistorialCambiosTrasladosDialog(
                                trasladoId: traslado['id'],
                                codigoTraslado: traslado['codigo_traslado'],
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue[600]),
                            onPressed: () => _editarTraslado(traslado),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red[600]),
                            onPressed: () => _eliminarTraslado(traslado['id']),
                          ),
                          IconButton(
                            icon: Icon(Icons.print, color: Colors.black),
                            onPressed: () async {
                              try {
                                final pdf =
                                    await TrasladoPDF.generateTrasladoPDF(
                                        traslado as Map<String, dynamic>);
                                final docFile = await pdf.save();
                                await Printing.layoutPdf(
                                  onLayout: (_) => docFile,
                                  name:
                                      'traslado_${traslado['codigo_traslado']}.pdf',
                                );
                                await Printing.sharePdf(
                                  bytes: docFile,
                                  filename:
                                      'traslado_${traslado['codigo_traslado']}.pdf',
                                );
                                _mostrarMensaje(
                                    'PDF generado, mostrado y listo para compartir');
                              } catch (e) {
                                _mostrarMensaje(
                                    'Error al generar o mostrar el PDF: $e',
                                    esError: true);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
    );
  }

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: _page > 1
              ? () => setState(() {
                    _page--;
                    _cargarTraslados();
                  })
              : null,
          child: Text("Anterior",
              style: TextStyle(fontSize: 14, color: Colors.black87)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[200],
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 2,
          ),
        ),
        SizedBox(width: 20),
        Text("Página $_page de ${(_total / _limit).ceil()}",
            style: TextStyle(fontSize: 14, color: Colors.black87)),
        SizedBox(width: 20),
        ElevatedButton(
          onPressed: _page < (_total / _limit).ceil()
              ? () => setState(() {
                    _page++;
                    _cargarTraslados();
                  })
              : null,
          child: Text("Siguiente",
              style: TextStyle(fontSize: 14, color: Colors.black87)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[200],
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 2,
          ),
        ),
      ],
    );
  }
}
