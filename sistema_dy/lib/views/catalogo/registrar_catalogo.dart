import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:dropdown_search/dropdown_search.dart';

class Producto {
  final int id;
  final String nombre;

  Producto({required this.id, required this.nombre});

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'],
      nombre: json['nombre'],
    );
  }
}

class RegistrarProducto extends StatefulWidget {
  final Function actualizarLista;

  const RegistrarProducto({Key? key, required this.actualizarLista}) : super(key: key);

  @override
  _RegistrarProductoState createState() => _RegistrarProductoState();
}

class _RegistrarProductoState extends State<RegistrarProducto> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController codigoController = TextEditingController();
  final TextEditingController descripcionController = TextEditingController();
  
  List<Producto> marcas = [];
  List<Producto> presentaciones = [];
  List<Producto> categorias = [];
  
  int? marcaIdSeleccionada;
  int? presentacionIdSeleccionada;
  int? categoriaIdSeleccionada;
  Uint8List? imagenBytes;

  @override
  void initState() {
    super.initState();
    fetchMarcas();
    fetchPresentaciones();
    fetchCategorias();
  }

  Future<void> fetchMarcas() async {
    final url = Uri.parse("http://localhost:3000/api/marca");
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        marcas = data.map((marca) => Producto.fromJson(marca)).toList();
      });
    } else {
      throw Exception("Error al cargar las marcas");
    }
  }

  Future<void> fetchPresentaciones() async {
    final url = Uri.parse("http://localhost:3000/api/presentacion");
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        presentaciones = data.map((presentacion) => Producto.fromJson(presentacion)).toList();
      });
    } else {
      throw Exception("Error al cargar las presentaciones");
    }
  }

  Future<void> fetchCategorias() async {
    final url = Uri.parse("http://localhost:3000/api/categoria");
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        categorias = data.map((categoria) => Producto.fromJson(categoria)).toList();
      });
    } else {
      throw Exception("Error al cargar las categorías");
    }
  }

  Future<void> registrarProducto() async {
    if (_formKey.currentState!.validate()) {
      final url = Uri.parse("http://localhost:3000/api/catalogo");
      final request = http.MultipartRequest('POST', url)
        ..fields['nombre_producto'] = nombreController.text
        ..fields['codigo'] = codigoController.text
        ..fields['presentacion_id'] = presentacionIdSeleccionada.toString()
        ..fields['marca_id'] = marcaIdSeleccionada.toString()
        ..fields['categoria_id'] = categoriaIdSeleccionada.toString()
        ..fields['descripcion'] = descripcionController.text;

      if (imagenBytes != null) {
        request.files.add(http.MultipartFile.fromBytes('imagen', imagenBytes!, filename: 'imagen.png'));
      }

      final response = await request.send();
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto registrado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        widget.actualizarLista();
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al registrar producto'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> seleccionarImagen() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() {
        imagenBytes = result.files.single.bytes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registrar Producto"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                _buildTextField(
                  controller: nombreController,
                  label: "Nombre del Producto",
                  icon: Icons.production_quantity_limits,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: codigoController,
                  label: "Código",
                  icon: Icons.code,
                ),
                const SizedBox(height: 16),
                _buildDropdownWithSearch(
                  label: "Seleccionar Presentación",
                  items: presentaciones,
                  onChanged: (value) {
                    setState(() {
                      presentacionIdSeleccionada = value;
                    });
                  },
                  selectedValue: presentacionIdSeleccionada,
                ),
                const SizedBox(height: 16),
                _buildDropdownWithSearch(
                  label: "Seleccionar Marca",
                  items: marcas,
                  onChanged: (value) {
                    setState(() {
                      marcaIdSeleccionada = value;
                    });
                  },
                  selectedValue: marcaIdSeleccionada,
                ),
                const SizedBox(height: 16),
                _buildDropdownWithSearch(
                  label: "Seleccionar Categoría",
                  items: categorias,
                  onChanged: (value) {
                    setState(() {
                      categoriaIdSeleccionada = value;
                    });
                  },
                  selectedValue: categoriaIdSeleccionada,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: descripcionController,
                  label: "Descripción",
                  icon: Icons.description,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: seleccionarImagen,
                  child: const Text("Seleccionar Imagen"),
                ),
                const SizedBox(height: 20),
                if (imagenBytes != null) 
                  Image.memory(
                    imagenBytes!,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: registrarProducto,
                  child: const Text("Registrar Producto"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
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
          border: const OutlineInputBorder(),
          prefixIcon: Icon(icon),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor ingrese $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdownWithSearch({
  required String label,
  required List<Producto> items,
  required ValueChanged<int?> onChanged,
  int? selectedValue,
}) {
  return DropdownSearch<Producto>(
    popupProps: PopupProps.menu(
      showSearchBox: true,
    ),
    items: items.isNotEmpty ? items : [], // Usar una lista vacía en lugar de `null`
    itemAsString: (Producto? item) => item?.nombre ?? '', // Manejar valores nulos correctamente
    dropdownDecoratorProps: DropDownDecoratorProps(
      dropdownSearchDecoration: InputDecoration(
        labelText: label.isNotEmpty ? label : 'Selecciona un producto', // Asegurarse de que el label no esté vacío
        border: OutlineInputBorder(),
      ),
    ),
    onChanged: (Producto? selectedItem) {
      onChanged(selectedItem?.id);
    },
    selectedItem: items.isNotEmpty
        ? items.firstWhere(
            (item) => item.id == selectedValue,
            orElse: () => Producto(id: 0, nombre: ''), // Valor predeterminado si no se encuentra
          )
        : null,
  );
}


}