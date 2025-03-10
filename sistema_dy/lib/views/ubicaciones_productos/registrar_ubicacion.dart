import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Sucursal {
  final int id;
  final String nombre;

  Sucursal({required this.id, required this.nombre});

  factory Sucursal.fromJson(Map<String, dynamic> json) {
    return Sucursal(
      id: json['id'],
      nombre: json['nombre'],
    );
  }
}

class RegistrarUbicacion extends StatefulWidget {
  final Function actualizarLista;

  RegistrarUbicacion({required this.actualizarLista});

  @override
  _RegistrarUbicacionState createState() => _RegistrarUbicacionState();
}

class _RegistrarUbicacionState extends State<RegistrarUbicacion> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController ubicacionController = TextEditingController();
  TextEditingController descripcionController = TextEditingController();
  String? estadoSeleccionado; // Variable para almacenar la opción seleccionada
  List<Sucursal> sucursales = [];
  int? sucursalIdSeleccionada; // Almacena el ID de la sucursal seleccionada

  @override
  void initState() {
    super.initState();
    fetchSucursales(); // Cargar las sucursales al iniciar
  }

  Future<void> fetchSucursales() async {
    final url = Uri.parse("http://localhost:3000/api/sucursal");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        sucursales = data.map((sucursal) => Sucursal.fromJson(sucursal)).toList();
      });
    } else {
      throw Exception("Error al cargar las sucursales");
    }
  }

  Future<void> registrarUbicacion() async {
    if (_formKey.currentState!.validate()) {
      final url = Uri.parse("http://localhost:3000/api/ubicaciones_productos");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "sucursal_id": sucursalIdSeleccionada, // Usar el ID de la sucursal seleccionada
          "ubicacion": ubicacionController.text,
          "descripcion": descripcionController.text,
        }),
      );
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ubicación registrada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        widget.actualizarLista();
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar ubicación'),
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
                              "Registro de Ubicación",
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
                                  DropdownButtonFormField<int>(
                                    value: sucursalIdSeleccionada,
                                    decoration: InputDecoration(
                                      labelText: "Seleccionar Sucursal",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    items: sucursales.map((sucursal) {
                                      return DropdownMenuItem<int>(
                                        value: sucursal.id,
                                        child: Text(sucursal.nombre),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        sucursalIdSeleccionada = value;
                                      });
                                    },
                                    validator: (value) {
                                      if (value == null) {
                                        return 'Por favor seleccione una sucursal';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: ubicacionController,
                                    label: "Ubicación",
                                    icon: Icons.location_on,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: descripcionController,
                                    label: "Descripción",
                                    icon: Icons.description,
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton(
                                    onPressed: registrarUbicacion,
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
}