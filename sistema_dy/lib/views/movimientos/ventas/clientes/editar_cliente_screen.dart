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
  late TextEditingController _registroContribuyenteController;
  late TextEditingController _representanteLegalController;
  late TextEditingController _direccionRepresentanteController;
  late TextEditingController _razonSocialController;
  late TextEditingController _emailController;
  late TextEditingController _telefonoController;
  late String _tipoCliente;

  @override
  void initState() {
    super.initState();
    _direccionController =
        TextEditingController(text: widget.cliente['direccion'] ?? '');
    _registroContribuyenteController = TextEditingController(
        text: widget.cliente['registro_contribuyente'] ?? '');
    _representanteLegalController = TextEditingController(
        text: widget.cliente['representante_legal'] ?? '');
    _direccionRepresentanteController = TextEditingController(
        text: widget.cliente['direccion_representante'] ?? '');
    _razonSocialController =
        TextEditingController(text: widget.cliente['razon_social'] ?? '');
    _emailController = TextEditingController(text: widget.cliente['email']);
    _telefonoController =
        TextEditingController(text: widget.cliente['telefono']);
    _tipoCliente = widget.cliente['tipo_cliente'];
  }

  void _guardarCambios() async {
    if (_formKey.currentState!.validate()) {
      final datosActualizados = {
        'direccion': _direccionController.text.isNotEmpty
            ? _direccionController.text
            : null,
        'tipo_cliente': _tipoCliente,
        'registro_contribuyente':
            _registroContribuyenteController.text.isNotEmpty
                ? _registroContribuyenteController.text
                : null,
        'representante_legal': _representanteLegalController.text.isNotEmpty
            ? _representanteLegalController.text
            : null,
        'direccion_representante':
            _direccionRepresentanteController.text.isNotEmpty
                ? _direccionRepresentanteController.text
                : null,
        'razon_social': _razonSocialController.text.isNotEmpty
            ? _razonSocialController.text
            : null,
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
              Text("DUI: ${widget.cliente['dui'] ?? 'N/A'}"),
              SizedBox(height: 15),
              Text("NIT: ${widget.cliente['nit'] ?? 'N/A'}"),
              SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: _tipoCliente,
                decoration: InputDecoration(
                    labelText: 'Tipo de Cliente', border: OutlineInputBorder()),
                items: [
                  'Consumidor Final',
                  'Contribuyente Jurídico',
                  'Natural',
                  'ONG',
                  'Sujeto Excluido'
                ]
                    .map((tipo) =>
                        DropdownMenuItem(value: tipo, child: Text(tipo)))
                    .toList(),
                onChanged: (value) => setState(() => _tipoCliente = value!),
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: _direccionController,
                decoration: InputDecoration(
                    labelText: 'Dirección', border: OutlineInputBorder()),
              ),
              SizedBox(height: 15),
              if (_tipoCliente == "Consumidor Final")
                TextFormField(
                  controller: _registroContribuyenteController,
                  decoration: InputDecoration(
                      labelText: 'Registro Contribuyente (NCR)',
                      border: OutlineInputBorder()),
                ),
              SizedBox(height: 15),
              if (_tipoCliente == "Contribuyente Jurídico") ...[
                TextFormField(
                  controller: _representanteLegalController,
                  decoration: InputDecoration(
                      labelText: 'Representante Legal',
                      border: OutlineInputBorder()),
                ),
                SizedBox(height: 15),
                TextFormField(
                  controller: _direccionRepresentanteController,
                  decoration: InputDecoration(
                      labelText: 'Dirección del Representante',
                      border: OutlineInputBorder()),
                ),
              ],
              SizedBox(height: 15),
              if (_tipoCliente == "ONG")
                TextFormField(
                  controller: _razonSocialController,
                  decoration: InputDecoration(
                      labelText: 'Razón Social', border: OutlineInputBorder()),
                ),
              SizedBox(height: 15),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                    labelText: 'Email', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? "Requerido" : null,
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: _telefonoController,
                decoration: InputDecoration(
                    labelText: 'Teléfono', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? "Requerido" : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
