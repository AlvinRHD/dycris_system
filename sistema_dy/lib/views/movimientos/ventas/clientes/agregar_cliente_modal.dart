import 'package:flutter/material.dart';
import 'clientes_controller.dart';

class AgregarClienteModal extends StatefulWidget {
  final Function() onClienteAgregado;

  const AgregarClienteModal({required this.onClienteAgregado});

  @override
  _AgregarClienteModalState createState() => _AgregarClienteModalState();
}

class _AgregarClienteModalState extends State<AgregarClienteModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _duiController = TextEditingController();
  final TextEditingController _nitController = TextEditingController();

  final ClientesController _clientesController = ClientesController();

  void _agregarCliente() async {
    if (_formKey.currentState!.validate()) {
      await _clientesController.agregarCliente(
        nombre: _nombreController.text,
        direccion: _direccionController.text,
        dui: _duiController.text,
        nit: _nitController.text,
        context: context,
      );

      // Cerrar el modal y notificar que se agregó un cliente
      widget.onClienteAgregado();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Agregar Cliente"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(labelText: "Nombre"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "El nombre es obligatorio";
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _direccionController,
                decoration: InputDecoration(labelText: "Dirección"),
              ),
              TextFormField(
                controller: _duiController,
                decoration: InputDecoration(labelText: "DUI"),
              ),
              TextFormField(
                controller: _nitController,
                decoration: InputDecoration(labelText: "NIT"),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _agregarCliente,
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
