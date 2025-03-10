import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegistrarProductos extends StatefulWidget {
  const RegistrarProductos({super.key});

  @override
  _RegistrarProductosState createState() => _RegistrarProductosState();
}

class _RegistrarProductosState extends State<RegistrarProductos> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _comprobanteController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _presentacionController = TextEditingController();
  final TextEditingController _comentarioController = TextEditingController();
  final TextEditingController _numeroMotorController = TextEditingController();
  final TextEditingController _colorrController = TextEditingController();
  final TextEditingController _numeroChasisController = TextEditingController();
  final TextEditingController _categoriaController = TextEditingController();
  final TextEditingController _sucursalController = TextEditingController();
  final TextEditingController _costoUnitController = TextEditingController();
  final TextEditingController _precioVentaController = TextEditingController();
  final TextEditingController _cantidadController = TextEditingController();
  final TextEditingController _fechaIngresoController = TextEditingController();
  final TextEditingController _numeroPolizaController = TextEditingController();
  final TextEditingController _proveedorController = TextEditingController();
  final TextEditingController _busquedaController = TextEditingController();
  final TextEditingController _gananciaController = TextEditingController();
  final TextEditingController _subtotalController = TextEditingController();
  final TextEditingController _ivaController = TextEditingController();
  final TextEditingController _costoTotalController = TextEditingController();
  List<dynamic> _productos = [];
  List<Map<String, dynamic>> _productosSeleccionados = [];
  List<dynamic> _sucursales = [];
  List<dynamic> _proveedores = [];
  Map<String, dynamic> _productoTemporal = {};

  String? _selectedSucursal;
  String? _selectedProveedor;

  @override
  void initState() {
    super.initState();
    _fetchSucursales();
    _fetchProveedores();
    // Listener para el cambio en el Precio de Venta
    _precioVentaController.addListener(_calcularGanancia);

    // Listener para el cambio en el Costo Unitario
    _costoUnitController.addListener(_calcularGanancia);
    // Inicializar los campos de subtotal, IVA y precio total
    _subtotalController.text = '0.00';
    _ivaController.text = '0.00';
    _costoTotalController.text = '0.00';
  }

  void _calcularTotales() {
    double subtotal = 0;
    double iva = 0;
    double precioTotal = 0;

    // Calcular el subtotal sumando el costo total de cada producto sin IVA
    for (var producto in _productosSeleccionados) {
      double precioConIva = producto['costoUnit'];
      double precioSinIva = precioConIva / 1.13; // Quitar el IVA del precio
      subtotal += producto['cantidad'] * precioSinIva;
      precioTotal += producto['cantidad'] * precioConIva; // Total con IVA
    }

    // Calcular el IVA total (13% del subtotal sin IVA)
    iva = subtotal * 0.13;

    // Actualizar los controladores
    setState(() {
      _subtotalController.text = subtotal.toStringAsFixed(2);
      _ivaController.text = iva.toStringAsFixed(2);
      _costoTotalController.text = precioTotal.toStringAsFixed(2);
    });
  }

  void _agregarProductoALista() {
    if (_formKey.currentState?.validate() ?? false) {
      final producto = {
        'nombre': _nombreController.text,
        'presentacion': _presentacionController.text,
        'categoria':
            _productoTemporal['categoria'], // Ensure this is correctly assigned
        'marca':
            _productoTemporal['marca'], // Ensure this is correctly assigned
        'descripcion': _productoTemporal['descripcion'],
        'codigo': _productoTemporal['codigo'],
        'cantidad': int.parse(_cantidadController.text),
        'costoUnit': double.parse(_costoUnitController.text),
        'precioVenta': double.parse(_precioVentaController.text),
        'ganancia': double.parse(_gananciaController.text),
      };

      setState(() {
        _productosSeleccionados.add(producto);
      });

      // Clear fields after adding the product
      _nombreController.clear();
      _presentacionController.clear();
      _cantidadController.clear();
      _costoUnitController.clear();
      _precioVentaController.clear();
      _gananciaController.clear();
      _calcularTotales();
    }
  }

  Widget _buildTablaProductosSeleccionados() {
    return _productosSeleccionados.isEmpty
        ? const Text("No hay productos seleccionados.")
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Nombre')),
                DataColumn(label: Text('Presentación')),
                DataColumn(label: Text('Cantidad')),
                DataColumn(label: Text('Costo Unitario')),
                DataColumn(label: Text('Precio Venta')),
                DataColumn(label: Text('Ganancia (%)')),
                DataColumn(label: Text('Acciones')),
              ],
              rows: _productosSeleccionados.map((producto) {
                return DataRow(cells: [
                  DataCell(Text(producto['nombre'])),
                  DataCell(Text(producto['presentacion'])),
                  DataCell(Text(producto['cantidad'].toString())),
                  DataCell(Text(producto['costoUnit'].toString())),
                  DataCell(Text(producto['precioVenta'].toString())),
                  DataCell(Text(producto['ganancia'].toString())),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _productosSeleccionados.remove(producto);
                          _calcularTotales(); // Recalcular los totales
                        });
                      },
                    ),
                  ),
                ]);
              }).toList(),
            ),
          );
  }

  void _calcularGanancia() {
    // Asegúrate de que ambos campos tengan valores antes de hacer el cálculo
    if (_precioVentaController.text.isNotEmpty &&
        _costoUnitController.text.isNotEmpty) {
      double precioVenta = double.parse(_precioVentaController.text);
      double costoUnit = double.parse(_costoUnitController.text);

      // Cálculo del porcentaje de ganancia
      double ganancia = ((precioVenta - costoUnit) / costoUnit) * 100;

      // Actualizar el campo del porcentaje de ganancia
      setState(() {
        _gananciaController.text =
            ganancia.toStringAsFixed(2); // Redondear a 2 decimales
      });
    } else {
      // Si no hay valores, limpiar el campo de ganancia
      setState(() {
        _gananciaController.text = '';
      });
    }
  }

  Future<void> _fetchProductos() async {
    final query = _busquedaController.text;
    if (query.isNotEmpty) {
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/catalogo?search=$query'),
      );
      if (response.statusCode == 200) {
        setState(() {
          _productos = json.decode(response.body);
          // Limpiar los campos de nombre y presentación al realizar una nueva búsqueda
          _nombreController.clear();
          _presentacionController.clear();
        });
      }
    } else {
      // Si el campo de búsqueda está vacío, no mostrar nada o mostrar todos los productos
      setState(() {
        _productos = [];
        // Limpiar los campos de nombre y presentación
        _nombreController.clear();
        _presentacionController.clear();
      });
    }
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: _busquedaController,
        decoration: InputDecoration(
          labelText: "Buscar Producto",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: (value) {
          _fetchProductos(); // Realizar la búsqueda al escribir
        },
      ),
    );
  }

  Widget _buildProductoList() {
    return _productos.isEmpty
        ? const Text("No se encontraron productos.")
        : ListView.builder(
            shrinkWrap: true,
            itemCount: _productos.length,
            itemBuilder: (context, index) {
              final producto = _productos[index];

              // Agrega las líneas de depuración aquí
              print(
                  "Categoria: ${producto['categoria_nombre']}"); // Verifica si la categoría es nula o vacía
              print(
                  "Marca: ${producto['marca_nombre']}"); // Verifica si la marca es nula o vacía

              return ListTile(
                title:
                    Text(producto['nombre_producto'] ?? 'Nombre desconocido'),
                subtitle: Text(producto['descripcion'] ?? 'Sin descripción'),
                onTap: () {
                  _nombreController.text = producto['nombre_producto'] ?? '';
                  _presentacionController.text =
                      producto['presentacion_nombre'] ?? '';

                  // Ensure categoria and marca are correctly assigned
                  final categoria = producto['categoria_nombre'] ?? '';
                  final marca = producto['marca_nombre'] ?? '';
                  final descripcion = producto['descripcion'] ?? '';
                  final codigo = producto['codigo'] ?? '';

                  _busquedaController.clear();

                  setState(() {
                    _productos = [];
                  });

                  // Assign all necessary fields to _productoTemporal
                  _productoTemporal = {
                    'nombre': producto['nombre_producto'] ?? '',
                    'presentacion': producto['presentacion_nombre'] ?? '',
                    'categoria': categoria,
                    'marca': marca,
                    'descripcion': descripcion,
                    'codigo': codigo,
                  };
                },
              );
            },
          );
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        controller.text = "${pickedDate.toLocal()}".split(' ')[0];
      });
    }
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          prefixIcon: Icon(icon),
        ),
        readOnly: true,
        onTap: () => _selectDate(context, controller),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor ingrese $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isNumeric = false,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          prefixIcon: Icon(icon),
        ),
        validator: (value) {
          // No validar campos de solo lectura
          if (readOnly) {
            return null;
          }
          if (value == null || value.isEmpty) {
            return 'Por favor ingrese $label';
          }
          if (isNumeric) {
            final numValue = num.tryParse(value);
            if (numValue == null) {
              return 'Por favor ingrese un valor numérico válido';
            }
          }
          return null;
        },
      ),
    );
  }

  Future<void> _registrarProductos() async {
    if (_productosSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay productos para registrar')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      for (var producto in _productosSeleccionados) {
        // Imprimir los datos antes de hacer la solicitud HTTP
        print(json.encode({
          'comprobante': _comprobanteController.text,
          'fecha_ingreso': _fechaIngresoController.text,
          'codigo_producto': producto['codigo'],
          'producto': producto['nombre'],
          'cantidad': producto['cantidad'],
          'comentario': _comentarioController.text,
          'proveedor': _selectedProveedor,
          'costo_unit': producto['costoUnit'],
          'costo_total': double.parse(_costoTotalController.text),
          'retencion': 0.0, // Ajusta según sea necesario
          'sucursal': _selectedSucursal,
          'codigo': producto['codigo'],
          'nombre': producto['nombre'],
          'categoria': producto['categoria_nombre'],
          'marca': producto['marca_nombre'],
          'descripcion': producto['descripcion'],
          'stock_existencia': producto['cantidad'],
          'precio_venta': producto['precioVenta'],
          'numero_motor': _numeroMotorController.text,
          'numero_chasis': _numeroChasisController.text,
          'color': _colorrController.text,
          'poliza': _numeroPolizaController.text,
        }));

        final response = await http.post(
          Uri.parse('http://localhost:3000/api/inventario'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'comprobante': _comprobanteController.text,
            'fecha_ingreso': _fechaIngresoController.text,
            'codigo_producto': producto['codigo'],
            'producto': producto['nombre'],
            'cantidad': producto['cantidad'],
            'comentario': _comentarioController.text,
            'proveedor': _selectedProveedor,
            'costo_unit': producto['costoUnit'],
            'costo_total': double.parse(_costoTotalController.text),
            'retencion': 0.0,
            'sucursal': _selectedSucursal,
            'codigo': producto['codigo'],
            'nombre': producto['nombre'],
            'categoria':
                producto['categoria'], // Ensure this is correctly passed
            'marca': producto['marca'], // Ensure this is correctly passed
            'descripcion': producto['descripcion'],
            'stock_existencia': producto['cantidad'],
            'precio_venta': producto['precioVenta'],
            'numero_motor': _numeroMotorController.text,
            'numero_chasis': _numeroChasisController.text,
            'color': _colorrController.text,
            'poliza': _numeroPolizaController.text,
          }),
        );
        if (response.statusCode != 201 && response.statusCode != 200) {
          throw Exception('Error al registrar el producto: ${response.body}');
        }
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Productos registrados correctamente')),
      );

      // Limpiar la lista de productos seleccionados después de guardar
      setState(() {
        _productosSeleccionados.clear();
        _subtotalController.text = '0.00';
        _ivaController.text = '0.00';
        _costoTotalController.text = '0.00';
      });

      // Opcional: Limpiar los campos fijos
      _comprobanteController.clear();
      _comentarioController.clear();
      _numeroMotorController.clear();
      _numeroChasisController.clear();
      _fechaIngresoController.clear();
      _numeroPolizaController.clear();
    } catch (e) {
      Navigator.pop(context); // Cierra el diálogo de carga
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _regresarAHome() {
    Navigator.pop(context);
  }

  Future<void> _fetchSucursales() async {
    final response =
        await http.get(Uri.parse('http://localhost:3000/api/sucursal'));
    if (response.statusCode == 200) {
      setState(() {
        _sucursales = json.decode(response.body);
      });
    }
  }

  Future<void> _fetchProveedores() async {
    final response =
        await http.get(Uri.parse('http://localhost:3000/api/proveedores'));
    if (response.statusCode == 200) {
      setState(() {
        _proveedores = json.decode(response.body);
      });
    }
  }

  @override
  void dispose() {
    _comprobanteController.dispose();
    _nombreController.dispose();
    _presentacionController.dispose();
    _comentarioController.dispose();
    _numeroMotorController.dispose();
    _numeroChasisController.dispose();
    _categoriaController.dispose();
    _sucursalController.dispose();
    _costoUnitController.dispose();
    _precioVentaController.dispose();
    _cantidadController.dispose();
    _fechaIngresoController.dispose();
    _numeroPolizaController.dispose();
    _proveedorController.dispose();
    _precioVentaController.dispose();
    _costoUnitController.dispose();
    _gananciaController.dispose();
    super.dispose();
  }

  Widget _buildProveedorDropdown() {
    return _buildDropdownField(
      label: "Proveedor",
      icon: Icons.business,
      items: _proveedores,
      selectedValue: _selectedProveedor,
      onChanged: (value) {
        setState(() {
          _selectedProveedor = value;
        });
      },
    );
  }

  Widget _buildSucursalDropdown() {
    return _buildDropdownField(
      label: "Sucursal",
      icon: Icons.location_city,
      items: _sucursales,
      selectedValue: _selectedSucursal,
      onChanged: (value) {
        setState(() {
          _selectedSucursal = value;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          "Registro de Producto",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1976D2),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: <Widget>[
                              // Décima fila: Subtotal, IVA y Precio Total
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _subtotalController,
                                      label: "Subtotal",
                                      icon: Icons.calculate,
                                      readOnly: true,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _ivaController,
                                      label: "IVA",
                                      icon: Icons.money_off,
                                      readOnly: true,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _costoTotalController,
                                      label: "Costo Total",
                                      icon: Icons.attach_money,
                                      readOnly: true,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Primera fila
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _comprobanteController,
                                      label: "Comprobante",
                                      icon: Icons.code,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildDateField(
                                      controller: _fechaIngresoController,
                                      label: "Fecha de Ingreso",
                                      icon: Icons.date_range,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Segunda fila
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Expanded(
                                    child: _buildSucursalDropdown(),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildProveedorDropdown(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Tercera fila: Comentario
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Expanded(
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 16.0),
                                      child: TextFormField(
                                        controller: _comentarioController,
                                        maxLines: 5,
                                        decoration: InputDecoration(
                                          labelText: "Comentario",
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          prefixIcon: Icon(Icons.description),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Por favor ingrese un comentario';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Cuarta fila: Buscar Producto
                              _buildSearchField(),
                              const SizedBox(height: 16),

                              // Quinta fila: Lista de Productos
                              SizedBox(
                                height: 200,
                                child: _buildProductoList(),
                              ),

                              // Sexta fila: Nombre y Presentación
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _nombreController,
                                      label: "Nombre del Producto",
                                      icon: Icons.shopping_cart,
                                      readOnly:
                                          true, // Hace que el campo no sea editable
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _presentacionController,
                                      label: "Presentación",
                                      icon: Icons.description,
                                      readOnly:
                                          true, // Hace que el campo no sea editable
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Séptima fila: Cantidad, Costo unitario y Precio de Venta
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _cantidadController,
                                      label: "Cantidad",
                                      icon: Icons.store,
                                      isNumeric: true,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _costoUnitController,
                                      label: "Costo unitario",
                                      icon: Icons.monetization_on,
                                      isNumeric: true,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _precioVentaController,
                                      label: "Precio de Venta",
                                      icon: Icons.attach_money,
                                      isNumeric: true,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Octava fila: Porcentaje de ganancia
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _gananciaController,
                                      label: "Porcentaje de Ganancia",
                                      icon: Icons.percent,
                                      isNumeric: true,
                                      readOnly:
                                          true, // Hace que el campo no sea editable
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Novena fila: Número de Póliza y Número de Motor
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _numeroPolizaController,
                                      label: "Número de Póliza",
                                      icon: Icons.policy,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _numeroMotorController,
                                      label: "Número de Motor",
                                      icon: Icons.motorcycle,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _numeroChasisController,
                                      label: "Número de Chasis",
                                      icon: Icons.directions_car,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _colorrController,
                                      label: "Color",
                                      icon: Icons.motorcycle,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Tabla de productos seleccionados
                              const Text(
                                "Productos Seleccionados",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1976D2),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 200, // Altura fija para la tabla
                                child: _buildTablaProductosSeleccionados(),
                              ),
                              const SizedBox(height: 16),

                              // Botones de acción
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  ElevatedButton(
                                    onPressed: _agregarProductoALista,
                                    child: const Text('Agregar Producto'),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton(
                                    onPressed: _registrarProductos,
                                    child: const Text('Registrar Productos'),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton(
                                    onPressed: _regresarAHome,
                                    child: const Text('Regresar'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildDropdownField({
  required String label,
  required IconData icon,
  required List<dynamic> items,
  String? selectedValue,
  void Function(String?)? onChanged,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16.0),
    child: DropdownButtonFormField<String>(
      value: selectedValue,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: Icon(icon),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor seleccione $label';
        }
        return null;
      },
      items: items.map<DropdownMenuItem<String>>((dynamic item) {
        String displayName = '';
        if (label == "Proveedor") {
          displayName = item['nombre_comercial'] ?? 'Desconocido';
        } else if (label == "Sucursal") {
          displayName = item['nombre'] ?? 'Desconocido';
        }
        return DropdownMenuItem<String>(
          value: item['id'].toString(),
          child: Text(displayName),
        );
      }).toList(),
    ),
  );
}
