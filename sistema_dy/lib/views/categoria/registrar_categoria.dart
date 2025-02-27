import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegistrarCategoria extends StatefulWidget {
  final Function actualizarLista;

  RegistrarCategoria({required this.actualizarLista});

  @override
  _RegistrarCategoriaState createState() => _RegistrarCategoriaState();
}

class _RegistrarCategoriaState extends State<RegistrarCategoria> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController nombreController = TextEditingController();
  TextEditingController descripcionController = TextEditingController();
  String? estadoSeleccionado; // Variable para almacenar la opción seleccionada

  Future<void> registrarCategoria() async {
    if (_formKey.currentState!.validate()) {
      final url = Uri.parse("http://localhost:3000/api/categoria");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nombre": nombreController.text,
          "descripcion": descripcionController.text,
          "estado": estadoSeleccionado,
        }),
      );
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sucursal registrada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        widget.actualizarLista();
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar sucursal'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                              "Registro de Categoría",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1976D2),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Form(
                              key: _formKey,
                              child: Column(
                                children: <Widget>[
                                  _buildTextField(
                                    controller: nombreController,
                                    label: "Nombre",
                                    icon: Icons.category,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: descripcionController,
                                    label: "Descripción",
                                    icon: Icons.description,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildDropdownField(
                                    label: "Estado",
                                    icon: Icons.toggle_on,
                                    items: ["Activo", "Inactivo"],
                                    selectedValue: estadoSeleccionado,
                                    onChanged: (value) {
                                      setState(() {
                                        estadoSeleccionado = value;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton(
                                    onPressed: registrarCategoria,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 30, vertical: 15),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      backgroundColor: const Color(0xFF2A2D3E),
                                    ),
                                    child: const Text(
                                      "Registrar",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 30, vertical: 15),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      backgroundColor: Colors.grey[600],
                                    ),
                                    child: const Text(
                                      "Regresar",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
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
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor ingrese $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required List<String> items,
    String? selectedValue,
    void Function(String?)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          prefixIcon: Icon(icon),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor seleccione $label';
          }
          return null;
        },
        items: items.map<DropdownMenuItem<String>>((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
      ),
    );
  }
}
