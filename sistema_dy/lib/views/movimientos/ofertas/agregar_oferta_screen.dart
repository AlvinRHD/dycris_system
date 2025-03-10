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
  String? _selectedCategoria;
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
      _mostrarMensaje('Error al cargar categorías: $e', esError: true);
    }
  }

  Future<void> _buscarProductos() async {
    setState(() => _isLoading = true);
    try {
      final productos = await OfertasApi()
          .searchProductos(categoria: _selectedCategoria, nombre: _searchQuery);
      setState(() {
        _productos = productos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _productos = [];
        _isLoading = false;
      });
      _mostrarMensaje('Error al buscar productos: $e', esError: true);
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
    if (_formKey.currentState!.validate()) {
      if (_selectedProductId == null) {
        _mostrarMensaje('Seleccione un producto', esError: true);
        return;
      }
      if (_fechaInicio == null || _fechaFin == null) {
        _mostrarMensaje('Seleccione las fechas de inicio y fin', esError: true);
        return;
      }
      if (_fechaFin!.isBefore(_fechaInicio!)) {
        _mostrarMensaje('La fecha fin debe ser posterior a la fecha inicio',
            esError: true);
        return;
      }

      final oferta = {
        'inventario_id': _selectedProductId,
        'descuento': double.parse(_descuentoController.text),
        'fecha_inicio': DateFormat('yyyy-MM-dd HH:mm:ss').format(_fechaInicio!),
        'fecha_fin': DateFormat('yyyy-MM-dd HH:mm:ss').format(_fechaFin!),
      };
      try {
        await OfertasApi().addOferta(oferta);
        _mostrarMensaje('Oferta agregada correctamente');
        Navigator.pop(context, true);
      } catch (e) {
        _mostrarMensaje('Error al agregar oferta: $e', esError: true);
      }
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
        title: Text("Agregar Oferta",
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
              _buildDropdownField(),
              SizedBox(height: 12),
              _buildSearchField(),
              SizedBox(height: 12),
              _buildProductList(),
              SizedBox(height: 12),
              _buildTextField(
                  _productoSeleccionadoController, "Producto seleccionado",
                  readOnly: true),
              SizedBox(height: 12),
              _buildTextField(_descuentoController, "Descuento (%)",
                  keyboardType: TextInputType.number),
              SizedBox(height: 12),
              if (_precioConDescuento != null)
                Text(
                  "Precio con Descuento: \$${_precioConDescuento!.toStringAsFixed(2)}",
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
              SizedBox(height: 12),
              _buildDateTile(
                  "Fecha Inicio", _fechaInicio, _seleccionarFechaInicio),
              SizedBox(height: 12),
              _buildDateTile("Fecha Fin", _fechaFin, _seleccionarFechaFin),
              if (_fechaInicio != null &&
                  _fechaFin != null &&
                  _fechaFin!.isBefore(_fechaInicio!))
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'La fecha fin debe ser posterior a la fecha inicio',
                    style: TextStyle(color: Colors.red[600], fontSize: 12),
                  ),
                ),
              SizedBox(height: 24),
              _buildButton("Guardar Oferta", _agregarOferta),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: DropdownButtonFormField<String?>(
        value: _selectedCategoria,
        decoration: InputDecoration(
          labelText: "Filtrar por categoría",
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
          ..._categorias.map((categoria) => DropdownMenuItem(
              value: categoria['nombre'],
              child:
                  Text(categoria['nombre'], style: TextStyle(fontSize: 14)))),
        ],
        onChanged: (value) {
          setState(() {
            _selectedCategoria = value;
            _buscarProductos();
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
          labelText: "Buscar producto",
          labelStyle: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
            _buscarProductos();
          });
        },
      ),
    );
  }

  Widget _buildProductList() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: _isLoading
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
                      trailing: _selectedProductId == producto['id']
                          ? Icon(Icons.check, color: Colors.green[600])
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
          if (label == "Producto seleccionado" && _selectedProductId == null)
            return 'Seleccione un producto';
          if (label == "Descuento (%)" && (value == null || value.isEmpty))
            return 'Ingrese un descuento';
          if (label == "Descuento (%)") {
            final descuento = double.tryParse(value!);
            if (descuento == null || descuento <= 0 || descuento > 100)
              return 'El descuento debe estar entre 0 y 100';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDateTile(String label, DateTime? date, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: ListTile(
        title: Text(
          '$label: ${date != null ? DateFormat('dd/MM/yyyy HH:mm').format(date) : "No seleccionada"}',
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
        trailing: Icon(Icons.calendar_today, color: Colors.grey[600]),
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
    _descuentoController.dispose();
    _productoSeleccionadoController.dispose();
    super.dispose();
  }
}
