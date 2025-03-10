import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:sistema_dy/views/navigation_bar.dart';
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
  String? _selectedCategoria;
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
      _mostrarMensaje('Error al cargar categorías: $e', esError: true);
    }
  }

  Future<void> _cargarOfertas() async {
    try {
      final response = await OfertasApi().getOfertas(
        categoria: _selectedCategoria,
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
      _mostrarMensaje('Error al cargar ofertas: $e', esError: true);
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
      _mostrarMensaje('Oferta actualizada correctamente');
    }
  }

  void _eliminarOferta(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text('Confirmar eliminación',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text('¿Está seguro de que desea eliminar esta oferta?',
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
                await OfertasApi().deleteOferta(id);
                Navigator.pop(context);
                _cargarOfertas();
                _mostrarMensaje('Oferta eliminada correctamente');
              } catch (e) {
                Navigator.pop(context);
                _mostrarMensaje('Error al eliminar oferta: $e', esError: true);
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
          title: Text('Ofertas',
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
                        builder: (context) => AgregarOfertaScreen()),
                  );
                  if (result == true) _cargarOfertas();
                },
                icon: Icon(Icons.add, size: 18, color: Colors.white),
                label: Text("Nueva Oferta",
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
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              _buildFilters(),
              SizedBox(height: 12),
              Expanded(child: _buildDataTable()),
              SizedBox(height: 12),
              _buildPagination(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        Expanded(
            child: _buildDropdown(
                "Filtrar por categoría", _selectedCategoria, _categorias,
                (value) {
          setState(() {
            _selectedCategoria = value;
            _cargarOfertas();
          });
        })),
        SizedBox(width: 12),
        Expanded(child: _buildEstadoDropdown()),
        SizedBox(width: 12),
        Expanded(child: _buildSearchField()),
      ],
    );
  }

  Widget _buildDropdown(String label, String? value, List<dynamic> items,
      Function(String?) onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: DropdownButtonFormField<String?>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
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
                  Text("Todas las categorías", style: TextStyle(fontSize: 14))),
          ...items.map((item) => DropdownMenuItem(
              value: item['nombre'],
              child: Text(item['nombre'], style: TextStyle(fontSize: 14)))),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildEstadoDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedEstado,
        decoration: InputDecoration(
          labelText: "Filtrar por estado",
          labelStyle: TextStyle(fontSize: 12, color: Colors.grey[600]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        items: ['Todas', 'Activa', 'Inactiva', 'Pendiente']
            .map((estado) => DropdownMenuItem(
                value: estado,
                child: Text(estado, style: TextStyle(fontSize: 14))))
            .toList(),
        onChanged: (value) {
          setState(() {
            _selectedEstado = value;
            _page = 1;
            _cargarOfertas();
          });
        },
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
        decoration: InputDecoration(
          hintText: 'Buscar por nombre...',
          hintStyle: TextStyle(fontSize: 14, color: Colors.grey[600]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _cargarOfertas();
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
      child: ofertas.isEmpty
          ? Center(
              child: Text("No hay ofertas disponibles",
                  style: TextStyle(color: Colors.grey[600], fontSize: 14)))
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                columns: [
                  DataColumn(
                      label: Text('Código',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text('Producto',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text('Descuento (%)',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text('Precio Original',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text('Precio con Desc.',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text('Fecha Inicio',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text('Fecha Fin',
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
                rows: ofertas.map((oferta) {
                  return DataRow(cells: [
                    DataCell(Text(oferta['codigo_oferta']?.toString() ?? 'N/A',
                        style: TextStyle(fontSize: 14))),
                    DataCell(Text(
                        oferta['producto_nombre']?.toString() ?? 'N/A',
                        style: TextStyle(fontSize: 14))),
                    DataCell(Text(
                        oferta['descuento'] != null
                            ? '${double.tryParse(oferta['descuento'].toString())?.toStringAsFixed(2)}%'
                            : 'N/A',
                        style: TextStyle(fontSize: 14))),
                    DataCell(Text(
                        oferta['precio_venta'] != null
                            ? '\$${double.tryParse(oferta['precio_venta'].toString())?.toStringAsFixed(2)}'
                            : 'N/A',
                        style: TextStyle(fontSize: 14))),
                    DataCell(Text(
                        oferta['precio_con_descuento'] != null
                            ? '\$${double.tryParse(oferta['precio_con_descuento'].toString())?.toStringAsFixed(2)}'
                            : 'N/A',
                        style: TextStyle(fontSize: 14))),
                    DataCell(oferta['fecha_inicio'] != null
                        ? Text(
                            DateFormat('dd/MM/yyyy HH:mm')
                                .format(DateTime.parse(oferta['fecha_inicio'])),
                            style: TextStyle(fontSize: 14))
                        : Text('N/A', style: TextStyle(fontSize: 14))),
                    DataCell(oferta['fecha_fin'] != null
                        ? Text(
                            DateFormat('dd/MM/yyyy HH:mm')
                                .format(DateTime.parse(oferta['fecha_fin'])),
                            style: TextStyle(fontSize: 14))
                        : Text('N/A', style: TextStyle(fontSize: 14))),
                    DataCell(
                      Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          color: oferta['estado'] == 'Activa'
                              ? Colors.green[100]
                              : oferta['estado'] == 'Inactiva'
                                  ? Colors.red[100]
                                  : Colors.yellow[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          oferta['estado']?.toString() ?? 'N/A',
                          style: TextStyle(
                            fontSize: 14,
                            color: oferta['estado'] == 'Activa'
                                ? Colors.green[600]
                                : oferta['estado'] == 'Inactiva'
                                    ? Colors.red[600]
                                    : Colors.yellow[600],
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
                            icon: Icon(Icons.history, color: Colors.grey[600]),
                            onPressed: () => showDialog(
                              context: context,
                              builder: (_) => HistorialCambiosOfertasDialog(
                                ofertaId: oferta['id'],
                                codigoOferta: oferta['codigo_oferta'],
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue[600]),
                            onPressed: () => _editarOferta(oferta),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red[600]),
                            onPressed: () => _eliminarOferta(oferta['id']),
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
                    _cargarOfertas();
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
                    _cargarOfertas();
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
