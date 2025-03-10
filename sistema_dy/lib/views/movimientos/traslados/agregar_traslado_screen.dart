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
      _mostrarMensaje('Sesión no encontrada. Por favor, inicia sesión.',
          esError: true);
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
      _mostrarMensaje('Error al buscar productos: $e', esError: true);
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
      _mostrarMensaje('Error al cargar sucursales: $e', esError: true);
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
      _mostrarMensaje('Error al cargar sucursales: $e', esError: true);
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
      _mostrarMensaje(
          'Seleccione un producto y especifique una cantidad válida',
          esError: true);
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
      _mostrarMensaje('Usuario no autenticado', esError: true);
      return;
    }

    if (_selectedProductos.isEmpty ||
        _selectedSucursalOrigen == null ||
        _selectedSucursalDestino == null) {
      _mostrarMensaje(
          'Complete todos los campos requeridos y agregue al menos un producto',
          esError: true);
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
      _mostrarMensaje('Traslado agregado correctamente');
      Navigator.pop(context, true);
    } catch (e) {
      _mostrarMensaje('Error al agregar traslado: $e', esError: true);
    }
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("Agregar Traslado",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
        backgroundColor: Colors.grey[50],
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(_empleadoController, "Empleado", readOnly: true),
              SizedBox(height: 12),
              _buildSearchField(
                  _productoController, "Buscar producto", _buscarProductos),
              SizedBox(height: 12),
              _buildProductList(),
              SizedBox(height: 12),
              if (_productoSeleccionado != null)
                Text(
                  "Producto seleccionado: ${_productoSeleccionado!['nombre']} (Código: ${_productoSeleccionado!['codigo']})",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
              SizedBox(height: 12),
              _buildTextField(_cantidadController, "Cantidad",
                  keyboardType: TextInputType.number),
              SizedBox(height: 12),
              _buildButton("Agregar Producto", _agregarProducto),
              SizedBox(height: 12),
              if (_selectedProductos.isNotEmpty) _buildSelectedProducts(),
              SizedBox(height: 12),
              _buildSearchField(_sucursalOrigenSearchController,
                  "Buscar sucursal origen", _buscarSucursalesOrigen),
              SizedBox(height: 12),
              _buildSucursalList(
                  _sucursalesOrigen, _isLoadingSucursalesOrigen, true),
              SizedBox(height: 12),
              if (_selectedSucursalOrigen != null)
                Text(
                  "Sucursal origen seleccionada: $_sucursalOrigenNombre",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[600]),
                ),
              SizedBox(height: 12),
              _buildSearchField(_sucursalDestinoSearchController,
                  "Buscar sucursal destino", _buscarSucursalesDestino),
              SizedBox(height: 12),
              _buildSucursalList(
                  _sucursalesDestino, _isLoadingSucursalesDestino, false),
              SizedBox(height: 12),
              if (_selectedSucursalDestino != null)
                Text(
                  "Sucursal destino seleccionada: $_sucursalDestinoNombre",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[600]),
                ),
              SizedBox(height: 12),
              _buildEstadoDropdown(),
              SizedBox(height: 24),
              _buildButton("Guardar Traslado", _agregarTraslado),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool readOnly = false, TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: 12, color: Colors.grey[600]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        readOnly: readOnly,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 14, color: Colors.black87),
        validator: (value) {
          if (label == "Cantidad" &&
              _productoSeleccionado != null &&
              (value == null || value.isEmpty)) {
            return 'Ingrese una cantidad';
          }
          if (label == "Cantidad") {
            final cantidad = int.tryParse(value ?? '');
            if (cantidad != null && cantidad <= 0)
              return 'Cantidad debe ser mayor a 0';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSearchField(TextEditingController controller, String label,
      Function(String) onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: 12, color: Colors.grey[600]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        onChanged: onChanged,
        style: TextStyle(fontSize: 14, color: Colors.black87),
      ),
    );
  }

  Widget _buildProductList() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: _isLoadingProductos
          ? Center(child: CircularProgressIndicator())
          : _productos.isEmpty
              ? Center(
                  child: Text("No se encontraron productos",
                      style: TextStyle(color: Colors.grey[600], fontSize: 14)))
              : ListView.builder(
                  itemCount: _productos.length,
                  itemBuilder: (context, index) {
                    final producto = _productos[index];
                    return ListTile(
                      title: Text(producto['nombre'] ?? 'N/A',
                          style:
                              TextStyle(fontSize: 14, color: Colors.black87)),
                      subtitle: Text("Código: ${producto['codigo'] ?? 'N/A'}",
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600])),
                      trailing: ElevatedButton(
                        onPressed: () => _seleccionarProducto(producto),
                        child: Text("Seleccionar",
                            style:
                                TextStyle(fontSize: 14, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildSelectedProducts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Productos seleccionados:",
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
        SizedBox(height: 10),
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                  color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
            ],
          ),
          child: ListView.builder(
            itemCount: _selectedProductos.length,
            itemBuilder: (context, index) {
              final producto = _selectedProductos[index];
              return ListTile(
                title: Text(producto['nombre'],
                    style: TextStyle(fontSize: 14, color: Colors.black87)),
                subtitle: Text("Cantidad: ${producto['cantidad']}",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove, color: Colors.grey[600]),
                      onPressed: () => _modificarCantidad(index, -1),
                    ),
                    IconButton(
                      icon: Icon(Icons.add, color: Colors.grey[600]),
                      onPressed: () => _modificarCantidad(index, 1),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red[600]),
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
    );
  }

  Widget _buildSucursalList(
      List<dynamic> sucursales, bool isLoading, bool isOrigen) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: isLoading
          ? Center(child: CircularProgressIndicator())
          : sucursales.isEmpty
              ? Center(
                  child: Text("No se encontraron sucursales",
                      style: TextStyle(color: Colors.grey[600], fontSize: 14)))
              : ListView.builder(
                  itemCount: sucursales.length,
                  itemBuilder: (context, index) {
                    final sucursal = sucursales[index];
                    return ListTile(
                      title: Text(
                          sucursal['nombre'] ??
                              'Sucursal ${sucursal['codigo']}',
                          style:
                              TextStyle(fontSize: 14, color: Colors.black87)),
                      subtitle: Text("Código: ${sucursal['codigo'] ?? 'N/A'}",
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600])),
                      onTap: () {
                        setState(() {
                          if (isOrigen) {
                            _selectedSucursalOrigen = sucursal['codigo'];
                            _sucursalOrigenNombre =
                                sucursal['nombre'] ?? sucursal['codigo'];
                            _sucursalOrigenSearchController.text =
                                _sucursalOrigenNombre ?? sucursal['codigo'];
                            _sucursalesOrigen = [];
                          } else {
                            _selectedSucursalDestino = sucursal['codigo'];
                            _sucursalDestinoNombre =
                                sucursal['nombre'] ?? sucursal['codigo'];
                            _sucursalDestinoSearchController.text =
                                _sucursalDestinoNombre ?? sucursal['codigo'];
                            _sucursalesDestino = [];
                          }
                        });
                      },
                    );
                  },
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
        value: _estadoSeleccionado,
        decoration: InputDecoration(
          labelText: "Estado",
          labelStyle: TextStyle(fontSize: 12, color: Colors.grey[600]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        items: ['Pendiente', 'Completado', 'Cancelado']
            .map((estado) => DropdownMenuItem(
                value: estado,
                child: Text(estado, style: TextStyle(fontSize: 14))))
            .toList(),
        onChanged: (value) => setState(() => _estadoSeleccionado = value!),
        validator: (value) => value == null ? 'Seleccione un estado' : null,
      ),
    );
  }

  Widget _buildButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(label, style: TextStyle(fontSize: 14, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: Colors.blue[600],
          elevation: 2,
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
