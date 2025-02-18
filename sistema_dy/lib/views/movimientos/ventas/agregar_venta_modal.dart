import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'product_service.dart';
import 'ventas_controller.dart';
import 'clientes/clientes_service.dart';
import 'clientes/clientes_model.dart';

class AgregarVentaScreen extends StatefulWidget {
  @override
  _AgregarVentaScreenState createState() => _AgregarVentaScreenState();
}

class _AgregarVentaScreenState extends State<AgregarVentaScreen> {
  final VentasController _ventasController = VentasController();
  final ClientesService _clientesService = ClientesService();
  final ProductService _productService = ProductService();
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final TextEditingController _clienteController = TextEditingController();
  final TextEditingController _direccionClienteController =
      TextEditingController();
  final TextEditingController _duiController = TextEditingController();
  final TextEditingController _nitController = TextEditingController();
  final TextEditingController _notasController = TextEditingController();
  final TextEditingController _subtotalController = TextEditingController();
  final TextEditingController _ivaController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();
  final TextEditingController _codigoProductoController =
      TextEditingController();
  final TextEditingController _precioProductoController =
      TextEditingController();
  final TextEditingController _cantidadController = TextEditingController();
  final TextEditingController _descuentoController = TextEditingController();

  List<Cliente> _clientes = [];
  List<Map<String, dynamic>> _productosSugeridos = [];
  Cliente? _clienteSeleccionado;
  String? _tipoFactura;
  String? _metodoPago;
  DateTime _fechaVenta = DateTime.now();
  List<Map<String, dynamic>> _productosSeleccionados = [];

  // Variables para controlar el foco de los TextField de búsqueda
  bool _clienteTextFieldFocus = false;
  bool _productoTextFieldFocus = false;

  @override
  void initState() {
    super.initState();
    _clienteController.addListener(_buscarClientes);
    _codigoProductoController.addListener(_buscarProductos);
  }

  void _buscarClientes() async {
    if (!_clienteTextFieldFocus)
      return; // Solo buscar si el TextField de cliente tiene foco

    if (_clienteController.text.isEmpty) {
      setState(() => _clientes = []);
      return;
    }

    try {
      final clientes = await _clientesService.obtenerClientes();
      setState(() {
        _clientes = clientes
            .where((c) => c.nombre
                .toLowerCase()
                .contains(_clienteController.text.toLowerCase()))
            .toList();
      });
    } catch (e) {
      print("Error buscando clientes: $e");
    }
  }

  void _buscarProductos() async {
    if (!_productoTextFieldFocus)
      return; // Solo buscar si el TextField de producto tiene foco

    final query = _codigoProductoController.text;
    if (query.isEmpty) {
      setState(() => _productosSugeridos = []);
      return;
    }

    try {
      final response = await http
          .get(Uri.parse('http://localhost:3000/api/inventario?q=$query'));
      if (response.statusCode == 200) {
        setState(() {
          _productosSugeridos =
              List<Map<String, dynamic>>.from(jsonDecode(response.body));
        });
      }
    } catch (e) {
      print("Error buscando productos: $e");
    }
  }

  void _seleccionarCliente(Cliente cliente) {
    setState(() {
      _clienteSeleccionado = cliente;
      _clienteController.text = cliente.nombre;
      _direccionClienteController.text = cliente.direccion ?? 'Sin Dirección';
      _duiController.text = cliente.dui ?? 'Sin DUI';
      _nitController.text = cliente.nit ?? 'Sin NIT';
      _clientes = []; // Limpia las sugerencias
      _clienteTextFieldFocus =
          false; // Quita el foco para que no reaparezcan las sugerencias
    });
    FocusScope.of(context)
        .unfocus(); // Quita el foco del TextField y cierra el teclado
  }

  void _agregarProducto() async {
    // Limpiar y validar código
    final codigo = _codigoProductoController.text.trim();
    if (codigo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese un código de producto válido')),
      );
      return;
    }

