import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AgregarUsuarioDialog extends StatefulWidget {
  final VoidCallback onUserAdded;

  const AgregarUsuarioDialog({super.key, required this.onUserAdded});

  @override
  // ignore: library_private_types_in_public_api
  _AgregarUsuarioDialogState createState() => _AgregarUsuarioDialogState();
}

class _AgregarUsuarioDialogState extends State<AgregarUsuarioDialog> {
  List<Map<String, dynamic>> empleados = [];
  bool isLoading = true;

  String? selectedEmpleadoId;
  String usuario = "";
  String password = "";
  String tipoCuenta = "Normal";
  String cargo = "Administrador";

  bool obscureText = true;

  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchEmpleados();
  }

  Future<void> _fetchEmpleados() async {
    setState(() => isLoading = true);
    try {
      final url = Uri.parse("http://localhost:3000/api/empleados-sin-usuario");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          empleados = data.cast<Map<String, dynamic>>();
          if (empleados.isNotEmpty) {
            selectedEmpleadoId = empleados.first["id"].toString();
            cargo = empleados.first["cargo"] ?? 'Administrador';
          }
        });
      } else {
        _showAlertDialog(
            "Error", "Error al obtener empleados: ${response.statusCode}");
      }
    } catch (e) {
      _showAlertDialog("Error", "Error de conexión: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  InputDecoration _inputDecoration(String labelText, IconData icon) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: Color(0xFF3C3C3C)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF3C3C3C)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF3C3C3C)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF3C3C3C)),
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF3C3C3C)),
      contentPadding:
          const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Future<void> _submit() async {
    if (selectedEmpleadoId == null || selectedEmpleadoId!.isEmpty) {
      _showAlertDialog("Error", "Seleccione un empleado");
      return;
    }
    if (usuario.isEmpty) {
      _showAlertDialog("Error", "Ingrese el nombre de usuario");
      return;
    }
    if (password.isEmpty) {
      _showAlertDialog("Error", "Ingrese la contraseña");
      return;
    }
    if (password.length < 8) {
      _showAlertDialog(
          "Error", "La contraseña debe tener al menos 8 caracteres");
      return;
    }
    if (!RegExp(r'[A-Z]').hasMatch(password) ||
        !RegExp(r'[0-9]').hasMatch(password)) {
      _showAlertDialog("Error",
          "La contraseña debe contener al menos una mayúscula y un número");
      return;
    }

    final empleado = empleados
        .firstWhere((emp) => emp["id"].toString() == selectedEmpleadoId);
    final String nombreCompleto =
        "${empleado["nombres"] ?? ''} ${empleado["apellidos"] ?? ''}".trim();

    final Map<String, dynamic> body = {
      "nombre_completo": nombreCompleto,
      "usuario": usuario,
      "password": password,
      "tipo_cuenta": tipoCuenta,
      "cargo": cargo,
    };

    try {
      final url = Uri.parse("http://localhost:3000/api/usuarios");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        widget.onUserAdded();
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop();
      } else {
        _showAlertDialog("Error", "Error al agregar usuario: ${response.body}");
      }
    } catch (e) {
      _showAlertDialog("Error", "Error al agregar usuario: $e");
    }
  }

  // Estilo de botón para las alertas, igual al utilizado en UsuariosScreen.
  ButtonStyle _alertButtonStyle() {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.pressed)) {
            // ignore: deprecated_member_use
            return const Color.fromARGB(255, 18, 122, 234).withOpacity(0.15);
          }
          return Theme.of(context).dialogBackgroundColor;
        },
      ),
      foregroundColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) => const Color(0xFF2A2D3E),
      ),
      elevation: WidgetStateProperty.all(0),
      padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 18)),
      overlayColor: WidgetStateProperty.all(Colors.transparent),
    );
  }

  Future<void> _showAlertDialog(String title, String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: _alertButtonStyle(),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _usuarioController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      title: const Text(
        "Agregar Usuario",
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 350, // Ancho personalizado para el diálogo
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (empleados.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                            "No hay empleados disponibles para registrar"),
                      )
                    else ...[
                      DropdownButtonFormField<String>(
                        value: selectedEmpleadoId,
                        decoration:
                            _inputDecoration("Nombre Completo", Icons.person),
                        icon: const Icon(Icons.arrow_drop_down,
                            color: Color(0xFF3C3C3C)),
                        items: empleados.map((empleado) {
                          return DropdownMenuItem<String>(
                            value: empleado["id"].toString(),
                            child: Text(
                                "${empleado["nombres"] ?? ''} ${empleado["apellidos"] ?? ''}"),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedEmpleadoId = value;
                            final empleado = empleados.firstWhere(
                                (emp) => emp["id"].toString() == value);
                            cargo = empleado["cargo"] ?? 'Administrador';
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _usuarioController,
                        decoration:
                            _inputDecoration("Usuario", Icons.person_outline),
                        onChanged: (value) =>
                            setState(() => usuario = value),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: obscureText,
                        decoration:
                            _inputDecoration("Contraseña", Icons.lock)
                                .copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureText
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: const Color(0xFF3C3C3C),
                            ),
                            onPressed: () =>
                                setState(() => obscureText = !obscureText),
                          ),
                        ),
                        onChanged: (value) =>
                            setState(() => password = value),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: tipoCuenta,
                        decoration: _inputDecoration(
                            "Tipo de Cuenta", Icons.people_alt),
                        icon: const Icon(Icons.arrow_drop_down,
                            color: Color(0xFF3C3C3C)),
                        items: ['Admin', 'Normal'].map((tc) {
                          return DropdownMenuItem<String>(
                            value: tc,
                            child: Text(tc),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => tipoCuenta = value!),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: cargo,
                        decoration:
                            _inputDecoration("Cargo", Icons.work_outline),
                        icon: const Icon(Icons.arrow_drop_down,
                            color: Color(0xFF3C3C3C)),
                        items: [
                          'Administrador',
                          'Gerente',
                          'Cajero',
                          'Vendedor',
                          'Bodeguero'
                        ].map((c) => DropdownMenuItem<String>(
                              value: c,
                              child: Text(c),
                            )).toList(),
                        onChanged: (value) =>
                            setState(() => cargo = value!),
                      ),
                    ],
                  ],
                ),
              ),
      ),
      actions: [
        if (empleados.isNotEmpty) ...[
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[200],
              foregroundColor: const Color(0xFF2A2D3E),
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 18),
            ),
            child: const Text("Agregar Usuario"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[200],
              foregroundColor: const Color(0xFF2A2D3E),
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 18),
            ),
            child: const Text("Cancelar"),
          ),
        ]
      ],
    );
  }
}
