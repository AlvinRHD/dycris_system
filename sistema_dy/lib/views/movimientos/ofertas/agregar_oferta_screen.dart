import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'ofertas_api.dart';

class AgregarOfertaScreen extends StatefulWidget {
  @override
  _AgregarOfertaScreenState createState() => _AgregarOfertaScreenState();
}

class _AgregarOfertaScreenState extends State<AgregarOfertaScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descuentoController = TextEditingController();
  final TextEditingController _productoSeleccionadoController =
      TextEditingController();
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  List<dynamic> _categorias = [];
  List<dynamic> _productos = [];
  int? _selectedCategoriaId;
  String _searchQuery = '';
  int? _selectedProductId;
  bool _isLoading = false;
  double? _precioConDescuento;

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
    _buscarProductos();
    _descuentoController.addListener(_calcularPrecioConDescuento);
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

  Future<void> _buscarProductos() async {
    setState(() => _isLoading = true);
    try {
      final productos = await OfertasApi().searchProductos(
          categoriaId: _selectedCategoriaId, nombre: _searchQuery);
      setState(() {
        _productos = productos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _productos = [];
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al buscar productos: $e')));
    }
  }

  void _calcularPrecioConDescuento() {
    if (_selectedProductId != null && _descuentoController.text.isNotEmpty) {
      final producto =
          _productos.firstWhere((p) => p['id'] == _selectedProductId);
      final precioVenta =
          double.tryParse(producto['precio_venta'].toString()) ?? 0.0;
      final descuento = double.tryParse(_descuentoController.text) ?? 0.0;
      setState(() {
        _precioConDescuento = precioVenta * (1 - descuento / 100);
      });
    } else {
      setState(() {
        _precioConDescuento = null;
      });
    }
  }

  void _agregarOferta() async {
    if (_formKey.currentState!.validate() &&
        _fechaInicio != null &&
        _fechaFin != null &&
        _selectedProductId != null) {
      final oferta = {
        'inventario_id': _selectedProductId,
        'descuento': double.parse(_descuentoController.text),
        'fecha_inicio': DateFormat('yyyy-MM-dd HH:mm:ss').format(_fechaInicio!),
        'fecha_fin': DateFormat('yyyy-MM-dd HH:mm:ss').format(_fechaFin!),
      };
      try {
        await OfertasApi().addOferta(oferta);
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al agregar oferta: $e')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Complete todos los campos requeridos')));
    }
  }

  Future<void> _seleccionarFechaInicio() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      final time =
          await showTimePicker(context: context, initialTime: TimeOfDay.now());
      if (time != null) {
        setState(() {
          _fechaInicio =
              DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  Future<void> _seleccionarFechaFin() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? DateTime.now(),
      firstDate: _fechaInicio ?? DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      final time =
          await showTimePicker(context: context, initialTime: TimeOfDay.now());
      if (time != null) {
        setState(() {
          _fechaFin =
              DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Agregar Oferta")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<int?>(
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
                    _buscarProductos();
                  });
                },
              ),
              SizedBox(height: 15),
              TextField(
                decoration: InputDecoration(
                    labelText: "Buscar producto",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder()),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _buscarProductos();
                  });
                },
              ),
              SizedBox(height: 15),
              Container(
                height: 200,
                child: _isLoading
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
                                trailing: _selectedProductId == producto['id']
                                    ? Icon(Icons.check, color: Colors.green)
                                    : null,
                                onTap: () {
                                  setState(() {
                                    _selectedProductId = producto['id'];
                                    _productoSeleccionadoController.text =
                                        producto['nombre'] ?? 'N/A';
                                    _calcularPrecioConDescuento();
                                  });
                                },
                              );
                            },
                          ),
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: _productoSeleccionadoController,
                decoration: InputDecoration(
                    labelText: "Producto seleccionado",
                    border: OutlineInputBorder()),
                readOnly: true,
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: _descuentoController,
                decoration: InputDecoration(
                    labelText: "Descuento (%)", border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty || double.tryParse(value) == null
                        ? "Ingrese un número válido"
                        : null,
              ),
              SizedBox(height: 15),
              if (_precioConDescuento != null)
                Text(
                    "Precio con Descuento: \$${_precioConDescuento!.toStringAsFixed(2)}"),
              SizedBox(height: 15),
              ListTile(
                title: Text(
                    'Fecha Inicio: ${_fechaInicio != null ? DateFormat('dd/MM/yyyy HH:mm').format(_fechaInicio!) : "No seleccionada"}'),
                trailing: Icon(Icons.calendar_today),
                onTap: _seleccionarFechaInicio,
              ),
              SizedBox(height: 15),
              ListTile(
                title: Text(
                    'Fecha Fin: ${_fechaFin != null ? DateFormat('dd/MM/yyyy HH:mm').format(_fechaFin!) : "No seleccionada"}'),
                trailing: Icon(Icons.calendar_today),
                onTap: _seleccionarFechaFin,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                  onPressed: _agregarOferta, child: Text("Guardar Oferta")),
            ],
          ),
        ),
      ),
    );
  }
}
