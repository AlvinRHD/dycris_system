import 'package:flutter/material.dart';
import 'venta_api.dart';

class EditarVentaScreen extends StatefulWidget {
  final Map<String, dynamic> venta;

  const EditarVentaScreen({required this.venta});

  @override
  _EditarVentaScreenState createState() => _EditarVentaScreenState();
}

class _EditarVentaScreenState extends State<EditarVentaScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _notasController;
  String? _metodoPago;

  @override
  void initState() {
    super.initState();
    _notasController =
        TextEditingController(text: widget.venta['descripcion_compra'] ?? '');
    _metodoPago = widget.venta['metodo_pago'];
  }

  void _guardarCambios() async {
    if (_formKey.currentState!.validate()) {
      final datosActualizados = {
        'metodo_pago': _metodoPago,
        'descripcion_compra': _notasController.text,
      };
      try {
        await VentaApi()
            .updateVenta(widget.venta['idVentas'], datosActualizados);
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final total =
        double.tryParse(widget.venta['total']?.toString() ?? '0.0') ?? 0.0;
    final descuento =
        double.tryParse(widget.venta['descuento']?.toString() ?? '0.0') ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text("Editar Venta ${widget.venta['codigo_venta']}"),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _guardarCambios),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Cliente: ${widget.venta['cliente_nombre'] ?? 'N/A'}"),
              const SizedBox(height: 10),
              Text("Código: ${widget.venta['codigo_venta'] ?? 'N/A'}"),
              const SizedBox(height: 10),
              Text("Empleado: ${widget.venta['empleado_nombre'] ?? 'N/A'}"),
              const SizedBox(height: 10),
              Text("Total: \$${total.toStringAsFixed(2)}"),
              const SizedBox(height: 10),
              Text("Descuento: ${descuento.toStringAsFixed(2)}%"),
              const SizedBox(height: 10),
              Text("Tipo de DTE: ${widget.venta['tipo_dte'] ?? 'N/A'}"),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _metodoPago,
                decoration: const InputDecoration(
                  labelText: 'Método de Pago',
                  border: OutlineInputBorder(),
                ),
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
              const SizedBox(height: 15),
              TextFormField(
                controller: _notasController,
                decoration: const InputDecoration(
                  labelText: 'Notas (Motivo del cambio)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) => value == null || value.isEmpty
                    ? 'Ingrese el motivo del cambio'
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _notasController.dispose();
    super.dispose();
  }
}
