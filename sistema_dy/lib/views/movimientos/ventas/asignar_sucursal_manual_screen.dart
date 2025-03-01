import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'venta_api_temporal.dart';

class AsignarSucursalManualScreen extends StatefulWidget {
  final Map<String, dynamic> venta;

  const AsignarSucursalManualScreen({required this.venta});

  @override
  _AsignarSucursalManualScreenState createState() =>
      _AsignarSucursalManualScreenState();
}

class _AsignarSucursalManualScreenState
    extends State<AsignarSucursalManualScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _searchController = TextEditingController();
  String? _selectedSucursal;
  List<dynamic> _sucursales = [];
  List<dynamic> _filteredSucursales = [];
  List<dynamic> _asignaciones = [];
  bool _isLoadingSucursales = false;
  bool _isLoadingAsignaciones = false;
  List<dynamic> _asignacionesOriginales = []; // Nueva variable en la clase

  @override
  void initState() {
    super.initState();
    _cargarSucursales();
    _cargarAsignaciones();
    _searchController.addListener(_filtrarSucursales);
  }

  Future<void> _cargarSucursales() async {
    setState(() => _isLoadingSucursales = true);
    try {
      final sucursales = await VentaApiTemporal().getSucursales();
      setState(() {
        _sucursales = sucursales;
        _filteredSucursales = sucursales;
        _isLoadingSucursales = false;
      });
    } catch (e) {
      setState(() => _isLoadingSucursales = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar sucursales: $e')),
      );
    }
  }

  Future<void> _cargarAsignaciones() async {
    setState(() => _isLoadingAsignaciones = true);
    try {
      final asignaciones = await VentaApiTemporal().getAsignacionesManuales();
      setState(() {
        _asignacionesOriginales = asignaciones; // Guardar copia original
        _asignaciones = asignaciones;
        _isLoadingAsignaciones = false;
      });
    } catch (e) {
      setState(() => _isLoadingAsignaciones = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar asignaciones: $e')),
      );
    }
  }

  void _filtrarSucursales() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSucursales = _sucursales.where((sucursal) {
        final nombre = sucursal['nombre'].toString().toLowerCase();
        return nombre.contains(query);
      }).toList();
    });
  }

  void _asignarSucursal() async {
    if (_formKey.currentState!.validate()) {
      try {
        await VentaApiTemporal().asignarSucursalManual(
            widget.venta['idVentas'], _selectedSucursal!);
        _cargarAsignaciones(); // Refrescar la tabla
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Venta asignada a $_selectedSucursal')),
        );
        setState(() {
          _selectedSucursal = null;
          _searchController.clear();
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al asignar sucursal: $e')),
        );
      }
    }
  }

  void _eliminarAsignacion(int asignacionId) async {
    try {
      await VentaApiTemporal().eliminarAsignacionManual(asignacionId);
      _cargarAsignaciones(); // Refrescar la tabla
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Asignación eliminada correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar asignación: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('Asignar Sucursal Manual - ${widget.venta['codigo_venta']}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección de asignación
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Buscar Sucursal',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 15),
                  _isLoadingSucursales
                      ? Center(child: CircularProgressIndicator())
                      : Container(
                          height: 150,
                          child: ListView.builder(
                            itemCount: _filteredSucursales.length,
                            itemBuilder: (context, index) {
                              final sucursal = _filteredSucursales[index];
                              return ListTile(
                                title: Text(sucursal['nombre']),
                                subtitle: Text('Código: ${sucursal['codigo']}'),
                                trailing:
                                    _selectedSucursal == sucursal['nombre']
                                        ? Icon(Icons.check, color: Colors.green)
                                        : null,
                                onTap: () {
                                  setState(() {
                                    _selectedSucursal = sucursal['nombre'];
                                    _searchController.text = sucursal['nombre'];
                                  });
                                },
                              );
                            },
                          ),
                        ),
                  SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: _selectedSucursal,
                    decoration: InputDecoration(
                      labelText: 'Sucursal Seleccionada',
                      border: OutlineInputBorder(),
                    ),
                    items: _sucursales.map((sucursal) {
                      return DropdownMenuItem<String>(
                        value: sucursal['nombre'],
                        child: Text(sucursal['nombre']),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedSucursal = value),
                    validator: (value) =>
                        value == null ? 'Seleccione una sucursal' : null,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _asignarSucursal,
                    child: Text('Asignar Sucursal'),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: null,
              decoration: InputDecoration(
                labelText: 'Filtrar por Sucursal',
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem<String>(value: null, child: Text('Todas')),
                ..._sucursales.map((sucursal) => DropdownMenuItem<String>(
                      value: sucursal['nombre'],
                      child: Text(sucursal['nombre']),
                    )),
              ],
              onChanged: (value) {
                setState(() {
                  if (value == null) {
                    _asignaciones =
                        List.from(_asignacionesOriginales); // Mostrar todas
                  } else {
                    _asignaciones = _asignacionesOriginales
                        .where((asignacion) =>
                            asignacion['sucursal_nombre'] == value)
                        .toList();
                  }
                });
              },
            ),
            SizedBox(height: 10),
            // Sección de tabla de asignaciones
            Text(
              'Ventas Asignadas Manualmente',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: _isLoadingAsignaciones
                  ? Center(child: CircularProgressIndicator())
                  : _asignaciones.isEmpty
                      ? Center(child: Text('No hay asignaciones registradas'))
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: [
                              DataColumn(label: Text('Código Venta')),
                              DataColumn(label: Text('Empleado')),
                              DataColumn(label: Text('Sucursal')),
                              DataColumn(label: Text('Productos')),
                              DataColumn(label: Text('Total')),
                              DataColumn(label: Text('Descuento')),
                              DataColumn(label: Text('Fecha Asignación')),
                              DataColumn(label: Text('Acciones')),
                            ],
                            rows: _asignaciones.map((asignacion) {
                              final productos = asignacion['productos']
                                  .map((p) =>
                                      "${p['nombre']} (${p['cantidad']})")
                                  .join(', ');
                              final total = double.tryParse(
                                      asignacion['total']?.toString() ??
                                          '0.0') ??
                                  0.0;
                              final descuento = double.tryParse(
                                      asignacion['descuento']?.toString() ??
                                          '0.0') ??
                                  0.0;
                              final fecha = DateFormat('dd/MM/yyyy HH:mm')
                                  .format(DateTime.parse(
                                      asignacion['fecha_asignacion']));
                              return DataRow(
                                cells: [
                                  DataCell(Text(
                                      asignacion['codigo_venta'] ?? 'N/A')),
                                  DataCell(Text(
                                      asignacion['empleado_nombre'] ?? 'N/A')),
                                  DataCell(Text(
                                      asignacion['sucursal_nombre'] ?? 'N/A')),
                                  DataCell(Text(productos)),
                                  DataCell(
                                      Text('\$${total.toStringAsFixed(2)}')),
                                  DataCell(Text(asignacion['descuento'] != null
                                      ? '${double.tryParse(asignacion['descuento'].toString())?.toStringAsFixed(2)}%'
                                      : '0.00%')),
                                  DataCell(Text(fecha)),
                                  DataCell(IconButton(
                                    icon: Icon(Icons.delete),
                                    onPressed: () =>
                                        _eliminarAsignacion(asignacion['id']),
                                  )),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
