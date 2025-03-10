import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart'; // Asegúrate de agregar este paquete en pubspec.yaml
import 'package:sistema_dy/views/catalogo/registrar_catalogo.dart';

class ListaCatalogo extends StatefulWidget {
  @override
  _ListaCatalogoState createState() => _ListaCatalogoState();
}

class _ListaCatalogoState extends State<ListaCatalogo> {
  late Future<List<dynamic>> catalogo;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> catalogoFiltrado = [];
  List<dynamic> catalogoOriginal = []; // Para almacenar la lista original

  List<dynamic> presentaciones = [];
  List<dynamic> marcas = [];
  List<dynamic> categorias = [];

  @override
  void initState() {
    super.initState();
    catalogo = fetchCatalogo();
    fetchPresentaciones();
    fetchMarcas();
    fetchCategorias();
    _searchController.addListener(_filterCatalogo);
  }

  Future<List<dynamic>> fetchCatalogo() async {
    final url = Uri.parse("http://localhost:3000/api/catalogo");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        catalogoFiltrado = data;
        catalogoOriginal = data; // Guardar la lista original
      });
      return data;
    } else {
      mostrarSnackBar("Error al cargar el catálogo", Colors.red);
      throw Exception("Error al cargar el catálogo");
    }
  }

  Future<void> fetchPresentaciones() async {
    final url = Uri.parse("http://localhost:3000/api/presentacion");
    final response = await http.get(url);
    if (response.statusCode == 200) {
      setState(() {
        presentaciones = jsonDecode(response.body);
      });
    } else {
      mostrarSnackBar("Error al cargar las presentaciones", Colors.red);
    }
  }

  Future<void> fetchMarcas() async {
    final url = Uri.parse("http://localhost:3000/api/marca");
    final response = await http.get(url);
    if (response.statusCode == 200) {
      setState(() {
        marcas = jsonDecode(response.body);
      });
    } else {
      mostrarSnackBar("Error al cargar las marcas", Colors.red);
    }
  }

  Future<void> fetchCategorias() async {
    final url = Uri.parse("http://localhost:3000/api/categoria");
    final response = await http.get(url);
    if (response.statusCode == 200) {
      setState(() {
        categorias = jsonDecode(response.body);
      });
    } else {
      mostrarSnackBar("Error al cargar las categorías", Colors.red);
    }
  }

  void _filterCatalogo() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      catalogoFiltrado = catalogoOriginal.where((producto) {
        return (producto['nombre_producto'] as String)
            .toLowerCase()
            .contains(query);
      }).toList();
    });
  }

  Future<void> eliminarProducto(int id) async {
    bool confirmar = await mostrarDialogoConfirmacion(id);
    if (!confirmar) return;

    final url = Uri.parse("http://localhost:3000/api/catalogo/$id");
    final response = await http.delete(url);

    if (response.statusCode == 200) {
      await fetchCatalogo(); // Actualiza la lista después de eliminar
      mostrarSnackBar("Producto eliminado correctamente", Colors.green);
    } else {
      mostrarSnackBar("Error al eliminar el producto", Colors.red);
    }
  }

  Future<bool> mostrarDialogoConfirmacion(int id) async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 8),
                Text('Confirmar eliminación'),
              ],
            ),
            content: Text("¿Estás seguro de que deseas eliminar este producto?"),
            actions: [
              TextButton(
                child: const Text("Cancelar"),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ) ??
        false;
  }

  void mostrarSnackBar(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mensaje),
      backgroundColor: color,
    ));
  }

  void editarProducto(Map<String, dynamic> producto) {
    TextEditingController nombreController =
        TextEditingController(text: producto['nombre_producto']);
    TextEditingController descripcionController =
        TextEditingController(text: producto['descripcion']);
    TextEditingController codigoController =
        TextEditingController(text: producto['codigo']);

    String? selectedPresentacion = producto['presentacion_id'].toString();
    String? selectedMarca = producto['marca_id'].toString();
    String? selectedCategoria = producto['categoria_id'].toString();

    String? newFilePath;
    String? currentImage = producto['imagen']; // Imagen actual

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text(
                'Editar Producto',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Vista previa: si se selecciona una nueva imagen se muestra la vista previa;
                    // en caso contrario, se muestra la imagen actual
                    if (newFilePath != null)
                      Image.file(
                        File(newFilePath!),
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      )
                    else if (currentImage != null && currentImage.isNotEmpty)
                      Image.network(
                        'http://localhost:3000/uploads/$currentImage',
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    const SizedBox(height: 8),
                    // Botón para seleccionar una nueva imagen
                    ElevatedButton(
                      onPressed: () async {
                        FilePickerResult? result =
                            await FilePicker.platform.pickFiles();
                        if (result != null) {
                          setStateDialog(() {
                            newFilePath = result.files.first.path;
                          });
                        }
                      },
                      child: const Text('Seleccionar nueva imagen'),
                    ),
                    const SizedBox(height: 8),
                    _buildTextField('Código', Icons.code, codigoController),
                    _buildTextField('Nombre', Icons.label, nombreController),
                    _buildTextField('Descripción', Icons.description,
                        descripcionController),
                    // Dropdown para Presentación
                    DropdownButton<String>(
                      value: selectedPresentacion,
                      hint: const Text("Seleccionar Presentación"),
                      items: presentaciones.map((presentacion) {
                        return DropdownMenuItem<String>(
                          value: presentacion['id'].toString(),
                          child: Text(presentacion['nombre']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setStateDialog(() {
                          selectedPresentacion = value;
                        });
                      },
                    ),
                    // Dropdown para Marca
                    DropdownButton<String>(
                      value: selectedMarca,
                      hint: const Text("Seleccionar Marca"),
                      items: marcas.map((marca) {
                        return DropdownMenuItem<String>(
                          value: marca['id'].toString(),
                          child: Text(marca['nombre']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setStateDialog(() {
                          selectedMarca = value;
                        });
                      },
                    ),
                    // Dropdown para Categoría
                    DropdownButton<String>(
                      value: selectedCategoria,
                      hint: const Text("Seleccionar Categoría"),
                      items: categorias.map((categoria) {
                        return DropdownMenuItem<String>(
                          value: categoria['id'].toString(),
                          child: Text(categoria['nombre']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setStateDialog(() {
                          selectedCategoria = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    await actualizarProducto(
                      producto['id'],
                      codigoController.text,
                      nombreController.text,
                      descripcionController.text,
                      selectedPresentacion,
                      selectedMarca,
                      selectedCategoria,
                      newFilePath ?? null, // Si no hay nueva imagen, se envía null
                    );
                    Navigator.of(context).pop();
                  },
                  child: const Text('Guardar cambios'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> actualizarProducto(
    int id,
    String codigo,
    String nombre,
    String descripcion,
    String? presentacionId,
    String? marcaId,
    String? categoriaId,
    String? imagePath, // Si es null, no se envía imagen nueva
  ) async {
    final url = Uri.parse("http://localhost:3000/api/catalogo/$id");
    var request = http.MultipartRequest('PUT', url);

    request.fields['codigo'] = codigo;
    request.fields['nombre_producto'] = nombre;
    request.fields['descripcion'] = descripcion;
    request.fields['presentacion_id'] = presentacionId ?? '';
    request.fields['marca_id'] = marcaId ?? '';
    request.fields['categoria_id'] = categoriaId ?? '';

    // Solo adjuntamos la imagen si se seleccionó una nueva (archivo local)
    if (imagePath != null && imagePath.contains('/')) {
      request.files.add(await http.MultipartFile.fromPath('imagen', imagePath));
    }

    final response = await request.send();

    if (response.statusCode == 200) {
      await fetchCatalogo(); // Actualiza la lista tras la actualización
      mostrarSnackBar("Producto actualizado correctamente", Colors.green);
    } else {
      mostrarSnackBar("Error al actualizar el producto", Colors.red);
    }
  }

  Widget _buildTextField(
      String label, IconData icon, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lista de Productos',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Barra de búsqueda
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search,
                      color: Colors.grey, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Buscar producto...',
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 14),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RegistrarProducto(
                              actualizarLista: fetchCatalogo),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_to_photos, size: 20),
                    label: const Text('Agregar nuevo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A2D3E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Contenedor con la tabla de productos
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 40,
                      horizontalMargin: 24,
                      headingRowHeight: 56,
                      dataRowHeight: 80,
                      headingRowColor:
                          MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) =>
                            Colors.grey[50]!,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black12),
                      ),
                      columns: const [
                        DataColumn(
                            label: Text('Código',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Imagen',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Nombre',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Descripción',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Presentación',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Marca',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Categoría',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Acciones',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold))),
                      ],
                      rows: catalogoFiltrado.map(
                        (producto) => DataRow(
                          cells: [
                            DataCell(
                                Text(producto['codigo'] ?? '')),
                            DataCell(
                              producto['imagen'] != null &&
                                      producto['imagen'].isNotEmpty
                                  ? Image.network(
                                      'http://localhost:3000/uploads/${producto['imagen']}',
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 50,
                                      height: 50,
                                      color: Colors.grey[300],
                                      child: const Icon(
                                          Icons.image, color: Colors.grey),
                                    ),
                            ),
                            DataCell(Text(
                                producto['nombre_producto'] ?? '')),
                            DataCell(Text(
                                producto['descripcion'] ?? '')),
                            DataCell(Text(
                                producto['presentacion_nombre'] ?? '')),
                            DataCell(Text(
                                producto['marca_nombre'] ?? '')),
                            DataCell(Text(
                                producto['categoria_nombre'] ?? '')),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () =>
                                        editarProducto(producto),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () =>
                                        eliminarProducto(producto['id']),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
