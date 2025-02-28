import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../ventas/auth_helper.dart';
import 'traslados_api.dart';

class AgregarTrasladoScreen extends StatefulWidget {
  @override
  _AgregarTrasladoScreenState createState() => _AgregarTrasladoScreenState();
}

class _AgregarTrasladoScreenState extends State<AgregarTrasladoScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _productoController = TextEditingController();
  final TextEditingController _sucursalOrigenSearchController =
      TextEditingController();
  final TextEditingController _sucursalDestinoSearchController =
      TextEditingController();
  final TextEditingController _cantidadController = TextEditingController();
  final TextEditingController _empleadoController = TextEditingController();
  String _estadoSeleccionado = 'Pendiente';
  List<Map<String, dynamic>> _selectedProductos = [];
  List<dynamic> _productos = [];
  List<dynamic> _sucursalesOrigen = [];
  List<dynamic> _sucursalesDestino = [];
  String? _selectedSucursalOrigen;
  String? _selectedSucursalDestino;
  String? _sucursalOrigenNombre;
  String? _sucursalDestinoNombre;
  bool _isLoadingProductos = false;
  bool _isLoadingSucursalesOrigen = false;
  bool _isLoadingSucursalesDestino = false;
  Map<String, dynamic>? _productoSeleccionado;
  Map<String, dynamic>? _loggedInUser;

  @override
  void initState() {
    super.initState();
    _loadLoggedInUser();
    _buscarProductos('');
    _buscarSucursalesOrigen('');
    _buscarSucursalesDestino('');
  }

  Future<void> _loadLoggedInUser() async {
    _loggedInUser = await AuthHelper.getLoggedInUser();
    if (_loggedInUser != null) {
      setState(() {
        _empleadoController.text = _loggedInUser!['nombre'] ?? 'N/A';
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Sesión no encontrada. Por favor, inicia sesión.')),
      );
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _buscarProductos(String query) async {
    setState(() => _isLoadingProductos = true);
    try {
      final productos = await TrasladosApi().searchProductos(query);
      setState(() {
        _productos = productos;
        _isLoadingProductos = false;
      });
    } catch (e) {
      setState(() => _isLoadingProductos = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al buscar productos: $e')));
    }
  }

  Future<void> _buscarSucursalesOrigen(String query) async {
    setState(() => _isLoadingSucursalesOrigen = true);
    try {
      final sucursales = await TrasladosApi().getSucursales();
      setState(() {
        _sucursalesOrigen = sucursales.where((s) {
          final nombre = s['nombre']?.toString().toLowerCase() ?? '';
          final codigo = s['codigo']?.toString().toLowerCase() ?? '';
          return nombre.contains(query.toLowerCase()) ||
              (query.isEmpty ? true : codigo.contains(query.toLowerCase()));
        }).toList();
        _isLoadingSucursalesOrigen = false;
      });
    } catch (e) {
      setState(() => _isLoadingSucursalesOrigen = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar sucursales: $e')));
    }
  }

  Future<void> _buscarSucursalesDestino(String query) async {
    setState(() => _isLoadingSucursalesDestino = true);
    try {
      final sucursales = await TrasladosApi().getSucursales();
      setState(() {
        _sucursalesDestino = sucursales.where((s) {
          final nombre = s['nombre']?.toString().toLowerCase() ?? '';
          final codigo = s['codigo']?.toString().toLowerCase() ?? '';
          return nombre.contains(query.toLowerCase()) ||
              (query.isEmpty ? true : codigo.contains(query.toLowerCase()));
        }).toList();
        _isLoadingSucursalesDestino = false;
      });
    } catch (e) {
      setState(() => _isLoadingSucursalesDestino = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar sucursales: $e')));
    }
  }

  void _seleccionarProducto(Map<String, dynamic> producto) {
    setState(() {
      _productoSeleccionado = producto;
      _productoController.text = producto['nombre'] ?? 'N/A';
      _productos = [];
    });
  }

  void _agregarProducto() {
    if (_productoSeleccionado == null ||
        _cantidadController.text.isEmpty ||
        int.tryParse(_cantidadController.text) == null ||
        int.parse(_cantidadController.text) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Seleccione un producto y especifique una cantidad válida')),
      );
      return;
    }

    final cantidad = int.parse(_cantidadController.text);
    setState(() {
      final existingProductIndex = _selectedProductos
          .indexWhere((p) => p['codigo'] == _productoSeleccionado!['codigo']);
      if (existingProductIndex != -1) {
        _selectedProductos[existingProductIndex]['cantidad'] += cantidad;
      } else {
        _selectedProductos.add({
          'codigo': _productoSeleccionado!['codigo'],
          'nombre': _productoSeleccionado!['nombre'],
          'cantidad': cantidad,
        });
      }
      _productoSeleccionado = null;
      _productoController.clear();
      _cantidadController.clear();
    });
  }

  void _modificarCantidad(int index, int cambio) {
    setState(() {
      final producto = _selectedProductos[index];
      final nuevaCantidad = producto['cantidad'] + cambio;
      if (nuevaCantidad <= 0) {
        _selectedProductos.removeAt(index);
      } else {
        producto['cantidad'] = nuevaCantidad;
      }
    });
  }

  void _agregarTraslado() async {
    if (!_formKey.currentState!.validate()) return;

    if (_loggedInUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Usuario no autenticado')),
      );
      return;
    }

    if (_selectedProductos.isEmpty ||
        _selectedSucursalOrigen == null ||
        _selectedSucursalDestino == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Complete todos los campos requeridos y agregue al menos un producto')),
      );
      return;
    }

    final traslado = {
      'productos': _selectedProductos,
      'codigo_sucursal_origen': _selectedSucursalOrigen,
      'codigo_sucursal_destino': _selectedSucursalDestino,
      'codigo_empleado': _loggedInUser!['empleado_id']?.toString() ??
          _loggedInUser!['id'].toString(),
      'fecha_traslado':
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      'estado': _estadoSeleccionado,
    };
    try {
      print('Enviando traslado: $traslado'); // Depuración
      await TrasladosApi().addTraslado(traslado);
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al agregar traslado: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Agregar Traslado")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _empleadoController,
                decoration: InputDecoration(
                    labelText: "Empleado", border: OutlineInputBorder()),
                readOnly: true,
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: _productoController,
                decoration: InputDecoration(
                  labelText: "Buscar producto",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: _buscarProductos,
                validator: (value) => _selectedProductos.isEmpty
                    ? 'Agregue al menos un producto'
                    : null,
              ),
              SizedBox(height: 15),
              Container(
                height: 150,
                child: _isLoadingProductos
                    ? Center(child: CircularProgressIndicator())
                    : _productos.isEmpty
                        ? Center(child: Text("No se encontraron productos"))
                        : ListView.builder(
                            itemCount: _productos.length,
                            itemBuilder: (context, index) {
                              final producto = _productos[index];
                              return ListTile(
                                title: Text(producto['nombre'] ?? 'N/A'),
                                subtitle: Text(
                                    "Código: ${producto['codigo'] ?? 'N/A'}"),
                                trailing: ElevatedButton(
                                  onPressed: () =>
                                      _seleccionarProducto(producto),
                                  child: Text("Seleccionar"),
                                ),
                              );
                            },
                          ),
              ),
              SizedBox(height: 15),
              if (_productoSeleccionado != null)
                Text(
                  "Producto seleccionado: ${_productoSeleccionado!['nombre']} (Código: ${_productoSeleccionado!['codigo']})",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              SizedBox(height: 15),
              TextFormField(
                controller: _cantidadController,
                decoration: InputDecoration(
                    labelText: "Cantidad", border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (_productoSeleccionado != null &&
                      (value == null || value.isEmpty)) {
                    return 'Ingrese una cantidad';
                  }
                  final cantidad = int.tryParse(value ?? '');
                  if (cantidad != null && cantidad <= 0)
                    return 'Cantidad debe ser mayor a 0';
                  return null;
                },
              ),
              SizedBox(height: 15),
              ElevatedButton(
                onPressed: _agregarProducto,
                child: Text("Agregar Producto"),
              ),
              SizedBox(height: 15),
              if (_selectedProductos.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Productos seleccionados:",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Container(
                      height: 150,
                      child: ListView.builder(
                        itemCount: _selectedProductos.length,
                        itemBuilder: (context, index) {
                          final producto = _selectedProductos[index];
                          return ListTile(
                            title: Text(producto['nombre']),
                            subtitle: Text("Cantidad: ${producto['cantidad']}"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.remove),
                                  onPressed: () =>
                                      _modificarCantidad(index, -1),
                                ),
                                IconButton(
                                  icon: Icon(Icons.add),
                                  onPressed: () => _modificarCantidad(index, 1),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      _selectedProductos.removeAt(index);
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              SizedBox(height: 15),
              TextFormField(
                controller: _sucursalOrigenSearchController,
                decoration: InputDecoration(
                  labelText: "Buscar sucursal origen",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: _buscarSucursalesOrigen,
                validator: (value) => _selectedSucursalOrigen == null
                    ? 'Seleccione una sucursal origen'
                    : null,
              ),
              SizedBox(height: 15),
              Container(
                height: 150,
                child: _isLoadingSucursalesOrigen
                    ? Center(child: CircularProgressIndicator())
                    : _sucursalesOrigen.isEmpty
                        ? Center(child: Text("No se encontraron sucursales"))
                        : ListView.builder(
                            itemCount: _sucursalesOrigen.length,
                            itemBuilder: (context, index) {
                              final sucursal = _sucursalesOrigen[index];
                              return ListTile(
                                title: Text(sucursal['nombre'] ??
                                    'Sucursal ${sucursal['codigo']}'),
                                subtitle: Text(
                                    "Código: ${sucursal['codigo'] ?? 'N/A'}"),
                                onTap: () {
                                  setState(() {
                                    _selectedSucursalOrigen =
                                        sucursal['codigo'];
                                    _sucursalOrigenNombre =
                                        sucursal['nombre'] ??
                                            sucursal['codigo'];
                                    _sucursalOrigenSearchController.text =
                                        _sucursalOrigenNombre ??
                                            sucursal['codigo'];
                                    _sucursalesOrigen = [];
                                  });
                                },
                              );
                            },
                          ),
              ),
              SizedBox(height: 10),
              if (_selectedSucursalOrigen != null)
                Text(
                  "Sucursal origen seleccionada: $_sucursalOrigenNombre",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.green),
                ),
              SizedBox(height: 15),
              TextFormField(
                controller: _sucursalDestinoSearchController,
                decoration: InputDecoration(
                  labelText: "Buscar sucursal destino",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: _buscarSucursalesDestino,
                validator: (value) {
                  if (_selectedSucursalDestino == null)
                    return 'Seleccione una sucursal destino';
                  if (_selectedSucursalDestino == _selectedSucursalOrigen)
                    return 'La sucursal destino debe ser diferente a la origen';
                  return null;
                },
              ),
              SizedBox(height: 15),
              Container(
                height: 150,
                child: _isLoadingSucursalesDestino
                    ? Center(child: CircularProgressIndicator())
                    : _sucursalesDestino.isEmpty
                        ? Center(child: Text("No se encontraron sucursales"))
                        : ListView.builder(
                            itemCount: _sucursalesDestino.length,
                            itemBuilder: (context, index) {
                              final sucursal = _sucursalesDestino[index];
                              return ListTile(
                                title: Text(sucursal['nombre'] ??
                                    'Sucursal ${sucursal['codigo']}'),
                                subtitle: Text(
                                    "Código: ${sucursal['codigo'] ?? 'N/A'}"),
                                onTap: () {
                                  setState(() {
                                    _selectedSucursalDestino =
                                        sucursal['codigo'];
                                    _sucursalDestinoNombre =
                                        sucursal['nombre'] ??
                                            sucursal['codigo'];
                                    _sucursalDestinoSearchController.text =
                                        _sucursalDestinoNombre ??
                                            sucursal['codigo'];
                                    _sucursalesDestino = [];
                                  });
                                },
                              );
                            },
                          ),
              ),
              SizedBox(height: 10),
              if (_selectedSucursalDestino != null)
                Text(
                  "Sucursal destino seleccionada: $_sucursalDestinoNombre",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.green),
                ),
              SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: _estadoSeleccionado,
                decoration: InputDecoration(
                    labelText: "Estado", border: OutlineInputBorder()),
                items: ['Pendiente', 'Completado', 'Cancelado']
                    .map((estado) =>
                        DropdownMenuItem(value: estado, child: Text(estado)))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _estadoSeleccionado = value!),
                validator: (value) =>
                    value == null ? 'Seleccione un estado' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _agregarTraslado,
                child: Text("Guardar Traslado"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _productoController.dispose();
    _sucursalOrigenSearchController.dispose();
    _sucursalDestinoSearchController.dispose();
    _cantidadController.dispose();
    _empleadoController.dispose();
    super.dispose();
  }
}
