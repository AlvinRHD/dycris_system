import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'agregar_traslado_screen.dart';
import 'editar_traslado_screen.dart';
import 'traslados_api.dart';
import 'traslados_widgets.dart';

class TrasladosScreen extends StatefulWidget {
  @override
  _TrasladosScreenState createState() => _TrasladosScreenState();
}

class _TrasladosScreenState extends State<TrasladosScreen> {
  List<dynamic> traslados = [];
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
        traslados = response['traslados'];
        _total = response['total'];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar traslados: $e')));
    }
  }

  Future<void> _cargarSucursales() async {
    try {
      final loadedSucursales = await TrasladosApi().getSucursales();
      setState(() {
        sucursales = loadedSucursales;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar sucursales: $e')));
      setState(() {
        sucursales = [];
      });
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
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Traslado actualizado correctamente')));
    }
  }

  void _eliminarTraslado(int id) async {
    try {
      await TrasladosApi().deleteTraslado(id);
      _cargarTraslados();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Traslado eliminado correctamente')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar traslado: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestión de Traslados',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AgregarTrasladoScreen()),
                );
                if (result == true) _cargarTraslados();
              },
              icon: Icon(Icons.add),
              label: Text("Nuevo Traslado"),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar por código o producto...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedSucursal,
                    decoration: InputDecoration(
                        labelText: 'Filtrar por Sucursal Origen',
                        border: OutlineInputBorder()),
                    items: [
                      DropdownMenuItem(
                          value: null, child: Text('Todas las sucursales')),
                      ...sucursales.map((s) => DropdownMenuItem<String>(
                            value: s['codigo'].toString(),
                            child: Text(s['nombre'] ?? s['codigo'].toString()),
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
                ),
              ],
            ),
          ),
          Expanded(
            child: traslados.isEmpty
                ? Center(child: Text("No hay traslados disponibles"))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: [
                        DataColumn(label: Text('Código')),
                        DataColumn(label: Text('Productos')),
                        DataColumn(label: Text('Origen')),
                        DataColumn(label: Text('Destino')),
                        DataColumn(label: Text('Empleado')), // Nueva columna
                        DataColumn(label: Text('Fecha')),
                        DataColumn(label: Text('Estado')),
                        DataColumn(label: Text('Acciones')),
                      ],
                      rows: traslados.map((traslado) {
                        final productos = traslado['productos'] != null
                            ? (traslado['productos'] as List)
                                .map((p) =>
                                    "${p['producto_nombre']} (${p['cantidad']})")
                                .join(", ")
                            : 'N/A';
                        return DataRow(cells: [
                          DataCell(Text(
                              traslado['codigo_traslado']?.toString() ??
                                  'N/A')),
                          DataCell(DetalleTrasladoWidget(
                              productos: traslado['productos'] ?? [])),
                          DataCell(Text(
                              traslado['sucursal_origen']?.toString() ??
                                  traslado['codigo_sucursal_origen'] ??
                                  'N/A')),
                          DataCell(Text(
                              traslado['sucursal_destino']?.toString() ??
                                  traslado['codigo_sucursal_destino'] ??
                                  'N/A')),
                          DataCell(Text(traslado['empleado']?.toString() ??
                              'N/A')), // Mostrar empleado
                          DataCell(traslado['fecha_traslado'] != null
                              ? Text(DateFormat('dd/MM/yyyy HH:mm').format(
                                  DateTime.parse(traslado['fecha_traslado'])))
                              : Text('N/A')),
                          DataCell(
                            Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 8),
                              decoration: BoxDecoration(
                                color: traslado['estado'] == 'Completado'
                                    ? Colors.green[100]
                                    : traslado['estado'] == 'Cancelado'
                                        ? Colors.red[100]
                                        : Colors.blue[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                traslado['estado']?.toString() ?? 'N/A',
                                style: TextStyle(
                                  color: traslado['estado'] == 'Completado'
                                      ? Colors.green[700]
                                      : traslado['estado'] == 'Cancelado'
                                          ? Colors.red[700]
                                          : Colors.blue[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.history),
                                  onPressed: () => showDialog(
                                    context: context,
                                    builder: (_) =>
                                        HistorialCambiosTrasladosDialog(
                                      trasladoId: traslado['id'],
                                      codigoTraslado:
                                          traslado['codigo_traslado'],
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _editarTraslado(traslado),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () =>
                                      _eliminarTraslado(traslado['id']),
                                ),
                              ],
                            ),
                          ),
                        ]);
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
                          _cargarTraslados();
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
                          _cargarTraslados();
                        })
                    : null,
                child: Text("Siguiente"),
              ),
            ],
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}
