import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data'; // Para trabajar con bytes de imagen
import 'dart:io'; // Para manejar los archivos

class RegistrarProductos extends StatefulWidget {
  const RegistrarProductos({super.key});

  @override
  _RegistrarProductosState createState() => _RegistrarProductosState();
}

class _RegistrarProductosState extends State<RegistrarProductos> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _numeroMotorController = TextEditingController();
  final TextEditingController _numeroChasisController = TextEditingController();
  final TextEditingController _categoriaController = TextEditingController();
  final TextEditingController _sucursalController = TextEditingController();
  final TextEditingController _costoController = TextEditingController();
  final TextEditingController _creditoController = TextEditingController();
  final TextEditingController _precioVentaController = TextEditingController();
  final TextEditingController _stockExistenciaController =
      TextEditingController();
  final TextEditingController _stockMinimoController = TextEditingController();
  final TextEditingController _fechaIngresoController = TextEditingController();
  final TextEditingController _fechaReingresoController =
      TextEditingController();
  final TextEditingController _numeroPolizaController = TextEditingController();
  final TextEditingController _numeroLoteController = TextEditingController();
  final TextEditingController _proveedorController = TextEditingController();

  List<dynamic> _categorias = [];
  List<dynamic> _sucursales = [];
  List<dynamic> _proveedores = [];

  String? _selectedCategoria;
  String? _selectedSucursal;
  String? _selectedProveedor;
  Uint8List? _imageBytes; // Para almacenar los bytes de la imagen seleccionada

  @override
  void initState() {
    super.initState();
    _fetchCategorias();
    _fetchSucursales();
    _fetchProveedores();
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
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          prefixIcon: Icon(icon),
        ),
        validator: (value) {
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

  Future<void> _registrarProducto() async {
    if (_formKey.currentState?.validate() ?? false) {
      final codigo = _codigoController.text;
      final nombre = _nombreController.text;
      final descripcion = _descripcionController.text;
      final numeroMotor = _numeroMotorController.text;
      final numeroChasis = _numeroChasisController.text;
      final categoriaId = _selectedCategoria;
      final sucursalId = _selectedSucursal;
      final proveedorId = _selectedProveedor;

      final costo = double.tryParse(_costoController.text);
      final credito = double.tryParse(_creditoController.text);
      final precioVenta = double.tryParse(_precioVentaController.text);
      final stockExistencia = int.tryParse(_stockExistenciaController.text);
      final stockMinimo = int.tryParse(_stockMinimoController.text);

      if (costo == null ||
          credito == null ||
          precioVenta == null ||
          stockExistencia == null ||
          stockMinimo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Por favor, ingresa valores válidos para los campos numéricos')),
        );
        return;
      }

      final fechaIngreso = _fechaIngresoController.text;
      final fechaReingreso = _fechaReingresoController.text;
      final numeroPoliza = _numeroPolizaController.text;
      final numeroLote = _numeroLoteController.text;

      showDialog(
        context: context,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      String? imageUrl;
      if (_imageBytes != null) {
        final imageName =
            'image_${DateTime.now().millisecondsSinceEpoch}.png'; // O cualquier otro nombre que prefieras
        imageUrl = await _uploadImage(
            _imageBytes!, imageName); // Subir imagen y obtener URL
      }

      final response = await http.post(
        Uri.parse('http://localhost:3000/api/inventario'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'codigo': codigo,
          'nombre': nombre,
          'descripcion': descripcion,
          'numero_motor': numeroMotor,
          'numero_chasis': numeroChasis,
          'categoria_id': categoriaId,
          'sucursal_id': sucursalId,
          'costo': costo,
          'credito': credito,
          'precio_venta': precioVenta,
          'stock_existencia': stockExistencia,
          'stock_minimo': stockMinimo,
          'fecha_ingreso': fechaIngreso,
          'fecha_reingreso': fechaReingreso,
          'numero_poliza': numeroPoliza,
          'numero_lote': numeroLote,
          'proveedor_id': proveedorId,
          'imagen': imageUrl, // Añadir la URL de la imagen
        }),
      );

      Navigator.pop(context);

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto registrado correctamente')),
        );
        Navigator.pop(context, true);
      } else {
        final errorData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${errorData['message']}')),
        );
      }
    }
  }

  void _regresarAHome() {
    Navigator.pop(context);
  }

  Future<void> _fetchCategorias() async {
    final response =
        await http.get(Uri.parse('http://localhost:3000/api/categoria'));
    if (response.statusCode == 200) {
      setState(() {
        _categorias = json.decode(response.body);
      });
    }
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

  Future<void> _selectImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.single;
      setState(() {
        // Usamos file.bytes en lugar de file.path
        _imageBytes = file.bytes;
      });
    }
  }

  Widget _buildImagePicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        children: [
          _imageBytes != null
              ? Image.memory(_imageBytes!)
              : const Icon(Icons.image, size: 100),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _selectImage,
            icon: const Icon(Icons.photo_library),
            label: const Text('Seleccionar Imagen'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();
    _numeroMotorController.dispose();
    _numeroChasisController.dispose();
    _categoriaController.dispose();
    _sucursalController.dispose();
    _costoController.dispose();
    _creditoController.dispose();
    _precioVentaController.dispose();
    _stockExistenciaController.dispose();
    _stockMinimoController.dispose();
    _fechaIngresoController.dispose();
    _fechaReingresoController.dispose();
    _numeroPolizaController.dispose();
    _numeroLoteController.dispose();
    _proveedorController.dispose();
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

  Widget _buildCategoriaDropdown() {
    return _buildDropdownField(
      label: "Categoría",
      icon: Icons.category,
      items: _categorias,
      selectedValue: _selectedCategoria,
      onChanged: (value) {
        setState(() {
          _selectedCategoria = value;
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
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
                                  _buildTextField(
                                    controller: _codigoController,
                                    label: "Código",
                                    icon: Icons.code,
                                  ),
                                  _buildTextField(
                                    controller: _nombreController,
                                    label: "Nombre",
                                    icon: Icons.text_fields,
                                  ),
                                  _buildTextField(
                                    controller: _descripcionController,
                                    label: "Descripción",
                                    icon: Icons.description,
                                  ),
                                  _buildTextField(
                                    controller: _numeroMotorController,
                                    label: "Número de Motor",
                                    icon: Icons.motorcycle,
                                  ),
                                  _buildTextField(
                                    controller: _numeroChasisController,
                                    label: "Número de Chasis",
                                    icon: Icons.car_repair,
                                  ),
                                  _buildTextField(
                                    controller: _precioVentaController,
                                    label: "Precio de Venta",
                                    icon: Icons.attach_money,
                                    isNumeric: true,
                                  ),
                                  _buildTextField(
                                    controller: _costoController,
                                    label: "Costo",
                                    icon: Icons.monetization_on,
                                    isNumeric: true,
                                  ),
                                  _buildTextField(
                                    controller: _creditoController,
                                    label: "Credito",
                                    icon: Icons.credit_card,
                                    isNumeric: true,
                                  ),
                                  _buildTextField(
                                    controller: _stockExistenciaController,
                                    label: "Stock Existencia",
                                    icon: Icons.store,
                                    isNumeric: true,
                                  ),
                                  _buildTextField(
                                    controller: _stockMinimoController,
                                    label: "Stock Mínimo",
                                    icon: Icons.store_mall_directory,
                                    isNumeric: true,
                                  ),
                                  _buildDateField(
                                    controller: _fechaIngresoController,
                                    label: "Fecha de Ingreso",
                                    icon: Icons.date_range,
                                  ),
                                  _buildDateField(
                                    controller: _fechaReingresoController,
                                    label: "Fecha de Reingreso",
                                    icon: Icons.date_range,
                                  ),
                                  _buildTextField(
                                    controller: _numeroPolizaController,
                                    label: "Numero de poliza",
                                    icon: Icons.policy,
                                  ),
                                  _buildTextField(
                                    controller: _numeroLoteController,
                                    label: "Numero de lote",
                                    icon: Icons.confirmation_number,
                                  ),
                                  _buildCategoriaDropdown(),
                                  _buildSucursalDropdown(),
                                  _buildProveedorDropdown(),
                                  _buildImagePicker(), // Selector de imagen
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _registrarProducto,
                                    child: const Text('Registrar Producto'),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: _regresarAHome,
                                    child: const Text('Regresar'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<String?> _uploadImage(Uint8List imageBytes, String imageName) async {
    final url = Uri.parse('http://localhost:3000/api/upload'); // Ajusta la URL
    final request = http.MultipartRequest('POST', url);

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: imageName,
      ),
    );

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseData);
        return jsonResponse[
            'imageUrl']; // Ajusta según la respuesta del servidor
      } else {
        print('Error al subir la imagen: ${response.reasonPhrase}');
        return null;
      }
    } catch (e) {
      print('Error al subir la imagen: $e');
      return null;
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
          return DropdownMenuItem<String>(
            value: item['id']
                .toString(), // Ajustar según la estructura de tu lista
            child: Text(item['nombre'] ??
                item['name'] ??
                'Desconocido'), // Ajustar según la propiedad de la lista
          );
        }).toList(),
      ),
    );
  }
}
