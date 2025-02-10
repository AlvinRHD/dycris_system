import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _RegistroScreenState createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _rol = 'Admin';
  bool _obscureText = true;

  // FocusNode para manejar el foco de los campos
  final FocusNode _usuarioFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  Future<void> _registrarUsuario() async {
    if (_formKey.currentState?.validate() ?? false) {
      final nombreCompleto = _nombreController.text;
      final usuario = _usuarioController.text;
      final password = _passwordController.text;

      final response = await http.post(
        Uri.parse('http://localhost:3000/api/usuarios'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nombre_completo': nombreCompleto,
          'usuario': usuario,
          'password': password,
          'rol': _rol,
        }),
      );

      if (response.statusCode == 201) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuario registrado correctamente')));

        // Limpiar los campos después de enviar los datos
        _nombreController.clear();
        _usuarioController.clear();
        _passwordController.clear();
        setState(() {
          _rol = 'Admin'; // Reiniciar el valor del rol si es necesario
        });
      } else {
        final errorData = json.decode(response.body);
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${errorData['message']}')));
      }
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  void _regresarAHome() {
    Navigator.pop(context); // Regresa a la pantalla anterior (Home)
  }

  @override
  void dispose() {
    _usuarioFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          // Usando gradiente de fondo
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE3F2FD), // Azul claro
              Color(0xFFBBDEFB), // Azul más fuerte
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
                              "Registro de Usuario",
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
                                  TextFormField(
                                    controller: _nombreController,
                                    decoration: InputDecoration(
                                      labelText: 'Nombre Completo',
                                      labelStyle: const TextStyle(
                                          color: Color(0xFF3C3C3C)),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                            color: Color(0xFF3C3C3C)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                            color: Color(0xFF3C3C3C)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                            color: Color(0xFF3C3C3C)),
                                      ),
                                      prefixIcon: const Icon(Icons.person,
                                          color: Color(0xFF3C3C3C)),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor ingrese su nombre completo';
                                      }
                                      return null;
                                    },
                                    textInputAction: TextInputAction.next,
                                    onFieldSubmitted: (_) {
                                      FocusScope.of(context)
                                          .requestFocus(_usuarioFocusNode);
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _usuarioController,
                                    focusNode: _usuarioFocusNode,
                                    decoration: InputDecoration(
                                      labelText: 'Usuario',
                                      labelStyle: const TextStyle(
                                          color: Color(0xFF3C3C3C)),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                            color: Color(0xFF3C3C3C)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                            color: Color(0xFF3C3C3C)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                            color: Color(0xFF3C3C3C)),
                                      ),
                                      prefixIcon: const Icon(
                                          Icons.account_circle,
                                          color: Color(0xFF3C3C3C)),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor ingrese un nombre de usuario';
                                      }
                                      return null;
                                    },
                                    textInputAction: TextInputAction.next,
                                    onFieldSubmitted: (_) {
                                      FocusScope.of(context)
                                          .requestFocus(_passwordFocusNode);
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _passwordController,
                                    focusNode: _passwordFocusNode,
                                    obscureText: _obscureText,
                                    decoration: InputDecoration(
                                      labelText: 'Contraseña',
                                      labelStyle: const TextStyle(
                                          color: Color(0xFF3C3C3C)),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                            color: Color(0xFF3C3C3C)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                            color: Color(0xFF3C3C3C)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                            color: Color(0xFF3C3C3C)),
                                      ),
                                      prefixIcon: const Icon(Icons.lock,
                                          color: Color(0xFF3C3C3C)),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureText
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: const Color(0xFF3C3C3C),
                                        ),
                                        onPressed: _togglePasswordVisibility,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor ingrese una contraseña';
                                      }
                                      return null;
                                    },
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) {
                                      _registrarUsuario();
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  DropdownButtonFormField<String>(
                                    value: _rol,
                                    decoration: InputDecoration(
                                      labelText: 'Rol',
                                      labelStyle: const TextStyle(
                                          color: Color(0xFF3C3C3C)),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                            color: Color(0xFF3C3C3C),
                                            width: 1.5),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                            color: Color(0xFF3C3C3C),
                                            width: 1.5),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                            color: Color(0xFF3C3C3C),
                                            width: 2.0),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 14),
                                    ),
                                    dropdownColor: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    menuMaxHeight: 200,
                                    elevation: 4,
                                    icon: const Icon(Icons.arrow_drop_down,
                                        color: Color(0xFF3C3C3C)),
                                    style: const TextStyle(
                                      color: Color(0xFF3C3C3C),
                                      fontSize: 16,
                                    ),
                                    items: ['Admin', 'Caja', 'Asesor de Venta']
                                        .map((rol) {
                                      return DropdownMenuItem<String>(
                                        value: rol,
                                        child: Text(rol),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _rol = value!;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: _registrarUsuario,
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor:
                                              const Color(0xFF2A2D3E),
                                          backgroundColor: const Color(
                                              0xFF8C9CAD), // Color texto
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 32, vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.check,
                                          color: Color(0xFF2A2D3E),
                                        ),
                                        label: const Text(
                                          'Registrar',
                                          style: TextStyle(fontSize: 18),
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: _regresarAHome,
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor:
                                              const Color(0xFF2A2D3E),
                                          backgroundColor: const Color(
                                              0xFF8C9CAD), // Color texto
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 32, vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.arrow_back,
                                          color: Color(0xFF2A2D3E),
                                        ),
                                        label: const Text(
                                          'Regresar',
                                          style: TextStyle(fontSize: 18),
                                        ),
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
}
