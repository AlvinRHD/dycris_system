import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'agregar_oferta_screen.dart';
import 'editar_oferta_screen.dart';
import 'ofertas_api.dart';
import 'ofertas_widgets.dart';

class OfertasScreen extends StatefulWidget {
  @override
  _OfertasScreenState createState() => _OfertasScreenState();
}

class _OfertasScreenState extends State<OfertasScreen> {
  List<dynamic> ofertas = [];
  List<dynamic> _categorias = [];
  int? _selectedCategoriaId;
  String _searchQuery = '';
  int _page = 1;
  int _limit = 10;
  int _total = 0;
  String? _selectedEstado = 'Todas';

  @override
  void initState() {
    super.initState();
    _cargarOfertas();
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    try {
      final categorias = await OfertasApi().getCategorias();
      setState(() {
        _categorias = categorias;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar categorías: $e')));
    }
  }

  Future<void> _cargarOfertas() async {
    try {
      final response = await OfertasApi().getOfertas(
        categoriaId: _selectedCategoriaId,
        searchQuery: _searchQuery,
        estado: _selectedEstado != 'Todas' ? _selectedEstado : null,
        page: _page,
        limit: _limit,
      );
      setState(() {
        ofertas = response['ofertas'];
        _total = response['total'];
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error al cargar ofertas: $e')));
    }
  }

  void _editarOferta(Map<String, dynamic> oferta) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => EditarOfertaScreen(oferta: oferta)),
    );
    if (result == true) {
      _cargarOfertas();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Oferta actualizada correctamente')));
    }
  }

  void _eliminarOferta(int id) async {
    try {
      await OfertasApi().deleteOferta(id);
      _cargarOfertas();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Oferta eliminada correctamente')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar oferta: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ofertas', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AgregarOfertaScreen()),
                );
                if (result == true) _cargarOfertas();
              },
              icon: Icon(Icons.add),
              label: Text("Nueva Oferta"),
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
                  child: DropdownButtonFormField<int?>(
                    value: _selectedCategoriaId,
                    decoration: InputDecoration(
                        labelText: "Filtrar por categoría",
                        border: OutlineInputBorder()),
                    items: [
                      DropdownMenuItem(
                          value: null, child: Text("Todas las categorías")),
                      ..._categorias.map((categoria) => DropdownMenuItem(
                          value: categoria['id'],
                          child: Text(categoria['nombre']))),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCategoriaId = value;
                        _cargarOfertas();
                      });
                    },
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedEstado,
                    decoration: InputDecoration(
                        labelText: "Filtrar por estado",
                        border: OutlineInputBorder()),
                    items: ['Todas', 'Activa', 'Inactiva', 'Pendiente']
                        .map((estado) => DropdownMenuItem(
                            value: estado, child: Text(estado)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedEstado = value;
                        _page = 1; // Reinicia la página al cambiar el filtro
                        _cargarOfertas();
                      });
                    },
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _cargarOfertas();
                      });
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Expanded(
              child: ofertas.isEmpty
                  ? Center(child: Text("No hay ofertas disponibles"))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: [
                          DataColumn(label: Text('Código')),
                          DataColumn(label: Text('Producto')),
                          DataColumn(label: Text('Descuento (%)')),
                          DataColumn(label: Text('Precio Original')),
                          DataColumn(label: Text('Precio con Desc.')),
                          DataColumn(label: Text('Fecha Inicio')),
                          DataColumn(label: Text('Fecha Fin')),
                          DataColumn(label: Text('Estado')),
                          DataColumn(label: Text('Acciones')),
                        ],
                        rows: ofertas.map((oferta) {
                          return DataRow(cells: [
                            DataCell(Text(
                                oferta['codigo_oferta']?.toString() ?? 'N/A')),
                            DataCell(Text(
                                oferta['producto_nombre']?.toString() ??
                                    'N/A')),
                            DataCell(Text(oferta['descuento'] != null
                                ? '${double.tryParse(oferta['descuento'].toString())?.toStringAsFixed(2)}%'
                                : 'N/A')),
                            DataCell(Text(oferta['precio_venta'] != null
                                ? '\$${double.tryParse(oferta['precio_venta'].toString())?.toStringAsFixed(2)}'
                                : 'N/A')),
                            DataCell(Text(oferta['precio_con_descuento'] != null
                                ? '\$${double.tryParse(oferta['precio_con_descuento'].toString())?.toStringAsFixed(2)}'
                                : 'N/A')),
                            DataCell(oferta['fecha_inicio'] != null
                                ? Text(DateFormat('dd/MM/yyyy HH:mm').format(
                                    DateTime.parse(oferta['fecha_inicio'])))
                                : Text('N/A')),
                            DataCell(oferta['fecha_fin'] != null
                                ? Text(DateFormat('dd/MM/yyyy HH:mm').format(
                                    DateTime.parse(oferta['fecha_fin'])))
                                : Text('N/A')),
                            DataCell(
                              Container(
                                padding: EdgeInsets.symmetric(
                                    vertical: 4, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: oferta['estado'] == 'Activa'
                                      ? Colors.green[100]
                                      : oferta['estado'] == 'Inactiva'
                                          ? Colors.red[100]
                                          : Colors.yellow[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  oferta['estado']?.toString() ?? 'N/A',
                                  style: TextStyle(
                                    color: oferta['estado'] == 'Activa'
                                        ? Colors.green[700]
                                        : oferta['estado'] == 'Inactiva'
                                            ? Colors.red[700]
                                            : Colors.yellow[700],
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
                                          HistorialCambiosOfertasDialog(
                                        ofertaId: oferta['id'],
                                        codigoOferta: oferta['codigo_oferta'],
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _editarOferta(oferta),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () =>
                                        _eliminarOferta(oferta['id']),
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
                            _cargarOfertas();
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
                            _cargarOfertas();
                          })
                      : null,
                  child: Text("Siguiente"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
