// Importación de paquetes necesarios para la aplicación
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Para codificar y decodificar datos JSON

import 'registro_screen.dart'; // Pantalla para el registro de nuevos usuarios

// Clase principal que representa la pantalla de usuarios, es un StatefulWidget para poder actualizar su estado
class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _UsuariosScreenState createState() => _UsuariosScreenState();
}

// Estado de la pantalla de usuarios
class _UsuariosScreenState extends State<UsuariosScreen> {
  // Lista que almacenará todos los usuarios obtenidos desde el API
  List<Map<String, dynamic>> usuarios = [];
  // Lista que contendrá los usuarios filtrados según la búsqueda
  List<Map<String, dynamic>> usuariosFiltrados = [];
  // Controlador para el campo de búsqueda
  final TextEditingController _searchController = TextEditingController();

  /// Método para retornar una decoración personalizada para campos de texto.
  /// Recibe un [labelText] y un [icon] que se muestran en el campo.
  InputDecoration _inputDecoration(String labelText, IconData icon) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: Color(0xFF3C3C3C)),
      // Borde predeterminado del campo
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF3C3C3C)),
      ),
      // Borde cuando el campo está habilitado
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF3C3C3C)),
      ),
      // Borde cuando el campo está enfocado
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF3C3C3C)),
      ),
      // Icono al inicio del campo
      prefixIcon: Icon(icon, color: const Color(0xFF3C3C3C)),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      filled: true,
      fillColor: Colors.white,
    );
  }

  @override
  void initState() {
    super.initState();
    // Se carga la lista de usuarios al iniciar la pantalla
    _fetchUsuarios();
    // Se añade un listener para filtrar la lista de usuarios conforme se escribe en el campo de búsqueda
    _searchController.addListener(_filterUsuarios);
  }

  /// Método asíncrono para obtener los usuarios desde el API.
  /// Realiza una petición GET y actualiza las listas de usuarios.
  Future<void> _fetchUsuarios() async {
    final url = Uri.parse('http://localhost:3000/api/usuarios');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        // Decodifica el cuerpo de la respuesta y lo asigna a la lista de usuarios
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          usuarios = data.map((e) => e as Map<String, dynamic>).toList();
          // Inicialmente, la lista filtrada es igual a la completa
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

  /// Método para formatear una cadena de fecha recibida del API.
  /// Retorna la fecha formateada en el formato "dd/MM/yyyy HH:mm" o "Fecha inválida" en caso de error.
  String _formatDate(String date) {
    try {
      final DateTime parsedDate = DateTime.parse(date).toLocal();
      final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm');
      return formatter.format(parsedDate);
    } catch (e) {
      return 'Fecha inválida';
    }
  }

  /// Método para filtrar la lista de usuarios según la consulta escrita en el campo de búsqueda.
  void _filterUsuarios() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      usuariosFiltrados = usuarios.where((usuario) {
        // Se filtra si el nombre completo o el nombre de usuario contienen la consulta en minúsculas
        return (usuario['nombre_completo'] as String)
                .toLowerCase()
                .contains(query) ||
            (usuario['usuario'] as String).toLowerCase().contains(query);
      }).toList();
    });
  }

  /// Método que define y retorna el estilo de los botones de alerta.
  /// Este estilo se utiliza en los diálogos y en la ventana modal.
  ButtonStyle _alertButtonStyle() {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          // Cambia el color de fondo al pasar el ratón o presionar
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.pressed)) {
            // ignore: deprecated_member_use
            return const Color.fromARGB(255, 18, 122, 234).withOpacity(0.15);
          }
          // Color de fondo por defecto, tomado del tema del diálogo
          return Theme.of(context).dialogBackgroundColor;
        },
      ),
      // Color del texto de los botones
      foregroundColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          return const Color(0xFF2A2D3E);
        },
      ),
      elevation: WidgetStateProperty.all(0),
      // Espaciado interno de los botones
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      ),
      // Forma del botón: bordes redondeados
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      // Estilo del texto del botón
      textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 18)),
      overlayColor: WidgetStateProperty.all(Colors.transparent),
    );
  }

  /// Muestra un diálogo de alerta genérico.
  /// [title] es el título, [message] el mensaje, [icon] el ícono a mostrar y [iconColor] el color del ícono.
  Future<void> _showAlertDialog(
      String title, String message, IconData icon, Color iconColor) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // Permite cerrar el diálogo al tocar fuera
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
          // Botón "OK" que utiliza el estilo definido en _alertButtonStyle()
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: _alertButtonStyle(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Realiza la eliminación de un usuario enviando una petición DELETE al API.
  /// Muestra un diálogo de alerta con el resultado de la operación.
  Future<void> _deleteUser(String usuario) async {
    final url = Uri.parse('http://localhost:3000/api/usuarios/$usuario');
    try {
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        // Al eliminar exitosamente se muestra un diálogo de éxito
        await _showAlertDialog(
          'Éxito',
          'Usuario eliminado exitosamente',
          Icons.check_circle,
          Colors.green,
        );
        // Se recarga la lista de usuarios
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

  /// Muestra un diálogo de confirmación antes de eliminar un usuario.
  /// Si se confirma, se procede a llamar a [_deleteUser].
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
          // Botón "Cancelar" que cierra el diálogo sin eliminar
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: _alertButtonStyle(),
            child: const Text('Cancelar'),
          ),
          // Botón "Eliminar" que confirma la eliminación
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

  /// Actualiza los datos de un usuario mediante una petición PUT al API.
  /// Se envían [nombreCompleto], [rol] y, si se proporciona, [password].
  Future<void> _updateUser(String usuario, String nombreCompleto, String rol,
      String password) async {
    final url = Uri.parse('http://localhost:3000/api/usuarios/$usuario');
    final Map<String, dynamic> body = {
      'nombre_completo': nombreCompleto,
      'rol': rol,
    };
    // Si se especifica una contraseña, se agrega al cuerpo de la petición
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

  /// Muestra un diálogo modal para editar los datos de un usuario.
  /// Permite actualizar el nombre completo, el rol y opcionalmente la contraseña.
  Future<void> _showEditUserDialog(Map<String, dynamic> usuarioData) async {
    // Controladores para los campos de texto, inicializados con los datos actuales del usuario
    final TextEditingController nombreController =
        TextEditingController(text: usuarioData['nombre_completo'] ?? '');
    final TextEditingController passwordController = TextEditingController();
    // Valor inicial del rol; si no existe se asigna "Admin"
    String rolValue = usuarioData['rol'] ?? 'Admin';
    // Variable para controlar la visibilidad del texto de la contraseña
    bool obscureText = true;

    return showDialog<void>(
      context: context,
      builder: (context) {
        // StatefulBuilder permite actualizar el estado interno del diálogo
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
                    // Muestra el nombre de usuario (no editable)
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
                    // Campo para editar el nombre completo
                    TextFormField(
                      controller: nombreController,
                      decoration:
                          _inputDecoration('Nombre Completo', Icons.person),
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).nextFocus();
                      },
                    ),
                    const SizedBox(height: 16),
                    // Campo para seleccionar el rol a través de un Dropdown
                    DropdownButtonFormField<String>(
                      value: rolValue,
                      decoration: _inputDecoration('Rol', Icons.work).copyWith(
                        filled: true,
                        fillColor: Colors.white,
                        suffixIcon: const Icon(
                          Icons.arrow_drop_down,
                          color: Color(0xFF3C3C3C),
                        ),
                      ),
                      items: ['Admin', 'Caja', 'Asesor de Venta'].map((rol) {
                        return DropdownMenuItem<String>(
                          value: rol,
                          child: Text(rol),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setStateModal(() {
                          rolValue = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Campo para actualizar la contraseña (opcional)
                    TextFormField(
                      controller: passwordController,
                      obscureText: obscureText,
                      decoration: _inputDecoration(
                              'Nueva Contraseña (opcional)', Icons.lock)
                          .copyWith(
                        // Botón para mostrar/ocultar la contraseña
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureText
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: const Color(0xFF3C3C3C),
                          ),
                          onPressed: () {
                            setStateModal(() {
                              obscureText = !obscureText;
                            });
                          },
                        ),
                      ),
                      textInputAction: TextInputAction.done,
                    ),
                  ],
                ),
              ),
              actions: [
                // Botón "Guardar cambios" con estilo de alerta y borde semitransparente
                ElevatedButton(
                  onPressed: () async {
                    final String nuevoNombre = nombreController.text.trim();
                    final String nuevoRol = rolValue;
                    final String nuevaPassword = passwordController.text.trim();
                    await _updateUser(usuarioData['usuario'], nuevoNombre,
                        nuevoRol, nuevaPassword);
                    // ignore: use_build_context_synchronously
                    Navigator.of(context).pop();
                  },
                  // Se utiliza el estilo de alerta y se añade un borde semivisible
                  style: _alertButtonStyle().copyWith(
                    side: WidgetStateProperty.all(
                      // ignore: deprecated_member_use
                      BorderSide(
                          color: Colors.black.withOpacity(0.3), width: 1),
                    ),
                  ),
                  child: const Text('Guardar cambios'),
                ),
                // Botón "Cancelar" con el mismo estilo y borde
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: _alertButtonStyle().copyWith(
                    side: WidgetStateProperty.all(
                      // ignore: deprecated_member_use
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
    // Se libera el controlador de búsqueda al eliminarse el widget
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar con título personalizado y botón de regreso
      appBar: AppBar(
        // Título en negrita y con fuente de mayor tamaño
        title: const Text(
          'Usuarios Registrados',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        // Botón de regreso mejorado
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
      // Cuerpo de la pantalla
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Barra de búsqueda con borde negro y sombra sutil
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black),
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icono de búsqueda
                  const Icon(Icons.search, color: Colors.grey, size: 28),
                  const SizedBox(width: 12),
                  // Campo de texto para ingresar la búsqueda
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
                  // Botón para ir a la pantalla de registro de nuevos usuarios
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegistroScreen(),
                        ),
                      );
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
            // Contenedor que muestra la tabla de usuarios
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      // ignore: deprecated_member_use
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  // Se utiliza SingleChildScrollView para permitir el desplazamiento horizontal y vertical de la tabla
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columnSpacing: 40,
                        horizontalMargin: 24,
                        headingRowHeight: 56,
                        // ignore: deprecated_member_use
                        dataRowHeight: 56,
                        // Color de fondo de la fila de encabezado
                        headingRowColor: WidgetStateProperty.resolveWith<Color>(
                          (Set<WidgetState> states) => Colors.grey[50]!,
                        ),
                        // Borde de la tabla
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black12),
                        ),
                        // Definición de las columnas de la tabla
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
                            'Rol',
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
                        // Genera las filas de la tabla con los datos de los usuarios filtrados
                        rows: usuariosFiltrados
                            .map(
                              (usuario) => DataRow(
                                cells: [
                                  DataCell(
                                      Text(usuario['nombre_completo'] ?? '')),
                                  DataCell(Text(usuario['usuario'] ?? '')),
                                  DataCell(Text(usuario['rol'] ?? '')),
                                  DataCell(Text(_formatDate(
                                      usuario['fecha_creacion'] ?? ''))),
                                  DataCell(Text(_formatDate(
                                      usuario['fecha_actualizacion'] ?? ''))),
                                  DataCell(
                                    Row(
                                      children: [
                                        // Botón para editar el usuario, que abre el diálogo modal de edición
                                        IconButton(
                                          icon: const Icon(Icons.edit,
                                              color: Colors.blue),
                                          onPressed: () =>
                                              _showEditUserDialog(usuario),
                                        ),
                                        // Botón para eliminar el usuario, que abre el diálogo de confirmación
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () => _confirmDelete(
                                              usuario['usuario']),
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
