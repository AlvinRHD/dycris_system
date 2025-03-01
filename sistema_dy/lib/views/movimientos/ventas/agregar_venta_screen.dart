import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'venta_api.dart';
import 'auth_helper.dart';

class AgregarVentaScreen extends StatefulWidget {
  @override
  _AgregarVentaScreenState createState() => _AgregarVentaScreenState();
}

class _AgregarVentaScreenState extends State<AgregarVentaScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _clienteController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _duiController = TextEditingController();
  final TextEditingController _nitController = TextEditingController();
  final TextEditingController _notasController = TextEditingController();
  final TextEditingController _subtotalController = TextEditingController();
  final TextEditingController _ivaController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();
  final TextEditingController _busquedaProductoController =
      TextEditingController();
  final TextEditingController _precioProductoController =
      TextEditingController();
  final TextEditingController _cantidadController = TextEditingController();
  final TextEditingController _descuentoController = TextEditingController();
  final TextEditingController _empleadoController = TextEditingController();

  ////campos de venta asociados, posiblemente al terminar con pruebas de api ventas las vamos a quitar
  final TextEditingController _facturaController = TextEditingController();
  final TextEditingController _creditoFiscalController =
      TextEditingController();
  final TextEditingController _facturaExportacionController =
      TextEditingController();
  final TextEditingController _notaCreditoController = TextEditingController();
  final TextEditingController _notaDebitoController = TextEditingController();
  final TextEditingController _notaRemisionController = TextEditingController();
  final TextEditingController _liquidacionController = TextEditingController();
  final TextEditingController _retencionController = TextEditingController();
  final TextEditingController _contableLiquidacionController =
      TextEditingController();
  final TextEditingController _donacionController = TextEditingController();
  final TextEditingController _sujetoExcluidoController =
      TextEditingController();
  ////campos de venta asociados, posiblemente al terminar con pruebas de api ventas las vamos a quitar

  List<dynamic> _clientes = [];
  List<dynamic> _productosSugeridos = [];
  Map<String, dynamic>? _clienteSeleccionado;
  Map<String, dynamic>? _loggedInUser;
  String? _tipoFactura;
  String? _metodoPago;
  List<Map<String, dynamic>> _productosSeleccionados = [];
  bool _clienteTextFieldFocus = false;
  bool _productoTextFieldFocus = false;
  bool _descuentoAutorizado = false;
  Map<String, dynamic>? _productoSeleccionado;

  @override
  void initState() {
    super.initState();
    _loadLoggedInUser();
    _clienteController.addListener(_buscarClientes);
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

  void _buscarClientes() async {
    if (!_clienteTextFieldFocus) return;
    final query = _clienteController.text.trim();
    if (query.isEmpty) {
      setState(() => _clientes = []);
      return;
    }
    try {
      final clientes = await VentaApi().searchClientes(query);
      setState(() => _clientes = clientes);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al buscar clientes: $e')));
    }
  }

  void _buscarProductos(String query) async {
    if (!_productoTextFieldFocus || query.isEmpty) {
      setState(() => _productosSugeridos = []);
      return;
    }
    try {
      final productos = await VentaApi().searchProductos(nombre: query);
      setState(() => _productosSugeridos = productos);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al buscar productos: $e')));
    }
  }

  void _seleccionarCliente(Map<String, dynamic> cliente) {
    setState(() {
      _clienteSeleccionado = cliente;
      _clienteController.text = cliente['nombre'];
      _direccionController.text = cliente['direccion'] ?? 'Sin Dirección';
      _duiController.text = cliente['dui'] ?? 'Sin DUI';
      _nitController.text = cliente['nit'] ?? 'Sin NIT';
      _clientes = [];
      _clienteTextFieldFocus = false;
    });
    FocusScope.of(context).unfocus();
  }

  void _seleccionarProducto(Map<String, dynamic> producto) {
    setState(() {
      _productoSeleccionado = producto;
      _busquedaProductoController.text = producto['nombre'];
      _precioProductoController.text = producto['precio_venta'].toString();
      _productosSugeridos = [];
      _productoTextFieldFocus = false;
    });
    FocusScope.of(context).unfocus();
  }

  void _agregarProducto() async {
    final cantidad = int.tryParse(_cantidadController.text) ?? 0;

    if (_productoSeleccionado == null || cantidad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Seleccione un producto y una cantidad válida')),
      );
      return;
    }

    final producto = _productoSeleccionado!;

    setState(() {
      final existingProductIndex = _productosSeleccionados
          .indexWhere((p) => p['codigo_producto'] == producto['codigo']);
      if (existingProductIndex != -1) {
        final currentProduct = _productosSeleccionados[existingProductIndex];
        final newCantidad = currentProduct['cantidad'] + cantidad;
        if (newCantidad > producto['stock_existencia']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Stock insuficiente: ${producto['stock_existencia']} disponibles')),
          );
          return;
        }
        currentProduct['cantidad'] = newCantidad;
        currentProduct['subtotal'] =
            newCantidad * currentProduct['precio_unitario'];
      } else {
        if (producto['stock_existencia'] < cantidad) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Stock insuficiente: ${producto['stock_existencia']} disponibles')),
          );
          return;
        }
        _productosSeleccionados.add({
          'codigo_producto': producto['codigo'],
          'nombre': producto['nombre'],
          'cantidad': cantidad,
          'precio_unitario': double.parse(producto['precio_venta'].toString()),
          'subtotal':
              double.parse(producto['precio_venta'].toString()) * cantidad,
        });
      }
      _busquedaProductoController.clear();
      _precioProductoController.clear();
      _cantidadController.clear();
      _productoSeleccionado = null;
      _productosSugeridos = [];
      _productoTextFieldFocus = false;
      _calcularTotales();
    });
  }

  void _modificarCantidad(int index, int cambio) {
    setState(() {
      final producto = _productosSeleccionados[index];
      final nuevoCantidad = producto['cantidad'] + cambio;
      if (nuevoCantidad <= 0) {
        _productosSeleccionados.removeAt(index);
      } else {
        final productoInfo = _buscarProductoCache(producto['codigo_producto']);
        final stockMaximo = productoInfo != null
            ? productoInfo['stock_existencia']
            : double.infinity;
        if (nuevoCantidad > stockMaximo) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Stock insuficiente: $stockMaximo disponibles')),
          );
          return;
        }
        producto['cantidad'] = nuevoCantidad;
        producto['subtotal'] = nuevoCantidad * producto['precio_unitario'];
      }
      _calcularTotales();
    });
  }

  Map<String, dynamic>? _buscarProductoCache(String codigo) {
    return _productosSugeridos.firstWhere((p) => p['codigo'] == codigo,
        orElse: () => null);
  }

  void _calcularTotales() {
    double subtotal =
        _productosSeleccionados.fold(0.0, (sum, p) => sum + p['subtotal']);
    double descuento = double.tryParse(_descuentoController.text) ?? 0.0;
    if (descuento < 0 || descuento > 100) descuento = 0.0;
    double subtotalConDescuento = subtotal * (1 - descuento / 100);
    double iva = subtotalConDescuento * 0.13;
    double total = subtotalConDescuento + iva;

    setState(() {
      _subtotalController.text = subtotal.toStringAsFixed(2);
      _ivaController.text = iva.toStringAsFixed(2);
      _totalController.text = total.toStringAsFixed(2);
    });
  }

  void _guardarVenta() async {
    if (!_formKey.currentState!.validate()) return;

    if (_loggedInUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Usuario no autenticado')),
      );
      return;
    }

    if (_clienteSeleccionado == null ||
        _tipoFactura == null ||
        _metodoPago == null ||
        _productosSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Complete todos los campos obligatorios')),
      );
      return;
    }

    double descuento = double.tryParse(_descuentoController.text) ?? 0.0;
    String? codigoAutorizacion;

    if (descuento > 0) {
      final tipoCuenta = _loggedInUser!['tipo_cuenta'];
      if (tipoCuenta != 'Admin' &&
          tipoCuenta != 'Root' &&
          !_descuentoAutorizado) {
        final result = await _mostrarModalAutorizacion();
        if (result == null || !result['autorizado']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Autorización de descuento fallida')),
          );
          return;
        }
        codigoAutorizacion = result['codigo'];
        setState(() => _descuentoAutorizado = true);
      }
    }

    try {
      final nuevaVenta = {
        'cliente_id': _clienteSeleccionado!['idCliente'],
        'empleado_id': _loggedInUser!['empleado_id'],
        'tipo_factura': _tipoFactura,
        'metodo_pago': _metodoPago,
        'total': double.parse(_totalController.text),
        'descuento': descuento,
        'fecha_venta': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'descripcion_compra': _notasController.text,
        'productos': _productosSeleccionados,
        'factura': _facturaController.text,
        //campos agregados asociados que posiblemente vamos a eliminar
        'comprobante_credito_fiscal': _creditoFiscalController.text,
        'factura_exportacion': _facturaExportacionController.text,
        'nota_credito': _notaCreditoController.text,
        'nota_debito': _notaDebitoController.text,
        'nota_remision': _notaRemisionController.text,
        'comprobante_liquidacion': _liquidacionController.text,
        'comprobante_retencion': _retencionController.text,
        'documento_contable_liquidacion': _contableLiquidacionController.text,
        'comprobante_donacion': _donacionController.text,
        'factura_sujeto_excluido': _sujetoExcluidoController.text,
        //campos agregados asociados que posiblemente vamos a eliminar

        if (codigoAutorizacion != null)
          'codigo_autorizacion': codigoAutorizacion,
        // No necesitamos enviar sucursal_id desde el frontend, el backend lo maneja por defecto
      };
      await VentaApi().addVenta(nuevaVenta);
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error al guardar venta: $e')));
    }
  }

  Future<Map<String, dynamic>?> _mostrarModalAutorizacion() async {
    final TextEditingController _codigoAutorizacionController =
        TextEditingController();
    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Autorización de Descuento'),
        content: TextField(
          controller: _codigoAutorizacionController,
          decoration: InputDecoration(labelText: 'Código del jefe'),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final autorizado = await VentaApi()
                    .autorizarDescuento(_codigoAutorizacionController.text);
                if (autorizado) {
                  Navigator.pop(context, {
                    'autorizado': true,
                    'codigo': _codigoAutorizacionController.text,
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Código incorrecto')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: Text('Autorizar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Agregar Venta")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sección: Información General
              Text(
                'Información General',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _empleadoController,
                decoration: InputDecoration(labelText: "Empleado"),
                readOnly: true,
              ),
              SizedBox(height: 20),

              // Sección: Agregar Cliente
              Text(
                'Agregar Cliente',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              FocusScope(
                onFocusChange: (focus) =>
                    setState(() => _clienteTextFieldFocus = focus),
                child: TextFormField(
                  controller: _clienteController,
                  decoration: InputDecoration(
                    labelText: "Buscar Cliente",
                    prefixIcon: Icon(Icons.search),
                  ),
                  validator: (value) => _clienteSeleccionado == null
                      ? 'Seleccione un cliente'
                      : null,
                ),
              ),
              if (_clientes.isNotEmpty && _clienteTextFieldFocus)
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    itemCount: _clientes.length,
                    itemBuilder: (context, index) => ListTile(
                      title: Text(_clientes[index]['nombre']),
                      onTap: () => _seleccionarCliente(_clientes[index]),
                    ),
                  ),
                ),
              TextFormField(
                controller: _direccionController,
                decoration: InputDecoration(labelText: "Dirección"),
                readOnly: true,
              ),
              TextFormField(
                controller: _duiController,
                decoration: InputDecoration(labelText: "DUI"),
                readOnly: true,
              ),
              TextFormField(
                controller: _nitController,
                decoration: InputDecoration(labelText: "NIT"),
                readOnly: true,
              ),
              SizedBox(height: 20),

              // Sección: Detalles de la Venta
              Text(
                'Detalles de la Venta',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _tipoFactura,
                decoration: InputDecoration(labelText: "Tipo de Factura"),
                items: ['Consumidor Final', 'Crédito Fiscal', 'Ticket']
                    .map((tipo) =>
                        DropdownMenuItem(value: tipo, child: Text(tipo)))
                    .toList(),
                onChanged: (value) => setState(() => _tipoFactura = value),
                validator: (value) =>
                    value == null ? 'Seleccione un tipo de factura' : null,
              ),
              DropdownButtonFormField<String>(
                value: _metodoPago,
                decoration: InputDecoration(labelText: "Método de Pago"),
                items: [
                  'Efectivo',
                  'Tarjeta de Crédito',
                  'Transferencia Bancaria'
                ]
                    .map((metodo) =>
                        DropdownMenuItem(value: metodo, child: Text(metodo)))
                    .toList(),
                onChanged: (value) => setState(() => _metodoPago = value),
                validator: (value) =>
                    value == null ? 'Seleccione un método de pago' : null,
              ),
              TextFormField(
                controller: _notasController,
                decoration: InputDecoration(labelText: "Notas"),
                maxLines: 2,
              ),
              TextFormField(
                controller: _descuentoController,
                decoration: InputDecoration(labelText: "Descuento (%)"),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  final descuento = double.tryParse(value);
                  if (descuento == null || descuento < 0 || descuento > 100) {
                    return 'Descuento debe estar entre 0 y 100';
                  }
                  return null;
                },
                onChanged: (_) => _calcularTotales(),
              ),
              SizedBox(height: 20),

              // Sección: Agregar Producto
              Text(
                'Agregar Producto',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              FocusScope(
                onFocusChange: (focus) =>
                    setState(() => _productoTextFieldFocus = focus),
                child: TextFormField(
                  controller: _busquedaProductoController,
                  decoration: InputDecoration(
                    labelText: "Buscar Producto (Código o Nombre)",
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: _buscarProductos,
                  validator: (value) => _productosSeleccionados.isEmpty
                      ? 'Agregue al menos un producto'
                      : null,
                ),
              ),
              if (_productosSugeridos.isNotEmpty && _productoTextFieldFocus)
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    itemCount: _productosSugeridos.length,
                    itemBuilder: (context, index) => ListTile(
                      title: Text(_productosSugeridos[index]['nombre']),
                      subtitle: Text(
                          'Código: ${_productosSugeridos[index]['codigo']} - Precio: \$${_productosSugeridos[index]['precio_venta']}'),
                      onTap: () =>
                          _seleccionarProducto(_productosSugeridos[index]),
                    ),
                  ),
                ),
              TextFormField(
                controller: _precioProductoController,
                decoration: InputDecoration(labelText: "Precio"),
                readOnly: true,
              ),
              TextFormField(
                controller: _cantidadController,
                decoration: InputDecoration(labelText: "Cantidad"),
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
              ElevatedButton(
                  onPressed: _agregarProducto, child: Text("Agregar Producto")),
              if (_productosSeleccionados.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _productosSeleccionados.length,
                  itemBuilder: (context, index) {
                    final p = _productosSeleccionados[index];
                    return ListTile(
                      title: Text(p['nombre']),
                      subtitle: Text(
                          "${p['cantidad']} x \$${p['precio_unitario']} = \$${p['subtotal'].toStringAsFixed(2)}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove),
                            onPressed: () => _modificarCantidad(index, -1),
                          ),
                          IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () => _modificarCantidad(index, 1),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => setState(() {
                              _productosSeleccionados.removeAt(index);
                              _calcularTotales();
                            }),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              SizedBox(height: 20),

              // Sección: Totales
              Text(
                'Totales',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _subtotalController,
                decoration: InputDecoration(labelText: "Subtotal"),
                readOnly: true,
              ),
              TextFormField(
                controller: _ivaController,
                decoration: InputDecoration(labelText: "IVA"),
                readOnly: true,
              ),
              TextFormField(
                controller: _totalController,
                decoration: InputDecoration(labelText: "Total"),
                readOnly: true,
              ),
              SizedBox(height: 20),

              // Sección: Documentos Asociados
              Text(
                'Documentos Asociados',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _facturaController,
                decoration: InputDecoration(labelText: "Factura"),
                validator: (value) => value == null || value.isEmpty
                    ? 'Ingrese el número de factura'
                    : null,
              ),
              TextFormField(
                controller: _creditoFiscalController,
                decoration:
                    InputDecoration(labelText: "Comprobante Crédito Fiscal"),
                validator: (value) => value == null || value.isEmpty
                    ? 'Ingrese el comprobante'
                    : null,
              ),
              TextFormField(
                controller: _facturaExportacionController,
                decoration: InputDecoration(labelText: "Factura Exportación"),
                validator: (value) => value == null || value.isEmpty
                    ? 'Ingrese la factura de exportación'
                    : null,
              ),
              TextFormField(
                controller: _notaCreditoController,
                decoration: InputDecoration(labelText: "Nota Crédito"),
                validator: (value) => value == null || value.isEmpty
                    ? 'Ingrese la nota de crédito'
                    : null,
              ),
              TextFormField(
                controller: _notaDebitoController,
                decoration: InputDecoration(labelText: "Nota Débito"),
                validator: (value) => value == null || value.isEmpty
                    ? 'Ingrese la nota de débito'
                    : null,
              ),
              TextFormField(
                controller: _notaRemisionController,
                decoration: InputDecoration(labelText: "Nota Remisión"),
                validator: (value) => value == null || value.isEmpty
                    ? 'Ingrese la nota de remisión'
                    : null,
              ),
              TextFormField(
                controller: _liquidacionController,
                decoration:
                    InputDecoration(labelText: "Comprobante Liquidación"),
                validator: (value) => value == null || value.isEmpty
                    ? 'Ingrese el comprobante de liquidación'
                    : null,
              ),
              TextFormField(
                controller: _retencionController,
                decoration: InputDecoration(labelText: "Comprobante Retención"),
                validator: (value) => value == null || value.isEmpty
                    ? 'Ingrese el comprobante de retención'
                    : null,
              ),
              TextFormField(
                controller: _contableLiquidacionController,
                decoration: InputDecoration(
                    labelText: "Documento Contable Liquidación"),
                validator: (value) => value == null || value.isEmpty
                    ? 'Ingrese el documento contable'
                    : null,
              ),
              TextFormField(
                controller: _donacionController,
                decoration: InputDecoration(labelText: "Comprobante Donación"),
                validator: (value) => value == null || value.isEmpty
                    ? 'Ingrese el comprobante de donación'
                    : null,
              ),
              TextFormField(
                controller: _sujetoExcluidoController,
                decoration:
                    InputDecoration(labelText: "Factura Sujeto Excluido"),
                validator: (value) => value == null || value.isEmpty
                    ? 'Ingrese la factura sujeto excluido'
                    : null,
              ),
              SizedBox(height: 20),

              // Botón Guardar
              ElevatedButton(
                  onPressed: _guardarVenta, child: Text("Guardar Venta")),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _clienteController.dispose();
    _direccionController.dispose();
    _duiController.dispose();
    _nitController.dispose();
    _notasController.dispose();
    _subtotalController.dispose();
    _ivaController.dispose();
    _totalController.dispose();
    _busquedaProductoController.dispose();
    _precioProductoController.dispose();
    _cantidadController.dispose();
    _descuentoController.dispose();
    _empleadoController.dispose();

    ////campos de venta asociados, posiblemente al terminar con pruebas de api ventas las vamos a quitar
    _creditoFiscalController.dispose();
    _facturaExportacionController.dispose();
    _notaCreditoController.dispose();
    _notaDebitoController.dispose();
    _notaRemisionController.dispose();
    _liquidacionController.dispose();
    _retencionController.dispose();
    _contableLiquidacionController.dispose();
    _donacionController.dispose();
    _sujetoExcluidoController.dispose();
    ////campos de venta asociados, posiblemente al terminar con pruebas de api ventas las vamos a quitar
    super.dispose();
  }
}
