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
  final TextEditingController _porcentajeRetencionController =
      TextEditingController(text: '10.0');
  DateTime? _fechaFin;
  String _tipoCliente = 'Natural';

  void _agregarCliente() async {
    if (_formKey.currentState!.validate()) {
      final cliente = {
        'nombre': _nombreController.text,
        'direccion': _direccionController.text.isNotEmpty
            ? _direccionController.text
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
        'email': _emailController.text,
        'telefono': _telefonoController.text,
        'fecha_inicio': DateTime.now().toIso8601String().split('T')[0],
        'fecha_fin': _fechaFin != null
            ? DateFormat('yyyy-MM-dd').format(_fechaFin!)
            : null,
        'porcentaje_retencion': _tipoCliente == 'Sujeto Excluido' ? 10.0 : null,
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
      // Limpiar campos que no aplican al nuevo tipo
      if (_tipoCliente != 'Natural' && _tipoCliente != 'Consumidor Final') {
        _duiController.clear();
      }
      if (_tipoCliente != 'Consumidor Final') {
        _registroContribuyenteController.clear();
      }
      if (_tipoCliente != 'Contribuyente Jurídico') {
        _representanteLegalController.clear();
        _direccionRepresentanteController.clear();
      }
      if (_tipoCliente != 'ONG') {
        _razonSocialController.clear();
      }
      if (_tipoCliente != 'Sujeto Excluido') {
        _fechaFin = null;
        _porcentajeRetencionController.text = '';
      } else {
        _porcentajeRetencionController.text = '10.0';
      }
    });
  }

  Future<void> _seleccionarFechaFin() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (fecha != null) {
      setState(() {
        _fechaFin = fecha;
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
                  'Sujeto Excluido'
                ]
                    .map((tipo) =>
                        DropdownMenuItem(value: tipo, child: Text(tipo)))
                    .toList(),
                onChanged: _actualizarTipoCliente,
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                    labelText: "Nombre", border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? "Requerido" : null,
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: _direccionController,
                decoration: InputDecoration(
                    labelText: "Dirección", border: OutlineInputBorder()),
              ),
              SizedBox(height: 15),
              if (_tipoCliente == 'Natural' ||
                  _tipoCliente == 'Consumidor Final')
                TextFormField(
                  controller: _duiController,
                  decoration: InputDecoration(
                      labelText: "DUI", border: OutlineInputBorder()),
                  validator: (value) => (_tipoCliente == 'Natural' ||
                              _tipoCliente == 'Consumidor Final') &&
                          value!.isEmpty
                      ? "Requerido"
                      : null,
                ),
              SizedBox(height: 15),
              TextFormField(
                controller: _nitController,
                decoration: InputDecoration(
                    labelText: "NIT", border: OutlineInputBorder()),
                validator: (value) => (_tipoCliente != 'Natural' &&
                            _tipoCliente != 'Consumidor Final') &&
                        value!.isEmpty
                    ? "Requerido"
                    : null,
              ),
              SizedBox(height: 15),
              if (_tipoCliente == 'Consumidor Final')
                TextFormField(
                  controller: _registroContribuyenteController,
                  decoration: InputDecoration(
                      labelText: "Registro Contribuyente (NCR)",
                      border: OutlineInputBorder()),
                ),
              SizedBox(height: 15),
              if (_tipoCliente == 'Contribuyente Jurídico') ...[
                TextFormField(
                  controller: _representanteLegalController,
                  decoration: InputDecoration(
                      labelText: "Representante Legal",
                      border: OutlineInputBorder()),
                ),
                SizedBox(height: 15),
                TextFormField(
                  controller: _direccionRepresentanteController,
                  decoration: InputDecoration(
                      labelText: "Dirección del Representante",
                      border: OutlineInputBorder()),
                ),
              ],
              SizedBox(height: 15),
              if (_tipoCliente == 'ONG')
                TextFormField(
                  controller: _razonSocialController,
                  decoration: InputDecoration(
                      labelText: "Razón Social", border: OutlineInputBorder()),
                ),
              SizedBox(height: 15),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                    labelText: "Email", border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? "Requerido" : null,
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: _telefonoController,
                decoration: InputDecoration(
                    labelText: "Teléfono", border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? "Requerido" : null,
              ),
              SizedBox(height: 15),
              if (_tipoCliente == 'Sujeto Excluido') ...[
                InkWell(
                  onTap: _seleccionarFechaFin,
                  child: InputDecorator(
                    decoration: InputDecoration(
                        labelText: "Fecha Fin", border: OutlineInputBorder()),
                    child: Text(_fechaFin != null
                        ? DateFormat('dd/MM/yyyy').format(_fechaFin!)
                        : "Seleccionar Fecha"),
                  ),
                ),
                SizedBox(height: 15),
                TextFormField(
                  controller: _porcentajeRetencionController,
                  decoration: InputDecoration(
                      labelText: "Porcentaje de Retención",
                      border: OutlineInputBorder()),
                  readOnly: true,
                ),
              ],
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
