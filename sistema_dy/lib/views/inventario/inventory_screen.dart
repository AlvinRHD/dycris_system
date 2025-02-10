import 'package:flutter/material.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';
import 'inventory_controller.dart';
import 'product_model.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final InventoryController _controller = InventoryController();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;
  String? _selectedSucursal;
  List<String> _categories = [];
  List<String> _sucursales = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_filterProducts);
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _controller.loadProducts();
      setState(() {
        _products = products;
        _filteredProducts = products;

        _categories = ['Todos'] +
            _products.map((product) => product.categoria).toSet().toList();
        _sucursales = ['Todos'] +
            _products.map((product) => product.sucursal).toSet().toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al cargar productos: $e")));
    }
  }

  void _filterProducts() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _products.where((product) {
        bool matchesSearchQuery =
            product.codigo.toLowerCase().contains(query) ||
                product.nombre.toLowerCase().contains(query) ||
                product.descripcion.toLowerCase().contains(query);

        bool matchesCategory = _selectedCategory == null ||
            _selectedCategory == 'Todos' ||
            product.categoria == _selectedCategory;
        bool matchesSucursal = _selectedSucursal == null ||
            _selectedSucursal == 'Todos' ||
            product.sucursal == _selectedSucursal;

        return matchesSearchQuery && matchesCategory && matchesSucursal;
      }).toList();
    });
  }

  Future<void> _deleteProduct(String productId) async {
    try {
      await _controller.deleteProduct(productId);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Producto eliminado con éxito")));
      _loadProducts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al eliminar producto: $e")));
    }
  }

  Future<void> _confirmDeleteProduct(String productId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Eliminar Producto"),
          content:
              const Text("¿Estás seguro de que deseas eliminar este producto?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Eliminar"),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      _deleteProduct(productId);
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterProducts);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inventario"),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed:
                _loadProducts, // Llama a la función para recargar productos
          ),
        ],
      ),
      body: _products.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              labelText:
                                  'Buscar por código, nombre o descripción',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.search),
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 10.0),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(Icons.filter_list),
                          onPressed: () {
                            // Acción para mostrar/ocultar los filtros
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedCategory,
                            hint: const Text("Seleccionar Categoría"),
                            onChanged: (newCategory) {
                              setState(() {
                                _selectedCategory = newCategory;
                                _filterProducts();
                              });
                            },
                            items: _categories.map<DropdownMenuItem<String>>(
                                (String category) {
                              return DropdownMenuItem<String>(
                                value: category,
                                child: Text(category),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedSucursal,
                            hint: const Text("Seleccionar Sucursal"),
                            onChanged: (newSucursal) {
                              setState(() {
                                _selectedSucursal = newSucursal;
                                _filterProducts();
                              });
                            },
                            items: _sucursales.map<DropdownMenuItem<String>>(
                                (String sucursal) {
                              return DropdownMenuItem<String>(
                                value: sucursal,
                                child: Text(sucursal),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor:
                            MaterialStateProperty.all(Colors.blue.shade100),
                        columnSpacing: 18.0,
                        columns: const <DataColumn>[
                          DataColumn(label: Text('Código')),
                          DataColumn(label: Text('Nombre')),
                          DataColumn(label: Text('Descripción')),
                          DataColumn(label: Text('Numero Motor')),
                          DataColumn(label: Text('Numero Chasis')),
                          DataColumn(label: Text('Categoría')),
                          DataColumn(label: Text('Sucursal')),
                          DataColumn(label: Text('Precio Compra')),
                          DataColumn(label: Text('Precio Venta')),
                          DataColumn(label: Text('Stock Existencia')),
                          DataColumn(label: Text('Stock Mínimo')),
                          DataColumn(label: Text('Fecha Ingreso')),
                          DataColumn(label: Text('Fecha Reingreso')),
                          DataColumn(label: Text('Número Póliza')),
                          DataColumn(label: Text('Número Lote')),
                          DataColumn(label: Text('Acción')),
                        ],
                        rows: _filteredProducts.map<DataRow>((product) {
                          return DataRow(cells: [
                            DataCell(Text(product.codigo)),
                            DataCell(Text(product.nombre)),
                            DataCell(Text(product.descripcion)),
                            DataCell(Text(product.nro_motor)),
                            DataCell(Text(product.nro_chasis)),
                            DataCell(Text(product.categoria)),
                            DataCell(Text(product.sucursal)),
                            DataCell(Text(
                                "\$${product.precioCompra.toStringAsFixed(2)}")),
                            DataCell(Text(
                                "\$${product.precioVenta.toStringAsFixed(2)}")),
                            DataCell(Text("${product.stockExistencia}")),
                            DataCell(Text("${product.stockMinimo}")),
                            DataCell(Text(product.fechaIngreso
                                .toLocal()
                                .toString()
                                .split(' ')[0])),
                            DataCell(Text(product.fechaReingreso
                                .toLocal()
                                .toString()
                                .split(' ')[0])),
                            DataCell(Text(product.nroPoliza)),
                            DataCell(Text(product.nroLote)),
                            DataCell(Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blue),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditProductScreen(
                                          productId: product.id.toString(),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () {
                                    _confirmDeleteProduct(product.codigo);
                                  },
                                ),
                              ],
                            )),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProductFormApp()),
          );
          _loadProducts();
        },
      ),
    );
  }
}
