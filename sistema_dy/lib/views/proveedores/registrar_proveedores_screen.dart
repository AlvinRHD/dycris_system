import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';
//comment
class RegistroProveedorScreen extends StatefulWidget {
  const RegistroProveedorScreen({super.key});

  @override
  _RegistroProveedorScreenState createState() =>
      _RegistroProveedorScreenState();
}

enum TipoPersona { Natural, Juridica }

class _RegistroProveedorScreenState extends State<RegistroProveedorScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _contactoController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _clasificacionController =
      TextEditingController();
  final TextEditingController _numeroFacturaController =
      TextEditingController();
  final TextEditingController _leyTributariaController =
      TextEditingController();

  TipoPersona? _selectedTipoPersona;

  Future<void> _registrarProveedor() async {
    if (_formKey.currentState?.validate() ?? false) {
      final nombre = _nombreController.text;
      final direccion = _direccionController.text;
      final contacto = _contactoController.text;
      final correo = _correoController.text;
      final tipoPersonaSeleccionada =
          _selectedTipoPersona == TipoPersona.Natural ? 'Natural' : 'Jurídica';
      final clasificacion = _clasificacionController.text;
      final numeroFactura = _numeroFacturaController.text;
      final leyTributaria = _leyTributariaController.text;

      final response = await http.post(
        Uri.parse('http://localhost:3000/api/proveedores'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nombre': nombre,
          'direccion': direccion,
          'contacto': contacto,
          'correo': correo,
          'clasificacion': clasificacion,
          'tipo_persona': tipoPersonaSeleccionada,
          'numero_factura_compra': numeroFactura,
          'ley_tributaria': leyTributaria,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proveedor registrado correctamente')),
        );

        Navigator.pop(context, true);
      } else {
        final errorData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${errorData['message']}')),
        );
      }
    }
  }

  void _regresarAHome() {
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _direccionController.dispose();
    _contactoController.dispose();
    _correoController.dispose();
    _clasificacionController.dispose();
    _numeroFacturaController.dispose();
    _leyTributariaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE3F2FD),
              Color(0xFFBBDEFB),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: <Widget>[
                            const Text(
                              "Registro de Proveedor",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3C3C3C),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Form(
                              key: _formKey,
                              child: Column(children: <Widget>[
                                _buildTextField(
                                  controller: _nombreController,
                                  label: 'Nombre del Proveedor',
                                  icon: Icons.business,
                                ),
                                _buildTextField(
                                  controller: _direccionController,
                                  label: 'Dirección',
                                  icon: Icons.location_on,
                                ),
                                _buildTextField(
                                  controller: _contactoController,
                                  label: 'Contacto',
                                  icon: Icons.phone,
                                  keyboardType: TextInputType.phone,
                                ),
                                _buildTextField(
                                  controller: _correoController,
                                  label: 'Correo Electrónico',
                                  icon: Icons.email,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                _buildTextField(
                                  controller: _clasificacionController,
                                  label: 'Clasificación',
                                  icon: Icons.category,
                                ),
                                _buildTextField(
                                  controller: _numeroFacturaController,
                                  label: 'Número de Factura',
                                  icon: Icons.receipt,
                                ),
                                _buildTextField(
                                  controller: _leyTributariaController,
                                  label: 'Ley Tributaria',
                                  icon: Icons.gavel,
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<TipoPersona>(
                                  value: _selectedTipoPersona,
                                  decoration: InputDecoration(
                                    labelText: 'Tipo de Persona',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    prefixIcon: const Icon(Icons.contact_mail),
                                  ),
                                  items: TipoPersona.values
                                      .map((TipoPersona tipo) {
                                    return DropdownMenuItem<TipoPersona>(
                                      value: tipo,
                                      child: Text(tipo
                                          .toString()
                                          .split('.')
                                          .last
                                          .toUpperCase()),
                                    );
                                  }).toList(),
                                  onChanged: (TipoPersona? newValue) {
                                    setState(() {
                                      _selectedTipoPersona = newValue;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Por favor seleccione un tipo de persona';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: _registrarProveedor,
                                      icon: const Icon(Icons.check),
                                      label: const Text('Registrar'),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: _regresarAHome,
                                      icon: const Icon(Icons.arrow_back),
                                      label: const Text('Regresar'),
                                    ),
                                  ],
                                ),
                              ]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          prefixIcon: Icon(icon),
        ),
        keyboardType: keyboardType,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor ingrese $label';
          }
          return null;
        },
      ),
    );
  }
}
