import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'clientes_api.dart';

class AgregarClienteScreen extends StatefulWidget {
  @override
  _AgregarClienteScreenState createState() => _AgregarClienteScreenState();
}

class _AgregarClienteScreenState extends State<AgregarClienteScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _departamentoController = TextEditingController();
  final TextEditingController _duiController = TextEditingController();
  final TextEditingController _nitController = TextEditingController();
  final TextEditingController _registroContribuyenteController =
      TextEditingController();
  final TextEditingController _representanteLegalController =
      TextEditingController();
  final TextEditingController _direccionRepresentanteController =
      TextEditingController();
  final TextEditingController _razonSocialController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();

  DateTime? _fechaInicio = DateTime.now();

  String _tipoCliente = 'Cliente de Paso';

  String? _validarDUI(String? value) {
    if (value == null || value.isEmpty) return "Requerido";
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

  void _formatearDUI(String value) {
    if (value.length == 8 && !value.contains('-')) {
      _duiController.text = '$value-';
      _duiController.selection = TextSelection.fromPosition(
          TextPosition(offset: _duiController.text.length));
    }
  }

  String? _validarNIT(String? value) {
    if (value == null || value.isEmpty) return "Requerido";
    final nitRegex = RegExp(r'^\d{4}-\d{6}-\d{3}-\d$');
    if (!nitRegex.hasMatch(value))
      return "Formato inválido (ej. 0614-010190-123-4)";
    return null;
  }

  void _formatearNIT(String value) {
    if (value.replaceAll('-', '').length == 4 && value.split('-').length == 1) {
      _nitController.text = '$value-';
    } else if (value.replaceAll('-', '').length == 10 &&
        value.split('-').length == 2) {
      _nitController.text = '$value-';
    } else if (value.replaceAll('-', '').length == 13 &&
        value.split('-').length == 3) {
      _nitController.text = '$value-';
    }
    _nitController.selection = TextSelection.fromPosition(
        TextPosition(offset: _nitController.text.length));
  }

  String? _validarTelefono(String? value) {
    if (value == null || value.isEmpty) return "Requerido";
    final regex = RegExp(r'^\d{4}-\d{4}$');
    return regex.hasMatch(value) ? null : "Formato inválido (ej. 1234-5678)";
  }

  void _formatearTelefono(String value) {
    if (value.length == 4 && !value.contains('-')) {
      _telefonoController.text = '$value-';
      _telefonoController.selection = TextSelection.fromPosition(
          TextPosition(offset: _telefonoController.text.length));
    }
  }

  String? _validarEmail(String? value) {
    if (value == null || value.isEmpty) return "Requerido";
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(value)
        ? null
        : "Formato inválido (ej. example@domain.com)";
  }

  void _agregarCliente() async {
    if (_formKey.currentState!.validate()) {
      final cliente = {
        'nombre': _nombreController.text,
        'direccion': _direccionController.text.isNotEmpty
            ? _direccionController.text
            : null,
        'departamento': _departamentoController.text.isNotEmpty
            ? _departamentoController.text
            : null,
        'dui': _duiController.text.isNotEmpty ? _duiController.text : null,
        'nit': _nitController.text.isNotEmpty ? _nitController.text : null,
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
        'email':
            _emailController.text.isNotEmpty ? _emailController.text : null,
        'telefono': _telefonoController.text.isNotEmpty
            ? _telefonoController.text
            : null,
        'fecha_inicio': DateFormat('yyyy-MM-dd').format(_fechaInicio!),
      };
      try {
        await ClientesApi().addCliente(cliente);
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al agregar cliente: $e')));
      }
    }
  }

  void _actualizarTipoCliente(String? nuevoTipo) {
    setState(() {
      _tipoCliente = nuevoTipo!;
      if (_tipoCliente != 'Natural' && _tipoCliente != 'Consumidor Final') {
        _duiController.clear();
      }
      if (_tipoCliente != 'Contribuyente Jurídico') {
        _representanteLegalController.clear();
        _direccionRepresentanteController.clear();
      }
      if (_tipoCliente != 'ONG') {
        _razonSocialController.clear();
      }
    });
  }

  Future<void> _seleccionarFecha() async {
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
      appBar: AppBar(title: Text("Agregar Cliente")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _tipoCliente,
                decoration: InputDecoration(
                    labelText: "Tipo de Cliente", border: OutlineInputBorder()),
                items: [
                  'Consumidor Final',
                  'Contribuyente Jurídico',
                  'Natural',
                  'ONG',
                  'Cliente de Paso'
                ]
                    .map((tipo) =>
                        DropdownMenuItem(value: tipo, child: Text(tipo)))
                    .toList(),
                onChanged: _actualizarTipoCliente,
                validator: (value) => value == null ? "Requerido" : null,
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                    labelText: "Nombre", border: OutlineInputBorder()),
                validator: (value) =>
                    value!.isEmpty || !RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)
                        ? "Requerido, solo letras"
                        : null,
                maxLength: 100,
              ),
              if (_tipoCliente != 'Cliente de Paso') ...[
                SizedBox(height: 15),
                TextFormField(
                  controller: _direccionController,
                  decoration: InputDecoration(
                      labelText: "Dirección", border: OutlineInputBorder()),
                  validator: (value) =>
                      value == null || value.isEmpty ? "Requerido" : null,
                  maxLength: 200,
                ),
                SizedBox(height: 15),
                TextFormField(
                  controller: _departamentoController,
                  decoration: InputDecoration(
                      labelText: "Departamento", border: OutlineInputBorder()),
                  validator: (value) =>
                      value == null || value.isEmpty ? "Requerido" : null,
                ),
                SizedBox(height: 15),
                if (_tipoCliente == 'Natural' ||
                    _tipoCliente == 'Consumidor Final')
                  TextFormField(
                    controller: _duiController,
                    decoration: InputDecoration(
                        labelText: "DUI", border: OutlineInputBorder()),
                    validator: _validarDUI,
                    onChanged: _formatearDUI,
                  ),
                SizedBox(height: 15),
                TextFormField(
                  controller: _nitController,
                  decoration: InputDecoration(
                      labelText: "NIT", border: OutlineInputBorder()),
                  validator: _validarNIT,
                  onChanged: _formatearNIT,
                ),
                SizedBox(height: 15),
                TextFormField(
                  controller: _registroContribuyenteController,
                  decoration: InputDecoration(
                      labelText: "Registro Contribuyente (NCR)",
                      border: OutlineInputBorder()),
                  validator: (value) =>
                      value == null || value.isEmpty ? "Requerido" : null,
                ),
                if (_tipoCliente == 'Contribuyente Jurídico') ...[
                  SizedBox(height: 15),
                  TextFormField(
                    controller: _representanteLegalController,
                    decoration: InputDecoration(
                        labelText: "Representante Legal",
                        border: OutlineInputBorder()),
                    validator: (value) =>
                        value == null || value.isEmpty ? "Requerido" : null,
                  ),
                  SizedBox(height: 15),
                  TextFormField(
                    controller: _direccionRepresentanteController,
                    decoration: InputDecoration(
                        labelText: "Dirección del Representante",
                        border: OutlineInputBorder()),
                    validator: (value) =>
                        value == null || value.isEmpty ? "Requerido" : null,
                  ),
                ],
                if (_tipoCliente == 'ONG') SizedBox(height: 15),
                TextFormField(
                  controller: _razonSocialController,
                  decoration: InputDecoration(
                      labelText: "Razón Social", border: OutlineInputBorder()),
                  validator: (value) =>
                      value == null || value.isEmpty ? "Requerido" : null,
                ),
                SizedBox(height: 15),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                      labelText: "Email", border: OutlineInputBorder()),
                  validator: _validarEmail,
                ),
                SizedBox(height: 15),
                TextFormField(
                  controller: _telefonoController,
                  decoration: InputDecoration(
                      labelText: "Teléfono", border: OutlineInputBorder()),
                  validator: _validarTelefono,
                  onChanged: _formatearTelefono,
                ),
              ],
              SizedBox(height: 15),
              InkWell(
                onTap: () => _seleccionarFecha,
                child: InputDecorator(
                  decoration: InputDecoration(
                      labelText: "Fecha Inicio", border: OutlineInputBorder()),
                  child: Text(_fechaInicio != null
                      ? DateFormat('dd/MM/yyyy').format(_fechaInicio!)
                      : "Seleccionar Fecha"),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                  onPressed: _agregarCliente, child: Text("Guardar Cliente")),
            ],
          ),
        ),
      ),
    );
  }
}
