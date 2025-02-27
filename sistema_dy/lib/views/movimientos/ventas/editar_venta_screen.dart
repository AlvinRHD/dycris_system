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
  String? _tipoFactura;

  @override
  void initState() {
    super.initState();
    _notasController =
        TextEditingController(text: widget.venta['descripcion_compra'] ?? '');
    _metodoPago = widget.venta['metodo_pago'];
    _tipoFactura = widget.venta['tipo_factura'];
  }

  void _guardarCambios() async {
    if (_formKey.currentState!.validate()) {
      final datosActualizados = {
        'tipo_factura': _tipoFactura,
        'metodo_pago': _metodoPago,
        'descripcion_compra': _notasController.text,
      };
      try {
        await VentaApi()
            .updateVenta(widget.venta['idVentas'], datosActualizados);
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error al actualizar: $e')));
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
          IconButton(icon: Icon(Icons.save), onPressed: _guardarCambios),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Campos de solo lectura
              Text("Cliente: ${widget.venta['cliente_nombre'] ?? 'N/A'}"),
              SizedBox(height: 10),
              Text("Código: ${widget.venta['codigo_venta'] ?? 'N/A'}"),
              SizedBox(height: 10),
              Text("Empleado: ${widget.venta['empleado_nombre'] ?? 'N/A'}"),
              SizedBox(height: 10),
              Text("Total: \$${total.toStringAsFixed(2)}"),
              SizedBox(height: 10),
              Text("Descuento: ${descuento.toStringAsFixed(2)}%"),
              SizedBox(height: 20),
              // Campos editables
              DropdownButtonFormField<String>(
                value: _tipoFactura,
                decoration: InputDecoration(
                    labelText: 'Tipo de Factura', border: OutlineInputBorder()),
                items: ['Consumidor Final', 'Crédito Fiscal', 'Ticket']
                    .map((tipo) =>
                        DropdownMenuItem(value: tipo, child: Text(tipo)))
                    .toList(),
                onChanged: (value) => setState(() => _tipoFactura = value),
              ),
              SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: _metodoPago,
                decoration: InputDecoration(
                    labelText: 'Método de Pago', border: OutlineInputBorder()),
                items: [
                  'Efectivo',
                  'Tarjeta de Crédito',
                  'Transferencia Bancaria'
                ]
                    .map((metodo) =>
                        DropdownMenuItem(value: metodo, child: Text(metodo)))
                    .toList(),
                onChanged: (value) => setState(() => _metodoPago = value),
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: _notasController,
                decoration: InputDecoration(
                    labelText: 'Notas', border: OutlineInputBorder()),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
