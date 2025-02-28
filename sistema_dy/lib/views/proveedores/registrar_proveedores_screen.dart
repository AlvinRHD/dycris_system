import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';

class RegistroProveedorScreen extends StatefulWidget {
  const RegistroProveedorScreen({super.key});

  @override
  _RegistroProveedorScreenState createState() =>
      _RegistroProveedorScreenState();
}

class _RegistroProveedorScreenState extends State<RegistroProveedorScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();

  final TextEditingController _propietarioController = TextEditingController();
  final TextEditingController _duiController = TextEditingController();

  final TextEditingController _razonSocialController = TextEditingController();
  final TextEditingController _nitController = TextEditingController();
  final TextEditingController _nrcController = TextEditingController();
  final TextEditingController _giroController = TextEditingController();
  final TextEditingController _correspondenciaController =
      TextEditingController();

  String _tipoProveedor = 'natural';

  List<TextInputFormatter> duiInputFormatters() {
    return [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(9), // Limita la longitud a 9 caracteres
      TextInputFormatter.withFunction((oldValue, newValue) {
        String newText = newValue.text;
        if (newText.length > 8) {
          // Si el texto tiene más de 8 caracteres, agregar un guion en la posición 8
          newText = newText.substring(0, 8) + '-' + newText.substring(8);
        }
        return TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        );
      }),
    ];
  }

  List<TextInputFormatter> nitInputFormatters() {
    return [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(14),
      TextInputFormatter.withFunction((oldValue, newValue) {
        String newText = newValue.text;
        if (newText.length > 4) {
          newText = newText.substring(0, 4) + '-' + newText.substring(4);
        }

        if (newText.length > 11) {
          newText = newText.substring(0, 11) + '-' + newText.substring(11);
        }

        if (newText.length > 15) {
          newText = newText.substring(0, 15) + '-' + newText.substring(15);
        }

        return TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        );
      }),
    ];
  }

  Future<void> _registrarProveedor() async {
    if (_formKey.currentState?.validate() ?? false) {
      final Map<String, dynamic> requestBody = {
        'nombre_comercial': _nombreController.text,
        'correo': _correoController.text,
        'direccion': _direccionController.text,
        'telefono': _telefonoController.text,
        'tipo_proveedor': _tipoProveedor,
      };

      if (_tipoProveedor == 'natural') {
        requestBody.addAll({
          'nombre_propietario': _propietarioController.text,
          'dui': _duiController.text,
        });
      } else if (_tipoProveedor == 'juridico') {
        requestBody.addAll({
          'razon_social': _razonSocialController.text,
          'nit': _nitController.text,
          'nrc': _nrcController.text,
          'giro': _giroController.text,
          'correspondencia': _correspondenciaController.text,
        });
      }

      final response = await http.post(
        Uri.parse('http://localhost:3000/api/proveedores'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
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
    _correoController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _propietarioController.dispose();
    _duiController.dispose();
    _razonSocialController.dispose();
    _nitController.dispose();
    _nrcController.dispose();
    _giroController.dispose();
    _correspondenciaController.dispose();
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
            colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
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
                    constraints: const BoxConstraints(
                        maxWidth: 600), // Aumenta el ancho total
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
                                _buildDropdown(),
                                Wrap(
                                  spacing: 20,
                                  runSpacing: 20,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildTextField(
                                            controller: _nombreController,
                                            label: 'Nombre comercial',
                                            icon: Icons.store,
                                          ),
                                        ),
                                        SizedBox(width: 20),
                                        Expanded(
                                          child: _buildTextField(
                                            controller: _correoController,
                                            label: 'Correo Electrónico',
                                            icon: Icons.email,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildTextField(
                                            controller: _direccionController,
                                            label: 'Dirección',
                                            icon: Icons.location_on,
                                          ),
                                        ),
                                        SizedBox(width: 20),
                                        Expanded(
                                          child: _buildTextField(
                                            controller: _telefonoController,
                                            label: 'Teléfono',
                                            icon: Icons.call,
                                            keyboardType: TextInputType.phone,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_tipoProveedor == 'natural') ...[
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildTextField(
                                              controller:
                                                  _propietarioController,
                                              label: 'Nombre del propietario',
                                              icon: Icons.person,
                                            ),
                                          ),
                                          SizedBox(width: 20),
                                          Expanded(
                                            child: _buildTextField(
                                              controller: _duiController,
                                              label: 'DUI',
                                              icon: Icons.badge,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (_tipoProveedor == 'juridico') ...[
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildTextField(
                                              controller:
                                                  _razonSocialController,
                                              label: 'Razón social',
                                              icon: Icons.apartment,
                                            ),
                                          ),
                                          SizedBox(width: 20),
                                          Expanded(
                                            child: _buildTextField(
                                              controller: _nitController,
                                              label: 'NIT',
                                              icon: Icons.confirmation_number,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildTextField(
                                              controller: _nrcController,
                                              label: 'NRC',
                                              icon: Icons.receipt_long,
                                            ),
                                          ),
                                          SizedBox(width: 20),
                                          Expanded(
                                            child: _buildTextField(
                                              controller: _giroController,
                                              label: 'Giro',
                                              icon: Icons.business,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildTextField(
                                              controller:
                                                  _correspondenciaController,
                                              label: 'Correspondencia',
                                              icon: Icons.markunread_mailbox,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
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

  Widget _buildDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        value: _tipoProveedor,
        decoration: InputDecoration(
          labelText: 'Tipo de proveedor',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          prefixIcon: const Icon(Icons.category),
        ),
        items: const [
          DropdownMenuItem(value: 'natural', child: Text('Natural')),
          DropdownMenuItem(value: 'juridico', child: Text('Jurídico')),
        ],
        onChanged: (value) {
          setState(() {
            _tipoProveedor = value!;
          });
        },
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
        inputFormatters: label == 'DUI'
            ? duiInputFormatters()
            : (label == 'NIT'
                ? nitInputFormatters()
                : (label == 'Teléfono'
                    ? [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(8)
                      ]
                    : label == 'NRC'
                        ? [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[A-Za-z0-9]')),
                            LengthLimitingTextInputFormatter(11),
                          ]
                        : [])),
        validator: (value) {
          if (value == null || value.isEmpty) {
            if (label == 'Correspondencia') {
              return null;
            }
            return 'Por favor ingrese $label';
          }
          if (label == 'Teléfono' &&
              !RegExp(r'^\d{8}$').hasMatch(value ?? '')) {
            return 'El teléfono es invalido.';
          }
          if (label == 'DUI' && !RegExp(r'^\d{8}-\d$').hasMatch(value ?? '')) {
            return 'El DUI debe tener el formato xxxxxxxx-x';
          }
          if (label == 'NRC' &&
              !RegExp(r'^[A-Za-z0-9]{11}$').hasMatch(value ?? '')) {
            return 'El NRC debe tener 11 caracteres alfanuméricos.';
          }
          if (label == 'NIT' &&
              !RegExp(r'^\d{4}-\d{6}-\d{3}-\d$').hasMatch(value ?? '')) {
            return 'El NIT debe tener el formato xxxx-xxxxxx-xxx-x';
          }
          if (label == 'Correo Electrónico') {
            final RegExp emailRegex = RegExp(
              r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
            );
            if (!emailRegex.hasMatch(value)) {
              return 'Ingrese un correo electrónico válido';
            }
          }
          return null;
        },
      ),
    );
  }
}
