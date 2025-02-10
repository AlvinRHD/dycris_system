import 'package:flutter/material.dart';

import 'inventory_controller.dart';
import 'inventory_screen.dart';
import 'product_model.dart';

class ProductFormApp extends StatelessWidget {
  const ProductFormApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestión de Productos',
      theme: _buildAppTheme(),
      home: const ProductFormScreen(),
    );
  }

  ThemeData _buildAppTheme() {
    return ThemeData(
      primaryColor: const Color(0xFF2A2D3E),
      colorScheme: const ColorScheme.light(
        secondary: Color(0xFF4ECCA3),
        surface: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: const Color(0xFF4ECCA3),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ProductFormScreenState createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
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

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final newProduct = Product(
        id: 0,
        codigo: _codeController.text,
        nombre: _nameController.text,
        descripcion: _descriptionController.text,
        nro_motor: _motorController.text,
        nro_chasis: _chasisController.text,
        categoria: _categoryController.text,
        sucursal: _branchController.text,
        precioCompra: _purchasePriceController.text.isNotEmpty
            ? double.parse(_purchasePriceController.text)
            : 0.0,
        credito: _creditController.text.isNotEmpty
            ? double.tryParse(_creditController.text) ?? 0.0
            : 0.0,
        precioVenta: _salePriceController.text.isNotEmpty
            ? double.parse(_salePriceController.text)
            : 0.0,
        stockExistencia: _stockController.text.isNotEmpty
            ? int.parse(_stockController.text)
            : 0,
        stockMinimo: _minStockController.text.isNotEmpty
            ? int.parse(_minStockController.text)
            : 0,
        fechaIngreso: _entryDateController.text.isNotEmpty
            ? DateTime.parse(_entryDateController.text)
            : DateTime.now(),
        fechaReingreso: _reentryDateController.text.isNotEmpty
            ? DateTime.parse(_reentryDateController.text)
            : DateTime.now(),
        nroPoliza: _policyController.text,
        nroLote: _lotController.text,
      );

      try {
        await _inventoryController.addProduct(newProduct);
        _showSuccessMessage();
        await Future.delayed(const Duration(seconds: 1));
        // Navega a InventoryScreen reemplazando la pantalla actual
        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(builder: (context) => const InventoryScreen()),
        );
      } catch (e) {
        _showErrorMessage();
      }
    }
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Producto guardado con éxito'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showErrorMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Error al guardar el producto'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Información Básica', Icons.shopping_bag),
              _buildResponsiveGrid([
                _buildTextFieldWithIcon(
                    'Código del producto', Icons.qr_code, _codeController),
                _buildTextFieldWithIcon(
                    'Nombre del producto', Icons.text_fields, _nameController),
                _buildTextFieldWithIcon(
                    'Descripción', Icons.description, _descriptionController),
                _buildTextFieldWithIcon(
                    'Categoría', Icons.category, _categoryController),
                _buildTextFieldWithIcon(
                    'Sucursal', Icons.store, _branchController),
              ]),
              _buildSectionHeader('Detalles del Producto', Icons.settings),
              _buildResponsiveGrid([
                _buildTextFieldWithIcon(
                    'N° Motor', Icons.directions_car, _motorController),
                _buildTextFieldWithIcon(
                    'N° Chasis', Icons.car_repair, _chasisController),
                _buildNumberFieldWithIcon('Precio de Compra',
                    Icons.monetization_on, _purchasePriceController),
                _buildTextFieldWithIcon(
                    'Crédito', Icons.credit_card, _creditController),
                _buildNumberFieldWithIcon('Precio de Venta', Icons.attach_money,
                    _salePriceController),
              ]),
              _buildSectionHeader('Gestión de Inventario', Icons.inventory),
              _buildResponsiveGrid([
                _buildNumberFieldWithIcon(
                    'Stock Existente', Icons.warehouse, _stockController),
                _buildNumberFieldWithIcon(
                    'Stock Mínimo', Icons.warning, _minStockController),
                _buildDateFieldWithIcon('Fecha de Ingreso',
                    Icons.calendar_today, _entryDateController),
                _buildDateFieldWithIcon('Fecha de Reingreso',
                    Icons.event_repeat, _reentryDateController),
              ]),
              _buildSectionHeader('Identificadores', Icons.fingerprint),
              _buildResponsiveGrid([
                _buildTextFieldWithIcon(
                    'N° de Póliza', Icons.assignment, _policyController),
                _buildTextFieldWithIcon(
                    'N° Lote', Icons.format_list_numbered, _lotController),
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

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Registro de Productos',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          )),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Theme.of(context).primaryColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(20),
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
            // ignore: deprecated_member_use
            color: Theme.of(context).primaryColor.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.save_alt, size: 24),
        label: const Text('Guardar Producto'),
        onPressed: _submitForm,
      ),
    );
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.text = "${picked.toLocal()}".split(' ')[0];
    }
  }
}
