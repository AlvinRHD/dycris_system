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

      if (_estadoSeleccionado != widget.traslado['estado']) {
        datosActualizados['estado'] = _estadoSeleccionado;
      }

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

      if (datosActualizados.isNotEmpty) {
        try {
          await TrasladosApi()
              .updateTraslado(widget.traslado['id'], datosActualizados);
          _mostrarMensaje('Traslado actualizado correctamente');
          Navigator.pop(context, true);
        } catch (e) {
          _mostrarMensaje('Error al actualizar traslado: $e', esError: true);
        }
      } else {
        Navigator.pop(context);
      }
    }
  }

  void _mostrarMensaje(String mensaje, {bool esError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensaje,
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        backgroundColor: esError ? Colors.red[600] : Colors.green[600],
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Editar Traslado (${widget.traslado['codigo_traslado']})",
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.grey[50],
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: Icon(Icons.save, color: Colors.blue[600]),
            onPressed: _guardarCambios,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Código: ${widget.traslado['codigo_traslado'] ?? 'N/A'}",
                  style: TextStyle(fontSize: 14, color: Colors.black87)),
              SizedBox(height: 12),
              Text(
                  "Sucursal Origen: ${widget.traslado['sucursal_origen'] ?? widget.traslado['codigo_sucursal_origen'] ?? 'N/A'}",
                  style: TextStyle(fontSize: 14, color: Colors.black87)),
              SizedBox(height: 12),
              Text(
                  "Sucursal Destino: ${widget.traslado['sucursal_destino'] ?? widget.traslado['codigo_sucursal_destino'] ?? 'N/A'}",
                  style: TextStyle(fontSize: 14, color: Colors.black87)),
              SizedBox(height: 12),
              Text(
                  "Empleado: ${widget.traslado['empleado'] ?? widget.traslado['codigo_empleado'] ?? 'N/A'}",
                  style: TextStyle(fontSize: 14, color: Colors.black87)),
              SizedBox(height: 12),
              Text(
                "Fecha: ${widget.traslado['fecha_traslado'] != null ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(widget.traslado['fecha_traslado'])) : 'N/A'}",
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              SizedBox(height: 12),
              Text("Productos:",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              SizedBox(height: 10),
              ..._productos.map((producto) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            producto['producto_nombre'] ??
                                producto['codigo_inventario'] ??
                                'N/A',
                            style:
                                TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 2))
                              ],
                            ),
                            child: TextFormField(
                              controller: producto['cantidadController'],
                              decoration: InputDecoration(
                                labelText: 'Cantidad',
                                labelStyle: TextStyle(
                                    fontSize: 12, color: Colors.grey[600]),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                  fontSize: 14, color: Colors.black87),
                              validator: (value) {
                                if (value == null || value.isEmpty)
                                  return 'Ingrese una cantidad';
                                final cantidad = int.tryParse(value);
                                if (cantidad == null || cantidad <= 0)
                                  return 'Cantidad debe ser mayor a 0';
                                return null;
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
              SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2))
                  ],
                ),
                child: DropdownButtonFormField<String>(
                  value: _estadoSeleccionado,
                  decoration: InputDecoration(
                    labelText: 'Estado',
                    labelStyle:
                        TextStyle(fontSize: 12, color: Colors.grey[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: ['Pendiente', 'Completado', 'Cancelado']
                      .map((estado) => DropdownMenuItem(
                          value: estado,
                          child: Text(estado, style: TextStyle(fontSize: 14))))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _estadoSeleccionado = value!),
                  validator: (value) =>
                      value == null ? 'Seleccione un estado' : null,
                ),
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
