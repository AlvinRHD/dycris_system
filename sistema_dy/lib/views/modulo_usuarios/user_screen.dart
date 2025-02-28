import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'agregar_usuario_modal.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _UsuariosScreenState createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  List<Map<String, dynamic>> usuarios = [];
  List<Map<String, dynamic>> usuariosFiltrados = [];
  final TextEditingController _searchController = TextEditingController();

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
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      filled: true,
      fillColor: Colors.white,
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchUsuarios();
    _searchController.addListener(_filterUsuarios);
  }

  Future<void> _fetchUsuarios() async {
    final url = Uri.parse('http://localhost:3000/api/usuarios');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          usuarios = data
              .map((e) => e as Map<String, dynamic>)
              .where((usuario) => usuario['tipo_cuenta'] != 'Root')
              .toList();
          usuariosFiltrados = usuarios;
        });
      } else {
        throw Exception('Error al cargar los usuarios');
      }
    } catch (error) {
      // ignore: avoid_print
      print('Error al obtener los usuarios: $error');
    }
  }

  String _formatDate(String date) {
    try {
      final DateTime parsedDate = DateTime.parse(date).toLocal();
      final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm');
      return formatter.format(parsedDate);
    } catch (e) {
      return 'Fecha inválida';
    }
  }

  void _filterUsuarios() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      usuariosFiltrados = usuarios.where((usuario) {
        return (usuario['nombre_completo'] as String)
                .toLowerCase()
                .contains(query) ||
            (usuario['usuario'] as String).toLowerCase().contains(query);
      }).toList();
    });
  }

  ButtonStyle _alertButtonStyle() {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.pressed)) {
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

  Future<void> _showAlertDialog(
      String title, String message, IconData icon, Color iconColor) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: _alertButtonStyle(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(String usuario) async {
    final url = Uri.parse('http://localhost:3000/api/usuarios/$usuario');
    try {
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        await _showAlertDialog(
          'Éxito',
          'Usuario eliminado exitosamente',
          Icons.check_circle,
          Colors.green,
        );
        _fetchUsuarios();
      } else {
        await _showAlertDialog(
          'Error',
          'Error al eliminar el usuario',
          Icons.error,
          Colors.red,
        );
      }
    } catch (e) {
      await _showAlertDialog(
        'Error',
        'Error al eliminar el usuario: $e',
        Icons.error,
        Colors.red,
      );
    }
  }

  Future<void> _confirmDelete(String usuario) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Confirmar eliminación'),
          ],
        ),
        content: Text('¿Está seguro de eliminar el usuario "$usuario"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: _alertButtonStyle(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: _alertButtonStyle(),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _deleteUser(usuario);
    }
  }

  /// Se elimina el parámetro 'cargo' para actualizar el usuario, ya que éste dato
  /// se debe mantener sincronizado desde la tabla de empleados.
  Future<void> _updateUser(
      String usuario, String tipoCuenta, String password) async {
    final url = Uri.parse('http://localhost:3000/api/usuarios/$usuario');
    final Map<String, dynamic> body = {
      'tipo_cuenta': tipoCuenta,
    };
    if (password.isNotEmpty) {
      body['password'] = password;
    }
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      if (response.statusCode == 200) {
        await _showAlertDialog(
          'Éxito',
          'Usuario actualizado exitosamente',
          Icons.check_circle,
          Colors.green,
        );
        _fetchUsuarios();
      } else {
        await _showAlertDialog(
          'Error',
          'Error al actualizar el usuario',
          Icons.error,
          Colors.red,
        );
      }
    } catch (e) {
      await _showAlertDialog(
        'Error',
        'Error al actualizar el usuario: $e',
        Icons.error,
        Colors.red,
      );
    }
  }

  Future<void> _showEditUserDialog(Map<String, dynamic> usuarioData) async {
    String tipoCuentaValue = usuarioData['tipo_cuenta']?.toString() ?? 'Admin';
    // Se muestra el cargo obtenido (de la unión con empleados en la API)
    String cargoValue = usuarioData['cargo']?.toString() ?? 'No definido';

    if (!['Admin', 'Normal'].contains(tipoCuentaValue)) {
      tipoCuentaValue = 'Admin';
    }

    final TextEditingController nombreController =
        TextEditingController(text: usuarioData['nombre_completo'] ?? '');
    final TextEditingController passwordController = TextEditingController();
    bool obscureText = true;

    return showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return AlertDialog(
              title: const Text(
                'Editar Usuario',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Usuario: ${usuarioData['usuario']}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nombreController,
                      decoration:
                          _inputDecoration('Nombre Completo', Icons.person),
                      enabled: false,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: tipoCuentaValue,
                      decoration:
                          _inputDecoration('Tipo de Cuenta', Icons.people_alt),
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Color(0xFF3C3C3C)),
                      items: ['Admin', 'Normal'].map((rol) {
                        return DropdownMenuItem<String>(
                          value: rol,
                          child: Text(rol),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setStateModal(() => tipoCuentaValue = value!),
                    ),
                    const SizedBox(height: 16),
                    // Campo para mostrar el cargo en modo lectura, ya que proviene de empleados
                    TextFormField(
                      initialValue: cargoValue,
                      decoration:
                          _inputDecoration('Cargo', Icons.work_outline),
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: passwordController,
                      obscureText: obscureText,
                      decoration: _inputDecoration(
                              'Nueva Contraseña (opcional)', Icons.lock)
                          .copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureText
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: const Color(0xFF3C3C3C),
                          ),
                          onPressed: () => setStateModal(
                              () => obscureText = !obscureText),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    if (tipoCuentaValue.isEmpty) {
                      await _showAlertDialog(
                        'Error',
                        'El tipo de cuenta es requerido',
                        Icons.error,
                        Colors.red,
                      );
                      return;
                    }

                    if (passwordController.text.isNotEmpty) {
                      if (passwordController.text.length < 8) {
                        await _showAlertDialog(
                          'Error',
                          'La contraseña debe tener al menos 8 caracteres',
                          Icons.error,
                          Colors.red,
                        );
                        return;
                      }
                      if (!passwordController.text.contains(RegExp(r'[A-Z]')) ||
                          !passwordController.text.contains(RegExp(r'[0-9]'))) {
                        await _showAlertDialog(
                          'Error',
                          'La contraseña debe contener al menos una mayúscula y un número',
                          Icons.error,
                          Colors.red,
                        );
                        return;
                      }
                    }

                    await _updateUser(
                      usuarioData['usuario'],
                      tipoCuentaValue,
                      passwordController.text.trim(),
                    );
                    // ignore: use_build_context_synchronously
                    Navigator.of(context).pop();
                  },
                  style: _alertButtonStyle().copyWith(
                    side: WidgetStateProperty.all(
                      BorderSide(
                          color: Colors.black.withOpacity(0.3), width: 1),
                    ),
                  ),
                  child: const Text('Guardar cambios'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: _alertButtonStyle().copyWith(
                    side: WidgetStateProperty.all(
                      BorderSide(
                          color: Colors.black.withOpacity(0.3), width: 1),
                    ),
                  ),
                  child: const Text('Cancelar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Usuarios Registrados',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(30),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: Colors.black,
              ),
            ),
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.grey[50],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Buscar usuario...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AgregarUsuarioDialog(
                          onUserAdded: () {
                            _fetchUsuarios();
                            setState(() {});
                          },
                        ),
                      ).then((_) => _fetchUsuarios());
                    },
                    icon: const Icon(Icons.person_add_alt_1, size: 20),
                    label: const Text('Nuevo Usuario'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A2D3E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columnSpacing: 40,
                        horizontalMargin: 24,
                        headingRowHeight: 56,
                        dataRowHeight: 56,
                        headingRowColor:
                            MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) => Colors.grey[50]!,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black12),
                        ),
                        columns: const [
                          DataColumn(
                              label: Text(
                            'Nombre Completo',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          )),
                          DataColumn(
                              label: Text(
                            'Usuario',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          )),
                          DataColumn(
                              label: Text(
                            'Tipo de Cuenta',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          )),
                          DataColumn(
                              label: Text(
                            'Cargo',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          )),
                          DataColumn(
                              label: Text(
                            'Fecha Creación',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          )),
                          DataColumn(
                              label: Text(
                            'Fecha Actualización',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          )),
                          DataColumn(
                              label: Text(
                            'Acciones',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          )),
                        ],
                        rows: usuariosFiltrados
                            .map(
                              (usuario) => DataRow(
                                cells: [
                                  DataCell(
                                      Text(usuario['nombre_completo'] ?? '')),
                                  DataCell(Text(usuario['usuario'] ?? '')),
                                  DataCell(Text(usuario['tipo_cuenta'] ?? '')),
                                  DataCell(Text(usuario['cargo'] ?? '')),
                                  DataCell(Text(_formatDate(
                                      usuario['fecha_creacion'] ?? ''))),
                                  DataCell(Text(_formatDate(
                                      usuario['fecha_actualizacion'] ?? ''))),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit,
                                              color: Colors.blue),
                                          onPressed: () =>
                                              _showEditUserDialog(usuario),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () =>
                                              _confirmDelete(usuario['usuario']),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
