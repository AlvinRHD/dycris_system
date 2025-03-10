import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'clientes_api.dart';

class EditarClienteScreen extends StatefulWidget {
  final Map<String, dynamic> cliente;

  const EditarClienteScreen({required this.cliente});

  @override
  _EditarClienteScreenState createState() => _EditarClienteScreenState();
}

class _EditarClienteScreenState extends State<EditarClienteScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _direccionController;
  late TextEditingController _departamentoController;
  late TextEditingController _duiController;
  late TextEditingController _nitController;
  late TextEditingController _registroContribuyenteController;
  late TextEditingController _representanteLegalController;
  late TextEditingController _direccionRepresentanteController;
  late TextEditingController _razonSocialController;
  late TextEditingController _emailController;
  late TextEditingController _telefonoController;
  DateTime? _fechaInicio;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.cliente['nombre']);
    _direccionController =
        TextEditingController(text: widget.cliente['direccion']);
    _departamentoController =
        TextEditingController(text: widget.cliente['departamento'] ?? '');
    _duiController = TextEditingController(text: widget.cliente['dui']);
    _nitController = TextEditingController(text: widget.cliente['nit']);
    _registroContribuyenteController =
        TextEditingController(text: widget.cliente['registro_contribuyente']);
    _representanteLegalController =
        TextEditingController(text: widget.cliente['representante_legal']);
    _direccionRepresentanteController =
        TextEditingController(text: widget.cliente['direccion_representante']);
    _razonSocialController =
        TextEditingController(text: widget.cliente['razon_social']);
    _emailController = TextEditingController(text: widget.cliente['email']);
    _telefonoController =
        TextEditingController(text: widget.cliente['telefono']);
    _fechaInicio = widget.cliente['fecha_inicio'] != null
        ? DateTime.parse(widget.cliente['fecha_inicio'])
        : null;
  }

  String? _validarTelefono(String? value) {
    if (value == null || value.isEmpty) return null; // Opcional ahora
    final regex = RegExp(r'^(\+503\s?)?\d{4}-?\d{4}$');
    return regex.hasMatch(value)
        ? null
        : "Formato inválido (ej. 1234-5678 o +503 12345678)";
  }

  String? _validarEmail(String? value) {
    if (value == null || value.isEmpty) return null; // Opcional ahora
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(value)
        ? null
        : "Formato inválido (ej. example@domain.com)";
  }

  String? _validarDUI(String? value) {
    if (value == null || value.isEmpty) return null; // Opcional en edición
    final regex = RegExp(r'^\d{8}-\d$');
    if (!regex.hasMatch(value)) return "Formato inválido (ej. 12345678-9)";
    final digits = value.replaceAll('-', '');
    final base = digits.substring(0, 8).split('').map(int.parse).toList();
    final verificador = int.parse(digits[8]);
    final pesos = [9, 8, 7, 6, 5, 4, 3, 2];
    final suma = base
        .asMap()
        .entries
        .fold(0, (sum, entry) => sum + entry.value * pesos[entry.key]);
    final residuo = suma % 10;
    final esperado = residuo == 0 ? 0 : 10 - residuo;
    return verificador == esperado ? null : "Dígito verificador incorrecto";
  }

  String? _validarNIT(String? value) {
    if (value == null || value.isEmpty) return null; // Opcional ahora
    final nitRegex = RegExp(r'^\d{4}-\d{6}-\d{3}-\d$');
    if (!nitRegex.hasMatch(value))
      return "Formato inválido (ej. 0614-010190-123-4)";
    return null;
  }

  void _guardarCambios() async {
    if (_formKey.currentState!.validate()) {
      final datosActualizados = {
        'nombre': _nombreController.text,
        'direccion': _direccionController.text.isNotEmpty
            ? _direccionController.text
            : null,
        'departamento': _departamentoController.text.isNotEmpty
            ? _departamentoController.text
            : null,
        'dui': _duiController.text.isNotEmpty ? _duiController.text : null,
        'nit': _nitController.text.isNotEmpty ? _nitController.text : null,
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
        'email':
            _emailController.text.isNotEmpty ? _emailController.text : null,
        'telefono': _telefonoController.text.isNotEmpty
            ? _telefonoController.text
            : null,
        'fecha_inicio': _fechaInicio != null
            ? DateFormat('yyyy-MM-dd').format(_fechaInicio!)
            : null,
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

  Future<void> _seleccionarFecha(String tipo) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (fecha != null) {
      setState(() {
        _fechaInicio = fecha;
      });
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
              Text("Tipo: ${widget.cliente['tipo_cliente'] ?? 'N/A'}"),
              SizedBox(height: 15),
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                    labelText: 'Nombre', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? "Requerido" : null,
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: _direccionController,
                decoration: InputDecoration(
                    labelText: 'Dirección', border: OutlineInputBorder()),
                maxLength: 200,
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: _departamentoController,
                decoration: InputDecoration(
                    labelText: 'Departamento', border: OutlineInputBorder()),
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: _duiController,
                decoration: InputDecoration(
                    labelText: 'DUI', border: OutlineInputBorder()),
                validator: _validarDUI,
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: _nitController,
                decoration: InputDecoration(
                    labelText: 'NIT', border: OutlineInputBorder()),
                validator: _validarNIT,
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: _registroContribuyenteController,
                decoration: InputDecoration(
                    labelText: 'Registro Contribuyente (NCR)',
                    border: OutlineInputBorder()),
              ),
              SizedBox(height: 15),
              if (widget.cliente['tipo_cliente'] ==
                  'Contribuyente Jurídico') ...[
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
              if (widget.cliente['tipo_cliente'] == 'ONG')
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
                validator: _validarEmail,
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: _telefonoController,
                decoration: InputDecoration(
                    labelText: 'Teléfono', border: OutlineInputBorder()),
                validator: _validarTelefono,
              ),
              SizedBox(height: 15),
              InkWell(
                onTap: () => _seleccionarFecha('inicio'),
                child: InputDecorator(
                  decoration: InputDecoration(
                      labelText: "Fecha Inicio", border: OutlineInputBorder()),
                  child: Text(_fechaInicio != null
                      ? DateFormat('dd/MM/yyyy').format(_fechaInicio!)
                      : "Seleccionar Fecha"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
