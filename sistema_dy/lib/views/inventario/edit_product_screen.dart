import 'package:flutter/material.dart';

import 'inventory_controller.dart';
import 'product_model.dart';

class EditProductScreen extends StatefulWidget {
  final String productId;

  const EditProductScreen({super.key, required this.productId});

  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final InventoryController _inventoryController = InventoryController();

  // Controladores para los campos
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _motorController = TextEditingController();
  final TextEditingController _chasisController = TextEditingController();
  final TextEditingController _branchController =
      TextEditingController(); // sucursal
  final TextEditingController _purchasePriceController =
      TextEditingController();
  final TextEditingController _creditController = TextEditingController();
  final TextEditingController _salePriceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _minStockController = TextEditingController();
  final TextEditingController _entryDateController = TextEditingController();
  final TextEditingController _reentryDateController = TextEditingController();
  final TextEditingController _policyController = TextEditingController();
  final TextEditingController _lotController = TextEditingController();

  Product? _product;

  @override
  void initState() {
    super.initState();
    print('productId recibido: ${widget.productId}');
    _loadProductData();
  }

  Future<void> _loadProductData() async {
    try {
      final product =
          await _inventoryController.getProductById(widget.productId);
      setState(() {
        _product = product;
        _codeController.text = product.codigo;
        _nameController.text = product.nombre;
        _descriptionController.text = product.descripcion;
        _categoryController.text = product.categoria;
        _motorController.text = product.nro_motor;
        _chasisController.text = product.nro_chasis;
        _branchController.text = product.sucursal;
        _purchasePriceController.text = product.precioCompra.toString();
        _creditController.text = product.credito.toString();
        _salePriceController.text = product.precioVenta.toString();
        _stockController.text = product.stockExistencia.toString();
        _minStockController.text = product.stockMinimo.toString();
        _entryDateController.text =
            product.fechaIngreso.toLocal().toString().split(' ')[0];
        _reentryDateController.text =
            product.fechaReingreso.toLocal().toString().split(' ')[0];
        _policyController.text = product.nroPoliza;
        _lotController.text = product.nroLote;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar el producto: $e')),
      );
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final updatedProduct = Product(
        id: _product!.id,
        codigo: _codeController.text,
        nombre: _nameController.text,
        descripcion: _descriptionController.text,
        nro_motor: _motorController.text,
        nro_chasis: _chasisController.text,
        categoria: _categoryController.text,
        sucursal: _branchController.text,
        precioCompra: double.tryParse(_purchasePriceController.text) ?? 0.0,
        credito: double.tryParse(_creditController.text) ?? 0.0,
        precioVenta: double.tryParse(_salePriceController.text) ?? 0.0,
        stockExistencia: int.tryParse(_stockController.text) ?? 0,
        stockMinimo: int.tryParse(_minStockController.text) ?? 0,
        fechaIngreso:
            DateTime.tryParse(_entryDateController.text) ?? DateTime.now(),
        fechaReingreso:
            DateTime.tryParse(_reentryDateController.text) ?? DateTime.now(),
        nroPoliza: _policyController.text,
        nroLote: _lotController.text,
      );

      try {
        // Pasar el ID del producto junto con el objeto actualizado
        await _inventoryController.updateProduct(
            widget.productId, updatedProduct);
        _showSuccessMessage();
        await Future.delayed(const Duration(seconds: 1));
        Navigator.pop(context); // Regresa a la pantalla anterior
      } catch (e) {
        _showErrorMessage();
      }
    }
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Producto actualizado con éxito'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showErrorMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Error al actualizar el producto'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Producto'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: _product == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                        'Información Básica', Icons.shopping_bag),
                    _buildResponsiveGrid([
                      _buildTextFieldWithIcon(
                          'Código', Icons.qr_code, _codeController),
                      _buildTextFieldWithIcon(
                          'Nombre', Icons.text_fields, _nameController),
                      _buildTextFieldWithIcon('Descripción', Icons.description,
                          _descriptionController),
                      _buildTextFieldWithIcon(
                          'Categoría', Icons.category, _categoryController),
                      _buildTextFieldWithIcon(
                          'Sucursal', Icons.store, _branchController),
                    ]),
                    _buildSectionHeader(
                        'Detalles del Producto', Icons.settings),
                    _buildResponsiveGrid([
                      _buildTextFieldWithIcon(
                          'N° Motor', Icons.directions_car, _motorController),
                      _buildTextFieldWithIcon(
                          'N° Chasis', Icons.car_repair, _chasisController),
                      _buildNumberFieldWithIcon('Precio Compra',
                          Icons.monetization_on, _purchasePriceController),
                      _buildNumberFieldWithIcon(
                          'Crédito', Icons.credit_card, _creditController),
                      _buildNumberFieldWithIcon('Precio Venta',
                          Icons.attach_money, _salePriceController),
                    ]),
                    _buildSectionHeader(
                        'Gestión de Inventario', Icons.inventory),
                    _buildResponsiveGrid([
                      _buildNumberFieldWithIcon(
                          'Stock Existente', Icons.warehouse, _stockController),
                      _buildNumberFieldWithIcon(
                          'Stock Mínimo', Icons.warning, _minStockController),
                      _buildDateFieldWithIcon('Fecha Ingreso',
                          Icons.calendar_today, _entryDateController),
                      _buildDateFieldWithIcon('Fecha Reingreso',
                          Icons.event_repeat, _reentryDateController),
                    ]),
                    _buildSectionHeader('Identificadores', Icons.fingerprint),
                    _buildResponsiveGrid([
                      _buildTextFieldWithIcon(
                          'N° de Póliza', Icons.assignment, _policyController),
                      _buildTextFieldWithIcon('N° Lote',
                          Icons.format_list_numbered, _lotController),
                    ]),
                    const SizedBox(height: 32),
                    Center(
                      child: _buildSubmitButton(context),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 28),
          const SizedBox(width: 12),
          Text(title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              )),
        ],
      ),
    );
  }

  Widget _buildResponsiveGrid(List<Widget> children) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: children.map((child) => _buildGridItem(child)).toList(),
    );
  }

  Widget _buildGridItem(Widget child) {
    return SizedBox(
      width: 400,
      child: child,
    );
  }

  Widget _buildTextFieldWithIcon(
      String label, IconData icon, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        floatingLabelBehavior: FloatingLabelBehavior.never,
      ),
      validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
    );
  }

  Widget _buildNumberFieldWithIcon(
      String label, IconData icon, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        floatingLabelBehavior: FloatingLabelBehavior.never,
      ),
      validator: (value) {
        if (value!.isEmpty) return 'Campo requerido';
        if (double.tryParse(value) == null) return 'Valor numérico inválido';
        return null;
      },
    );
  }

  Widget _buildDateFieldWithIcon(
      String label, IconData icon, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () => _selectDate(context, controller),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        floatingLabelBehavior: FloatingLabelBehavior.never,
      ),
      validator: (value) => value!.isEmpty ? 'Seleccione fecha' : null,
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            blurRadius: 4,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text(
          'Actualizar Producto',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2101),
    );
    if (selectedDate != null) {
      controller.text = selectedDate.toLocal().toString().split(' ')[0];
    }
  }
}
