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

  // Controladores para campos comunes
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _giroController = TextEditingController();
  final TextEditingController _correspondenciaController =
      TextEditingController();
  final TextEditingController _rubroController = TextEditingController();

  // Controladores para proveedor natural
  final TextEditingController _propietarioController = TextEditingController();
  final TextEditingController _duiController = TextEditingController();
  final TextEditingController _nrcNaturalController = TextEditingController();

  // Controladores para proveedor jurídico
  final TextEditingController _razonSocialController = TextEditingController();
  final TextEditingController _nitController = TextEditingController();
  final TextEditingController _nrcJuridicoController = TextEditingController();
  final TextEditingController _nombresRepresentanteController =
      TextEditingController();
  final TextEditingController _apellidosRepresentanteController =
      TextEditingController();
  final TextEditingController _direccionRepresentanteController =
      TextEditingController();
  final TextEditingController _telefonoRepresentanteController =
      TextEditingController();
  final TextEditingController _duiRepresentanteController =
      TextEditingController();
  final TextEditingController _nitRepresentanteController =
      TextEditingController();
  final TextEditingController _correoRepresentanteController =
      TextEditingController();

  // Controladores para sujeto excluido
  final TextEditingController _propietarioExcluidoController =
      TextEditingController();
  final TextEditingController _duiExcluidoController = TextEditingController();

  String _tipoProveedor = 'natural';

  // Formateadores para DUI y NIT
  List<TextInputFormatter> duiInputFormatters() {
    return [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(9),
      TextInputFormatter.withFunction((oldValue, newValue) {
        String newText = newValue.text;
        if (newText.length > 8) {
          newText = '${newText.substring(0, 8)}-${newText.substring(8)}';
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
          newText = '${newText.substring(0, 4)}-${newText.substring(4)}';
        }
        if (newText.length > 11) {
          newText = '${newText.substring(0, 11)}-${newText.substring(11)}';
        }
        if (newText.length > 15) {
          newText = '${newText.substring(0, 15)}-${newText.substring(15)}';
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
        'giro': _giroController.text,
        'correspondencia': _correspondenciaController.text,
        'rubro': _rubroController.text,
        'tipo_proveedor': _tipoProveedor,
      };

      if (_tipoProveedor == 'natural') {
        requestBody.addAll({
          'nombre_propietario': _propietarioController.text,
          'dui': _duiController.text,
          'nrc_natural': _nrcNaturalController.text,
        });
      } else if (_tipoProveedor == 'juridico') {
        requestBody.addAll({
          'razon_social': _razonSocialController.text,
          'nit': _nitController.text,
          'nrc_juridico': _nrcJuridicoController.text,
          'nombres_representante': _nombresRepresentanteController.text,
          'apellidos_representante': _apellidosRepresentanteController.text,
          'direccion_representante': _direccionRepresentanteController.text,
          'telefono_representante': _telefonoRepresentanteController.text,
          'dui_representante': _duiRepresentanteController.text,
          'nit_representante': _nitRepresentanteController.text,
          'correo_representante': _correoRepresentanteController.text,
        });
      } else if (_tipoProveedor == 'sujeto excluido') {
        // Cambiado a 'sujeto excluido'
        requestBody.addAll({
          'nombre_propietario_excluido': _propietarioExcluidoController.text,
          'dui_excluido': _duiExcluidoController.text,
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
    _giroController.dispose();
    _correspondenciaController.dispose();
    _rubroController.dispose();
    _propietarioController.dispose();
    _duiController.dispose();
    _nrcNaturalController.dispose();
    _razonSocialController.dispose();
    _nitController.dispose();
    _nrcJuridicoController.dispose();
    _nombresRepresentanteController.dispose();
    _apellidosRepresentanteController.dispose();
    _direccionRepresentanteController.dispose();
    _telefonoRepresentanteController.dispose();
    _duiRepresentanteController.dispose();
    _nitRepresentanteController.dispose();
    _correoRepresentanteController.dispose();
    _propietarioExcluidoController.dispose();
    _duiExcluidoController.dispose();
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
                    constraints: const BoxConstraints(maxWidth: 600),
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
                              child: Column(
                                children: <Widget>[
                                  _buildDropdown(),
                                  Wrap(
                                    spacing: 20,
                                    runSpacing: 20,
                                    children: [
                                      // Campos comunes
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildTextField(
                                              controller: _nombreController,
                                              label: 'Nombre comercial',
                                              icon: Icons.store,
                                            ),
                                          ),
                                          const SizedBox(width: 20),
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
                                          const SizedBox(width: 20),
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
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildTextField(
                                              controller: _giroController,
                                              label: 'Giro',
                                              icon: Icons.business,
                                            ),
                                          ),
                                          const SizedBox(width: 20),
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
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildTextField(
                                              controller: _rubroController,
                                              label: 'Rubro',
                                              icon: Icons.category,
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Campos específicos para Natural
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
                                            const SizedBox(width: 20),
                                            Expanded(
                                              child: _buildTextField(
                                                controller: _duiController,
                                                label: 'DUI',
                                                icon: Icons.badge,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildTextField(
                                                controller:
                                                    _nrcNaturalController,
                                                label: 'NRC',
                                                icon: Icons.receipt_long,
                                                 maxLength: 20,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      // Campos específicos para Jurídico
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
                                            const SizedBox(width: 20),
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
                                                controller:
                                                    _nrcJuridicoController,
                                                label: 'NRC',
                                                icon: Icons.receipt_long,
                                                 maxLength: 20,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildTextField(
                                                controller:
                                                    _nombresRepresentanteController,
                                                label: 'Nombres Representante',
                                                icon: Icons.person,
                                              ),
                                            ),
                                            const SizedBox(width: 20),
                                            Expanded(
                                              child: _buildTextField(
                                                controller:
                                                    _apellidosRepresentanteController,
                                                label:
                                                    'Apellidos Representante',
                                                icon: Icons.person_outline,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildTextField(
                                                controller:
                                                    _direccionRepresentanteController,
                                                label:
                                                    'Dirección Representante',
                                                icon: Icons.location_on,
                                              ),
                                            ),
                                            const SizedBox(width: 20),
                                            Expanded(
                                              child: _buildTextField(
                                                controller:
                                                    _telefonoRepresentanteController,
                                                label: 'Teléfono Representante',
                                                icon: Icons.call,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildTextField(
                                                controller:
                                                    _duiRepresentanteController,
                                                label: 'DUI Representante',
                                                icon: Icons.badge,
                                              ),
                                            ),
                                            const SizedBox(width: 20),
                                            Expanded(
                                              child: _buildTextField(
                                                controller:
                                                    _nitRepresentanteController,
                                                label: 'NIT Representante',
                                                icon: Icons.confirmation_number,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildTextField(
                                                controller:
                                                    _correoRepresentanteController,
                                                label: 'Correo Representante',
                                                icon: Icons.email,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      // Campos específicos para Sujeto Excluido
                                      if (_tipoProveedor ==
                                          'sujeto excluido') ...[
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildTextField(
                                                controller:
                                                    _propietarioExcluidoController,
                                                label:
                                                    'Nombre Propietario Excluido',
                                                icon: Icons.person,
                                              ),
                                            ),
                                            const SizedBox(width: 20),
                                            Expanded(
                                              child: _buildTextField(
                                                controller:
                                                    _duiExcluidoController,
                                                label: 'DUI Excluido',
                                                icon: Icons.badge,
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
                                ],
                              ),
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
          DropdownMenuItem(
              value: 'sujeto excluido', child: Text('Sujeto Excluido')),
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
  int? maxLength,
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
      maxLength: maxLength,
      inputFormatters: label == 'DUI' ||
              label == 'DUI Representante' ||
              label == 'DUI Excluido'
          ? duiInputFormatters()
          : (label == 'NIT' || label == 'NIT Representante'
              ? nitInputFormatters()
              : (label == 'Teléfono' || label == 'Teléfono Representante'
                  ? [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ]
                  : [])),
      validator: (value) {
        if (value == null || value.isEmpty) {
          if (label == 'Correspondencia') {
            return null;
          }
          return 'Por favor ingrese $label';
        }

        // Validación para Teléfono
        if ((label == 'Teléfono' || label == 'Teléfono Representante') &&
            !RegExp(r'^\d{8}$').hasMatch(value)) {
          return 'El teléfono debe tener 8 dígitos.';
        }

        // Validación para DUI
        if ((label == 'DUI' ||
                label == 'DUI Representante' ||
                label == 'DUI Excluido') &&
            !RegExp(r'^\d{8}-\d$').hasMatch(value)) {
          return 'El DUI debe tener el formato xxxxxxxx-x.';
        }

        // Validación para NIT
        if ((label == 'NIT' || label == 'NIT Representante') &&
            !RegExp(r'^\d{4}-\d{6}-\d{3}-\d$').hasMatch(value)) {
          return 'El NIT debe tener el formato xxxx-xxxxxx-xxx-x.';
        }

        // Validación para Correo Electrónico
        if ((label == 'Correo Electrónico' ||
                label == 'Correo Representante') &&
            !emailRegex.hasMatch(value)) {
          return 'Ingrese un correo electrónico válido.';
        }

        return null; // Si pasa todas las validaciones
      },
    ),
  );
}
}
