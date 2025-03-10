import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:sistema_dy/views/inventario/historial_registro.dart';
import 'dart:convert';
import 'inventario_completo.dart';
import 'registrar_productos.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'historial_ajustes_screen.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  _InventarioScreenState createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  List<Map<String, dynamic>> inventario = [];
  List<Map<String, dynamic>> productosFiltrados = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchInventario();
    _searchController.addListener(_filterProductos);
  }

  Future<void> _fetchInventario() async {
    final url = Uri.parse('http://localhost:3000/api/inventario?tipo=resumido');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          inventario = data.map((e) => e as Map<String, dynamic>).toList();
          productosFiltrados = inventario;
        });
      } else {
        _showErrorDialog('Error al cargar el inventario');
      }
    } catch (error) {
      _showErrorDialog('Error al obtener el inventario: $error');
    }
  }

  void _filterProductos() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      productosFiltrados = inventario.where((producto) {
        return (producto['nombre'] as String).toLowerCase().contains(query);
      }).toList();
    });
  }

  void _showDetallesProducto(String nombre, String descripcion) async {
    final url = Uri.parse(
        'http://localhost:3000/api/inventario/detalles?nombre=$nombre&descripcion=$descripcion');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> detalles = json.decode(response.body);
        _showModalDetalles(detalles);
      } else {
        _showErrorDialog('Error al cargar los detalles del producto');
      }
    } catch (error) {
      _showErrorDialog('Error al obtener los detalles del producto: $error');
    }
  }

  void _showModalDetalles(List<dynamic> detalles) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Detalles del Producto'),
          content: SingleChildScrollView(
            child: DataTable(
              columnSpacing: 40,
              horizontalMargin: 24,
              headingRowHeight: 56,
              dataRowHeight: 80,
              headingRowColor: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) => Colors.grey[50]!,
              ),
              columns: const [
                DataColumn(label: Text('Nombre', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Marca', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Color', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Número de Motor', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Nro.Chasis', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Stock Existencia', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Precio', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: detalles.map<DataRow>((producto) {
                return DataRow(
                  cells: [
                    DataCell(Text(producto['nombre'] ?? '')),
                    DataCell(Text(producto['marca'] ?? '')),
                    DataCell(Text(producto['color'] ?? '')),
                    DataCell(Text(producto['numero_motor'] ?? '')),
                    DataCell(Text(producto['numero_chasis'] ?? '')),
                    DataCell(Text(producto['stock_existencia'].toString() ?? '0')),
                    DataCell(Text('\$${producto['precio_venta']?.toString() ?? '0'}')),
                  ],
                );
              }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showErrorDialog(String message) async {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Productos Registrados',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Barra de búsqueda
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  const Icon(Icons.search, color: Colors.grey, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Buscar producto...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _navegarARegistroProducto,
                    icon: const Icon(Icons.add_to_photos, size: 20),
                    label: const Text('Agregar nuevo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50), // Verde
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                      headingRowColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) => Colors.grey[50]!,
                      ),
                      columns: const [
                        DataColumn(label: Text('Nombre', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Descripción', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Marca', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Stock Total', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: productosFiltrados.map<DataRow>((inventario) {
                        return DataRow(
                          cells: [
                            DataCell(
                              GestureDetector(
                                onTap: () {
                                  _showDetallesProducto(inventario['nombre'], inventario['descripcion']);
                                },
                                child: Text(inventario['nombre'] ?? ''),
                              ),
                            ),
                            DataCell(Text(inventario['descripcion'] ?? '')),
                            DataCell(Text(inventario['marca'] ?? '')),
                            DataCell(Text(inventario['stock_total'].toString() ?? '0')),
                            DataCell(
                              Row(
                                children: [
                                  //IconButton(
                                    //icon: const Icon(Icons.edit, color: Colors.blue),
                                    //onPressed: () => _showEditProductoDialog(inventario),
                                  //),
                                //  IconButton(
                                  //  icon: const Icon(Icons.delete, color: Colors.red),
                                    //onPressed: () => _confirmDelete(inventario['id']),
                                  //),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Botones adicionales
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 150,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InventarioCompletoScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3), // Azul
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 5,
                    ),
                    child: const Text(
                      'Ver tabla completa',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20), // Espacio entre los botones
                SizedBox(
                  width: 150,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HistorialApp(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50), // Verde
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 5,
                    ),
                    child: const Text(
                      'Historial de Ajustes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20), // Espacio entre los botones
                SizedBox(
                  width: 150,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HistorialIngresoScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 175, 129, 76), // Verde
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 5,
                    ),
                    child: const Text(
                      'Historial de Ingreso',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Confirmar eliminación'),
          ],
        ),
        content: const Text('¿Está seguro de eliminar el producto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _deleteProducto(id);
    }
  }

  Future<void> _deleteProducto(int id) async {
    final url = Uri.parse('http://localhost:3000/api/inventario/$id');
    try {
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        await _showAlertDialog(
          'Éxito',
          'Producto eliminado exitosamente',
          Icons.check_circle,
          Colors.green,
        );
        _fetchInventario();
      } else {
        await _showAlertDialog(
          'Error',
          'Error al eliminar el producto',
          Icons.error,
          Colors.red,
        );
      }
    } catch (e) {
      await _showAlertDialog(
        'Error',
        'Error al eliminar el producto: $e',
        Icons.error,
        Colors.red,
      );
    }
  }

  Future<void> _showAlertDialog(
      String title, String message, IconData icon, Color iconColor) async {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProducto(
    String nombre,
    String descripcion,
    String precioVenta,
    String motivoCambio,
    String? imageUrl,
  ) async {
    final url = Uri.parse('http://localhost:3000/api/inventario/edit');
    final Map<String, dynamic> body = {
      'nombre': nombre,
      'descripcion': descripcion,
      'precio_venta': precioVenta,
      'motivo': motivoCambio,
      'imagen': imageUrl,
    };

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        await _showAlertDialog(
          'Éxito',
          'Producto actualizado exitosamente',
          Icons.check_circle,
          Colors.green,
        );
        _fetchInventario();
      } else {
        await _showAlertDialog(
          'Error',
          'Error al actualizar el producto',
          Icons.error,
          Colors.red,
        );
      }
    } catch (e) {
      await _showAlertDialog(
        'Error',
        'Error al actualizar el producto: $e',
        Icons.error,
        Colors.red,
      );
    }
  }

  Future<void> _showEditProductoDialog(Map<String, dynamic> productoData) async {
    final TextEditingController nombreController =
        TextEditingController(text: productoData['nombre'] ?? '');
    final TextEditingController descripcionController =
        TextEditingController(text: productoData['descripcion'] ?? '');
    final TextEditingController precioVentaController =
        TextEditingController(text: productoData['precio_venta'] ?? '');
    final TextEditingController motivoCambioController =
        TextEditingController(text: ''); // Inicializar con un valor vacío

    Uint8List? imageBytes;
    String? imageName;

    // Obtener la URL de la imagen actual (si existe)
    String? currentImageUrl = productoData['imagen'];

    return showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return AlertDialog(
              title: const Text(
                'Editar Producto',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField('Nombre', Icons.business, nombreController),
                    _buildTextField('Descripción', Icons.description, descripcionController),
                    _buildTextField('Precio de Venta', Icons.attach_money, precioVentaController),
                    _buildTextField('Motivo del Cambio', Icons.edit_note, motivoCambioController),

                    // Mostrar la imagen actual o la nueva, dependiendo de si hay una nueva seleccionada
                    if (imageBytes != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Image.memory(imageBytes!, height: 100),
                      )
                    else if (currentImageUrl != null && currentImageUrl.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Image.network(
                          currentImageUrl,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),

                    // Selector de imagen
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.image,
                          withData: true,
                        );

                        if (result != null && result.files.isNotEmpty) {
                          setStateModal(() {
                            imageBytes = result.files.first.bytes;
                            imageName = result.files.first.name;
                          });
                        }
                      },
                      icon: const Icon(Icons.image),
                      label: const Text("Seleccionar Imagen"),
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    if (nombreController.text.trim().isEmpty ||
                        descripcionController.text.trim().isEmpty ||
                        precioVentaController.text.trim().isEmpty ||
                        motivoCambioController.text.trim().isEmpty) {
                      await _showAlertDialog(
                        'Error',
                        'Todos los campos son obligatorios',
                        Icons.warning,
                        Colors.orange,
                      );
                      return;
                    }

                    // Subir imagen si hay una nueva seleccionada
                    String? nuevaImagenUrl;
                    if (imageBytes != null && imageName != null) {
                      nuevaImagenUrl = await _uploadImage(imageBytes!, imageName!);
                    } else {
                      // Si no hay una imagen nueva, mantener la imagen actual
                      nuevaImagenUrl = currentImageUrl;
                    }

                    // Actualizar el producto con la nueva imagen
                    await _updateProducto(
                      nombreController.text.trim(),
                      descripcionController.text.trim(),
                      precioVentaController.text.trim(),
                      motivoCambioController.text.trim(),
                      nuevaImagenUrl,
                    );

                    if (mounted) {
                      Navigator.of(context).pop();
                    }
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

  Future<String?> _uploadImage(Uint8List imageBytes, String imageName) async {
    final url = Uri.parse('http://localhost:3000/api/upload');
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
        return jsonResponse['imageUrl'];
      } else {
        print('Error al subir la imagen: ${response.reasonPhrase}');
        return null;
      }
    } catch (e) {
      print('Error al subir la imagen: $e');
      return null;
    }
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        ),
        textInputAction: TextInputAction.next,
      ),
    );
  }

  void _navegarARegistroProducto() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegistrarProductos()),
    );

    if (resultado == true) {
      _fetchInventario();
    }
  }
}