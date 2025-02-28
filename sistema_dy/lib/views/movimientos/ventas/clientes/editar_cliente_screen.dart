import 'package:flutter/material.dart';
import 'clientes_api.dart';

class EditarClienteScreen extends StatefulWidget {
  final Map<String, dynamic> cliente;

  const EditarClienteScreen({required this.cliente});

  @override
  _EditarClienteScreenState createState() => _EditarClienteScreenState();
}

class _EditarClienteScreenState extends State<EditarClienteScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _direccionController;
  late TextEditingController _emailController;
  late TextEditingController _telefonoController;

  @override
  void initState() {
    super.initState();
    _direccionController =
        TextEditingController(text: widget.cliente['direccion'] ?? '');
    _emailController = TextEditingController(text: widget.cliente['email']);
    _telefonoController =
        TextEditingController(text: widget.cliente['telefono']);
  }

  String? _validarTelefono(String? value) {
    if (value == null || value.isEmpty) return "Requerido";
    final regex = RegExp(r'^(\+503\s?)?\d{4}-?\d{4}$');
    return regex.hasMatch(value)
        ? null
        : "Formato inválido (ej. 1234-5678 o +503 12345678)";
  }

  String? _validarEmail(String? value) {
    if (value == null || value.isEmpty) return "Requerido";
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(value)
        ? null
        : "Formato inválido (ej. example@domain.com)";
  }

  void _guardarCambios() async {
    if (_formKey.currentState!.validate()) {
      final datosActualizados = {
        'direccion': _direccionController.text,
        'email': _emailController.text,
        'telefono': _telefonoController.text,
      };
      try {
        await ClientesApi()
            .updateCliente(widget.cliente['idCliente'], datosActualizados);
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al actualizar cliente: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Editar Cliente (${widget.cliente['nombre']})"),
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
              Text("Código: ${widget.cliente['codigo_cliente'] ?? 'N/A'}"),
              SizedBox(height: 15),
              Text("Nombre: ${widget.cliente['nombre'] ?? 'N/A'}"),
              SizedBox(height: 15),
              Text("Tipo: ${widget.cliente['tipo_cliente'] ?? 'N/A'}"),
              SizedBox(height: 15),
              TextFormField(
                controller: _direccionController,
                decoration: InputDecoration(
                    labelText: 'Dirección', border: OutlineInputBorder()),
                maxLength: 200,
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                    labelText: 'Email', border: OutlineInputBorder()),
                validator: _validarEmail,
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: _telefonoController,
                decoration: InputDecoration(
                    labelText: 'Teléfono', border: OutlineInputBorder()),
                validator: _validarTelefono,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
