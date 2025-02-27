import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'traslados_api.dart';

class EditarTrasladoScreen extends StatefulWidget {
  final Map<String, dynamic> traslado;

  const EditarTrasladoScreen({required this.traslado});

  @override
  _EditarTrasladoScreenState createState() => _EditarTrasladoScreenState();
}

class _EditarTrasladoScreenState extends State<EditarTrasladoScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _estadoSeleccionado;
  late List<Map<String, dynamic>> _productos;

  @override
  void initState() {
    super.initState();
    _estadoSeleccionado = widget.traslado['estado'] ?? 'Pendiente';
    _productos = List.from(widget.traslado['productos'] ?? [])
        .map((p) => Map<String, dynamic>.from(p))
        .toList();
    for (var producto in _productos) {
      producto['cantidadController'] =
          TextEditingController(text: producto['cantidad']?.toString() ?? '');
    }
  }

  void _guardarCambios() async {
    if (_formKey.currentState!.validate()) {
      final Map<String, dynamic> datosActualizados = {};

      // Verificar cambio en estado
      if (_estadoSeleccionado != widget.traslado['estado']) {
        datosActualizados['estado'] = _estadoSeleccionado;
      }

      // Verificar cambios en cantidades
      final List<Map<String, dynamic>> productosActualizados =
          _productos.map((p) {
        final nuevaCantidad = int.parse(p['cantidadController'].text);
        return <String, dynamic>{
          'codigo_inventario': p['codigo_inventario'] as String,
          'cantidad': nuevaCantidad,
        };
      }).where((p) {
        final original = widget.traslado['productos'].firstWhere(
            (op) => op['codigo_inventario'] == p['codigo_inventario']);
        return p['cantidad'] != original['cantidad'];
      }).toList();

      if (productosActualizados.isNotEmpty) {
        datosActualizados['productos'] = productosActualizados;
      }

      // Enviar actualización solo si hay cambios
      if (datosActualizados.isNotEmpty) {
        try {
          await TrasladosApi()
              .updateTraslado(widget.traslado['id'], datosActualizados);
          Navigator.pop(context, true);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al actualizar traslado: $e')));
        }
      } else {
        Navigator.pop(context); // No hay cambios, solo cerrar
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Editar Traslado (${widget.traslado['codigo_traslado']})"),
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
              Text("Código: ${widget.traslado['codigo_traslado'] ?? 'N/A'}"),
              SizedBox(height: 15),
              Text(
                  "Sucursal Origen: ${widget.traslado['sucursal_origen'] ?? widget.traslado['codigo_sucursal_origen'] ?? 'N/A'}"),
              SizedBox(height: 15),
              Text(
                  "Sucursal Destino: ${widget.traslado['sucursal_destino'] ?? widget.traslado['codigo_sucursal_destino'] ?? 'N/A'}"),
              SizedBox(height: 15),
              Text(
                  "Empleado: ${widget.traslado['empleado'] ?? widget.traslado['codigo_empleado'] ?? 'N/A'}"), // Prioriza nombre completo
              SizedBox(height: 15),
              Text(
                  "Fecha: ${widget.traslado['fecha_traslado'] != null ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(widget.traslado['fecha_traslado'])) : 'N/A'}"),
              SizedBox(height: 15),
              Text("Productos:", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              ..._productos
                  .map((producto) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                producto['producto_nombre'] ??
                                    producto['codigo_inventario'] ??
                                    'N/A',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: producto['cantidadController'],
                                decoration: InputDecoration(
                                  labelText: 'Cantidad',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) => value!.isEmpty ||
                                        int.tryParse(value) == null
                                    ? "Ingrese un número válido"
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
              SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: _estadoSeleccionado,
                decoration: InputDecoration(
                    labelText: 'Estado', border: OutlineInputBorder()),
                items: ['Pendiente', 'Completado', 'Cancelado']
                    .map((estado) =>
                        DropdownMenuItem(value: estado, child: Text(estado)))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _estadoSeleccionado = value!),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var producto in _productos) {
      producto['cantidadController'].dispose();
    }
    super.dispose();
  }
}