    // Validar cantidad
    final cantidad = int.tryParse(_cantidadController.text) ?? 0;
    if (cantidad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese una cantidad mayor a 0')),
      );
      return;
    }

    try {
      // Obtener producto del servicio
      final producto = await _productService.obtenerProductoPorCodigo(codigo);

      // Validar existencia del producto
      if (producto.isEmpty || producto['codigo'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Producto $codigo no encontrado en el sistema')),
        );
        return;
      }

      // Validar stock
      final stockDisponible = producto['stock_existencia'] ?? 0;
      if (stockDisponible < cantidad) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Stock insuficiente: $stockDisponible unidades disponibles'),
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // Obtener precios y descuento
      final precio = double.tryParse(_precioProductoController.text) ??
          producto['precio_venta']?.toDouble() ??
          0.0;
      final descuento = double.tryParse(_descuentoController.text) ?? 0.0;

      // Validar precio positivo
      if (precio <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El precio debe ser mayor a 0')),
        );
        return;
      }

      // Crear objeto del producto
      final nuevoProducto = {
        'codigo': codigo,
        'nombre': producto['nombre'] ?? 'Producto sin nombre',
        'precio_unitario': precio,
        'cantidad': cantidad,
        'descuento':
            descuento.clamp(0.0, 100.0), // Limitar descuento entre 0-100%
        'precio_con_descuento': precio * (1 - descuento.clamp(0.0, 100.0) / 100)
      };

      // Actualizar estado
      setState(() {
        _productosSeleccionados.add(nuevoProducto);
        _codigoProductoController.clear();
        _precioProductoController.clear();
        _cantidadController.clear();
        _descuentoController.clear();
        _productosSugeridos = []; // Limpia sugerencias de productos
        _productoTextFieldFocus =
            false; // Quita el foco para que no reaparezcan las sugerencias
        _calcularTotales();
      });
      FocusScope.of(context)
          .unfocus(); // Quita el foco del TextField y cierra el teclado
    } catch (e) {
      print('Error agregando producto: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error técnico: ${e.toString()}'),
        duration: const Duration(seconds: 5),
      ));
    }
  }

  void _calcularTotales() {
    double subtotal = _productosSeleccionados.fold(0.0, (sum, producto) {
      return sum + (producto['precio_con_descuento'] * producto['cantidad']);
    });

    double iva = subtotal * 0.13;
    double total = subtotal + iva;

    setState(() {
      _subtotalController.text = subtotal.toStringAsFixed(2);
      _ivaController.text = iva.toStringAsFixed(2);
      _totalController.text = total.toStringAsFixed(2);
    });
  }

  void _guardarVenta() async {
    if (_clienteSeleccionado == null ||
        _tipoFactura == null ||
        _metodoPago == null ||
        _productosSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Complete todos los campos requeridos')));
      return;
    }

    try {
      final nuevaVenta = {
        "cliente_id": _clienteSeleccionado!.idCliente,
        "tipo_factura": _tipoFactura,
        "metodo_pago": _metodoPago,
        "subtotal": double.tryParse(_subtotalController.text) ?? 0.0,
        "iva": double.tryParse(_ivaController.text) ?? 0.0,
        "total": double.tryParse(_totalController.text) ?? 0.0,
        "fecha_venta": DateFormat('yyyy-MM-dd').format(_fechaVenta),
        "descripcion_compra": _notasController.text,
        "direccion_cliente": _direccionClienteController.text,
        "dui": _duiController.text,
        "nit": _nitController.text,
        "productos": _productosSeleccionados
            .map((p) => {
                  "codigo_producto": p['codigo'],
                  "nombre": p['nombre'],
                  "cantidad": p['cantidad'],
                  "precio_unitario": p['precio_unitario'],
                  "subtotal": p['precio_unitario'] * p['cantidad']
                })
            .toList(),
      };

      await _ventasController.agregarVenta(nuevaVenta);
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar venta: ${e.toString()}')));
    }
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
            children: [
              // Sección Cliente
              FocusScope(
                // Encierra la búsqueda de cliente con FocusScope
                onFocusChange: (hasFocus) {
                  setState(() {
                    _clienteTextFieldFocus =
                        hasFocus; // Actualiza _clienteTextFieldFocus según el foco
                    if (!hasFocus) {
                      _clientes = []; // Limpia sugerencias si pierde el foco
                    }
                  });
                },
                child: TextFormField(
                  controller: _clienteController,
                  decoration: InputDecoration(
                    labelText: "Buscar Cliente",
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    // Dispara la búsqueda solo si tiene foco
                    if (_clienteTextFieldFocus) {
                      _buscarClientes();
                    }
                  },
                ),
              ),
              if (_clientes.isNotEmpty &&
                  _clienteTextFieldFocus) // Muestra sugerencias solo si hay clientes y el TextField tiene foco
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    itemCount: _clientes.length,
                    itemBuilder: (context, index) => ListTile(
                      title: Text(_clientes[index].nombre),
                      subtitle: Text(_clientes[index].direccion ?? ''),
                      onTap: () => _seleccionarCliente(_clientes[index]),
                    ),
                  ),
                ),
              TextFormField(
                controller: _direccionClienteController,
                decoration: InputDecoration(labelText: "Dirección del Cliente"),
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

              // Sección Datos Venta
              DropdownButtonFormField<String>(
                value: _tipoFactura,
                decoration: InputDecoration(labelText: "Tipo de Factura"),
                items: ['Consumidor Final', 'Crédito Fiscal', 'Ticket']
                    .map((tipo) => DropdownMenuItem(
                          value: tipo,
                          child: Text(tipo),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _tipoFactura = value),
              ),
              DropdownButtonFormField<String>(
                value: _metodoPago,
                decoration: InputDecoration(labelText: "Método de Pago"),
                items:
                    ['Efectivo', 'Tarjeta de Crédito', 'Transferencia Bancaria']
                        .map((metodo) => DropdownMenuItem(
                              value: metodo,
                              child: Text(metodo),
                            ))
                        .toList(),
                onChanged: (value) => setState(() => _metodoPago = value),
              ),
              TextFormField(
                controller: _notasController,
                decoration: InputDecoration(
                    labelText: "Notas o Descripción",
                    hintText: "Detalles adicionales de la venta"),
                maxLines: 2,
              ),

              // Sección Productos
              SizedBox(height: 20),
              Text("Agregar Productos",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              FocusScope(
                // Encerramos la búsqueda de producto con FocusScope
                onFocusChange: (hasFocus) {
                  setState(() {
                    _productoTextFieldFocus =
                        hasFocus; // Actualiza _productoTextFieldFocus según el foco
                    if (!hasFocus) {
                      _productosSugeridos =
                          []; // Limpia sugerencias si pierde el foco
                    }
                  });
                },
                child: TextFormField(
                  controller: _codigoProductoController,
                  decoration: InputDecoration(
                      labelText: "Código/Nombre Producto",
                      prefixIcon: Icon(Icons.search)),
                  onChanged: (value) {
                    // Dispara la búsqueda solo si tiene foco
                    if (_productoTextFieldFocus) {
                      _buscarProductos();
                    }
                  },
                ),
              ),
              if (_productosSugeridos.isNotEmpty &&
                  _productoTextFieldFocus) // Muestra sugerencias solo si hay productos y el TextField tiene foco
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    itemCount: _productosSugeridos.length,
                    itemBuilder: (context, index) => ListTile(
                      title: Text(_productosSugeridos[index]['nombre']),
                      subtitle: Text(
                          "Código: ${_productosSugeridos[index]['codigo']} - Stock: ${_productosSugeridos[index]['stock_existencia']}"),
                      trailing: Text(
                          "\$${_productosSugeridos[index]['precio_venta']}"),
                      onTap: () {
                        _codigoProductoController.text =
                            _productosSugeridos[index]['codigo'];
                        _precioProductoController.text =
                            _productosSugeridos[index]['precio_venta']
                                .toString();
                        setState(() => _productosSugeridos = []);
                        _productoTextFieldFocus =
                            false; // Quita el foco al seleccionar producto
                        FocusScope.of(context)
                            .unfocus(); // Quita el foco del TextField
                      },
                    ),
                  ),
                ),
              TextFormField(
                controller: _precioProductoController,
                decoration: InputDecoration(labelText: "Precio Unitario"),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              TextFormField(
                controller: _cantidadController,
                decoration: InputDecoration(labelText: "Cantidad"),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _descuentoController,
                decoration: InputDecoration(labelText: "Descuento (%)"),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 10),
              ElevatedButton.icon(
                icon: Icon(Icons.add_shopping_cart),
                label: Text("Agregar Producto"),
                onPressed: _agregarProducto,
              ),

              // Lista de Productos Agregados
              if (_productosSeleccionados.isNotEmpty)
                Column(
                  children: [
                    SizedBox(height: 20),
                    Text("Productos en la Venta",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _productosSeleccionados.length,
                      itemBuilder: (context, index) {
                        final producto = _productosSeleccionados[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 5),
                          child: ListTile(
                            title: Text(producto['nombre']),
                            subtitle: Text(
                                "${producto['cantidad']} x \$${producto['precio_unitario'].toStringAsFixed(2)} "
                                "(Descuento: ${producto['descuento']}%)"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                    "\$${(producto['precio_con_descuento'] * producto['cantidad']).toStringAsFixed(2)}"),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      _productosSeleccionados.removeAt(index);
                                      _calcularTotales();
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),

              // Sección Totales
              SizedBox(height: 20),
              Text("Resumen de la Venta",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _subtotalController,
                decoration: InputDecoration(
                    labelText: "Subtotal",
                    border: OutlineInputBorder(),
                    filled: true,
                    prefixText: "\$ "),
                readOnly: true,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _ivaController,
                decoration: InputDecoration(
                    labelText: "IVA (13%)",
                    border: OutlineInputBorder(),
                    filled: true,
                    prefixText: "\$ "),
                readOnly: true,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _totalController,
                decoration: InputDecoration(
                    labelText: "Total",
                    border: OutlineInputBorder(),
                    filled: true,
                    prefixText: "\$ "),
                readOnly: true,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              // Botones Finales
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.save),
                    label: Text("Guardar Venta"),
                    style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
                    onPressed: _guardarVenta,
                  ),
                  ElevatedButton.icon(
                    icon: Icon(Icons.cancel),
                    label: Text("Cancelar"),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        padding:
                            EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
