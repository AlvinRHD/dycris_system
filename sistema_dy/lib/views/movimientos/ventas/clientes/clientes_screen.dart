import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sistema_dy/views/navigation_bar.dart';
import 'agregar_cliente_screen.dart';
import 'cliente_widgets.dart';
import 'editar_cliente_screen.dart';
import 'clientes_api.dart';

class ClientesScreen extends StatefulWidget {
  @override
  _ClientesScreenState createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  List<dynamic> _clientes = [];
  List<dynamic> _filteredClientes = [];
  final TextEditingController _searchController = TextEditingController();
  bool _mostrarTodosLosCampos = false;
  int _page = 1;
  int _limit = 10;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _cargarClientes();
    _searchController.addListener(_filtrarClientes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarClientes() async {
    try {
      final response =
          await ClientesApi().getClientes(page: _page, limit: _limit);
      setState(() {
        _clientes = response['clientes'];
        _filteredClientes = List.from(_clientes);
        _total = response['total'];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar clientes: $e')));
    }
  }

  void _filtrarClientes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredClientes = _clientes.where((cliente) {
        return (cliente['nombre']?.toLowerCase().contains(query) ?? false) ||
            (cliente['dui']?.toLowerCase().contains(query) ?? false) ||
            (cliente['telefono']?.toLowerCase().contains(query) ?? false) ||
            (cliente['codigo_cliente']?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  void _editarCliente(Map<String, dynamic> cliente) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => EditarClienteScreen(cliente: cliente)),
    );
    if (result == true) {
      _cargarClientes();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cliente actualizado correctamente')));
    }
  }

  void _eliminarCliente(int id) async {
    try {
      await ClientesApi().deleteCliente(id);
      _cargarClientes();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cliente eliminado correctamente')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar cliente: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomNavigationBar(
        child: Scaffold(
      appBar: AppBar(
        title: Text('Clientes', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AgregarClienteScreen()),
                );
                if (result == true) _cargarClientes();
              },
              icon: Icon(Icons.add),
              label: Text("Nuevo Cliente"),
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
                      hintText: 'Buscar clientes...',
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
              child: _filteredClientes.isEmpty
                  ? Center(child: Text("No hay clientes disponibles"))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: _mostrarTodosLosCampos
                            ? [
                                DataColumn(label: Text('Código')),
                                DataColumn(label: Text('Nombre')),
                                DataColumn(label: Text('DUI')),
                                DataColumn(label: Text('NIT')),
                                DataColumn(label: Text('Tipo')),
                                DataColumn(label: Text('Dirección')),
                                DataColumn(label: Text('Teléfono')),
                                DataColumn(label: Text('Email')),
                                DataColumn(label: Text('Reg. Contribuyente')),
                                DataColumn(label: Text('Rep. Legal')),
                                DataColumn(label: Text('Dir. Rep.')),
                                DataColumn(label: Text('Razón Social')),
                                DataColumn(label: Text('Fecha Inicio')),
                                DataColumn(label: Text('Fecha Fin')),
                                DataColumn(label: Text('% Retención')),
                                DataColumn(label: Text('Acciones')),
                              ]
                            : [
                                DataColumn(label: Text('Código')),
                                DataColumn(label: Text('Nombre')),
                                DataColumn(label: Text('DUI')),
                                DataColumn(label: Text('Teléfono')),
                                DataColumn(label: Text('Acciones')),
                              ],
                        rows: _filteredClientes.map((cliente) {
                          final porcentajeRetencion =
                              cliente['porcentaje_retencion'] != null
                                  ? double.tryParse(
                                          cliente['porcentaje_retencion']
                                              .toString())
                                      ?.toStringAsFixed(2)
                                  : 'N/A';
                          return DataRow(
                            cells: _mostrarTodosLosCampos
                                ? [
                                    DataCell(Text(
                                        cliente['codigo_cliente']?.toString() ??
                                            'N/A')),
                                    DataCell(Text(
                                        cliente['nombre']?.toString() ??
                                            'N/A')),
                                    DataCell(Text(
                                        cliente['dui']?.toString() ?? 'N/A')),
                                    DataCell(Text(
                                        cliente['nit']?.toString() ?? 'N/A')),
                                    DataCell(Text(
                                        cliente['tipo_cliente']?.toString() ??
                                            'N/A')),
                                    DataCell(Text(
                                        cliente['direccion']?.toString() ??
                                            'N/A')),
                                    DataCell(Text(
                                        cliente['telefono']?.toString() ??
                                            'N/A')),
                                    DataCell(Text(
                                        cliente['email']?.toString() ?? 'N/A')),
                                    DataCell(Text(
                                        cliente['registro_contribuyente']
                                                ?.toString() ??
                                            'N/A')),
                                    DataCell(Text(cliente['representante_legal']
                                            ?.toString() ??
                                        'N/A')),
                                    DataCell(Text(
                                        cliente['direccion_representante']
                                                ?.toString() ??
                                            'N/A')),
                                    DataCell(Text(
                                        cliente['razon_social']?.toString() ??
                                            'N/A')),
                                    DataCell(cliente['fecha_inicio'] != null
                                        ? Text(DateFormat('dd/MM/yyyy').format(
                                            DateTime.parse(
                                                cliente['fecha_inicio'])))
                                        : Text('N/A')),
                                    DataCell(cliente['fecha_fin'] != null
                                        ? Text(DateFormat('dd/MM/yyyy').format(
                                            DateTime.parse(
                                                cliente['fecha_fin'])))
                                        : Text('N/A')),
                                    DataCell(Text(porcentajeRetencion!)),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.history),
                                            onPressed: () => showDialog(
                                              context: context,
                                              builder: (_) =>
                                                  HistorialCambiosClientesDialog(
                                                clienteId: cliente['idCliente'],
                                                clienteNombre:
                                                    cliente['nombre'],
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.edit,
                                                color: Colors.blue),
                                            onPressed: () =>
                                                _editarCliente(cliente),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete,
                                                color: Colors.red),
                                            onPressed: () => _eliminarCliente(
                                                cliente['idCliente']),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ]
                                : [
                                    DataCell(Text(
                                        cliente['codigo_cliente']?.toString() ??
                                            'N/A')),
                                    DataCell(Text(
                                        cliente['nombre']?.toString() ??
                                            'N/A')),
                                    DataCell(Text(
                                        cliente['dui']?.toString() ?? 'N/A')),
                                    DataCell(Text(
                                        cliente['telefono']?.toString() ??
                                            'N/A')),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.history),
                                            onPressed: () => showDialog(
                                              context: context,
                                              builder: (_) =>
                                                  HistorialCambiosClientesDialog(
                                                clienteId: cliente['idCliente'],
                                                clienteNombre:
                                                    cliente['nombre'],
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.edit,
                                                color: Colors.blue),
                                            onPressed: () =>
                                                _editarCliente(cliente),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete,
                                                color: Colors.red),
                                            onPressed: () => _eliminarCliente(
                                                cliente['idCliente']),
                                          ),
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
                            _cargarClientes();
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
                            _cargarClientes();
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
