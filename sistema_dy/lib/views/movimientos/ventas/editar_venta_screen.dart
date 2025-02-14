import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'clientes/clientes_model.dart';
import 'ventas_controller.dart';

class EditarVentaScreen extends StatefulWidget {
  final Map<String, dynamic> venta;

  const EditarVentaScreen({Key? key, required this.venta}) : super(key: key);

  @override
  _EditarVentaScreenState createState() => _EditarVentaScreenState();
}

class _EditarVentaScreenState extends State<EditarVentaScreen> {
  final VentasController _ventasController = VentasController();
  final _formKey = GlobalKey<FormState>();

  // Controladores editables
  late TextEditingController _direccionController;
  late TextEditingController _notasController;
  String? _metodoPago;
  String? _tipoFactura;

  @override
  void initState() {
    super.initState();
    _direccionController = TextEditingController(
        text: widget.venta['direccion_cliente'] ?? 'Sin dirección');
    _notasController =
        TextEditingController(text: widget.venta['descripcion_compra'] ?? '');
    _metodoPago = widget.venta['metodo_pago'] ?? 'Efectivo';
    _tipoFactura = widget.venta['tipo_factura'] ?? 'Consumidor Final';
  }

  void _guardarCambios() async {
    if (_formKey.currentState!.validate()) {
      final datosActualizados = {
        "direccion_cliente": _direccionController.text,
        "descripcion_compra": _notasController.text,
        "metodo_pago": _metodoPago,
        "tipo_factura": _tipoFactura,
      };

      try {
        await _ventasController.actualizarVenta(
            widget.venta['idVentas'], datosActualizados);

        Navigator.pop(context, true); // Retornar éxito
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Editar Venta #${widget.venta['idVentas']}"),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _guardarCambios,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Sección Cliente (solo lectura)
              _buildReadOnlySection(
                title: 'Datos del Cliente',
                items: {
                  'Nombre': widget.venta['cliente_nombre'],
                  'DUI': widget.venta['dui'] ?? 'N/A',
                  'NIT': widget.venta['nit'] ?? 'N/A',
                },
              ),

              // Dirección (editable)
              TextFormField(
                controller: _direccionController,
                decoration: InputDecoration(
                  labelText: 'Dirección del Cliente',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              SizedBox(height: 20),

              // Selectores
              DropdownButtonFormField<String>(
                value: _tipoFactura,
                decoration: InputDecoration(
                  labelText: 'Tipo de Factura',
                  border: OutlineInputBorder(),
                ),
                items: ['Consumidor Final', 'Crédito Fiscal', 'Ticket']
                    .map((tipo) => DropdownMenuItem(
                          value: tipo,
                          child: Text(tipo),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _tipoFactura = value),
              ),
              SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: _metodoPago,
                decoration: InputDecoration(
                  labelText: 'Método de Pago',
                  border: OutlineInputBorder(),
                ),
                items: ['Efectivo', 'Tarjeta', 'Transferencia']
                    .map((metodo) => DropdownMenuItem(
                          value: metodo,
                          child: Text(metodo),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _metodoPago = value),
              ),
              SizedBox(height: 20),

              // Notas
              TextFormField(
                controller: _notasController,
                decoration: InputDecoration(
                  labelText: 'Notas Adicionales',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlySection(
      {required String title, required Map<String, dynamic> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        ...items.entries.map((entry) => Padding(
              padding: EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Text('${entry.key}: ',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(width: 10),
                  Text(entry.value ?? 'N/A',
                      style: TextStyle(color: Colors.grey[700])),
                ],
              ),
            )),
        Divider(thickness: 2),
      ],
    );
  }
}
