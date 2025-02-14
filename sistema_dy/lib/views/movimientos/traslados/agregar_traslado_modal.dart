import 'package:flutter/material.dart';
import 'traslados_model.dart';
import 'traslados_controller.dart';

class AgregarTrasladoModal extends StatefulWidget {
  final Function() onTrasladoAgregado;

  const AgregarTrasladoModal({required this.onTrasladoAgregado});

  @override
  _AgregarTrasladoModalState createState() => _AgregarTrasladoModalState();
}

class _AgregarTrasladoModalState extends State<AgregarTrasladoModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _codigoTrasladoController =
      TextEditingController();
  final TextEditingController _inventarioIdController = TextEditingController();
  final TextEditingController _origenIdController = TextEditingController();
  final TextEditingController _destinoIdController = TextEditingController();
  final TextEditingController _cantidadController = TextEditingController();
  final TextEditingController _empleadoIdController = TextEditingController();
  String? _estadoSeleccionado;

  final TrasladosController _trasladosController = TrasladosController();

  void _agregarTraslado() async {
    if (_formKey.currentState!.validate()) {
      final traslado = Traslado(
        id: 0, // El ID se genera automáticamente en la base de datos
        codigoTraslado: _codigoTrasladoController.text,
        inventarioId: int.parse(_inventarioIdController.text),
        origenId: int.parse(_origenIdController.text),
        destinoId: int.parse(_destinoIdController.text),
        cantidad: int.parse(_cantidadController.text),
        fechaTraslado: DateTime.now(),
        empleadoId: int.parse(_empleadoIdController.text),
        estado: _estadoSeleccionado ?? 'Pendiente',
      );

      await _trasladosController.agregarTraslado(traslado, context);
      widget.onTrasladoAgregado();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Agregar Traslado"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _codigoTrasladoController,
                decoration: InputDecoration(labelText: "Código de Traslado"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "El código de traslado es obligatorio";
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _inventarioIdController,
                decoration: InputDecoration(labelText: "ID de Inventario"),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "El ID de inventario es obligatorio";
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _origenIdController,
                decoration: InputDecoration(labelText: "ID de Sucursal Origen"),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "El ID de sucursal origen es obligatorio";
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _destinoIdController,
                decoration:
                    InputDecoration(labelText: "ID de Sucursal Destino"),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "El ID de sucursal destino es obligatorio";
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _cantidadController,
                decoration: InputDecoration(labelText: "Cantidad"),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "La cantidad es obligatoria";
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _empleadoIdController,
                decoration: InputDecoration(labelText: "ID de Empleado"),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "El ID de empleado es obligatorio";
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: "Estado"),
                value: _estadoSeleccionado,
                items: ['Pendiente', 'Completado', 'Cancelado'].map((estado) {
                  return DropdownMenuItem<String>(
                    value: estado,
                    child: Text(estado),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _estadoSeleccionado = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _agregarTraslado,
          child: Text("Guardar"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancelar"),
        ),
      ],
    );
  }
}
