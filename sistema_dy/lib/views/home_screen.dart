import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sistema_dy/views/catalogo/lista_catalogo.dart';
import 'package:sistema_dy/views/ubicaciones_productos/lista_ubicaciones.dart';
import 'inventario/registrar_productos.dart';
import 'modulo_usuarios/login_screen.dart';
import 'modulo_usuarios/user_screen.dart';
import 'modulo_empleados/empleados_screen.dart';
import 'categoria/lista_categoria.dart';
import 'movimientos/movimientos_screen.dart';
import 'proveedores/proveedores_screen.dart';
import 'sucursal/mostrar_sucursales.dart';
import 'inventario/inventario_screen.dart';
import 'package:flutter/foundation.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dashboard',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          titleLarge: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              fontFamily: 'GoogleSans'),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.black87),
        ),
        cardTheme: const CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16))),
          surfaceTintColor: Colors.white,
        ),
      ),
      home: const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const DashboardScreen({super.key, required this.userData});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int? _hoveredCardIndex;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print("Datos del usuario recibido: ${widget.userData}");
    }
  }

  // Verifica permisos de administrador o root.
  bool _hasAdminAccess() {
    return (widget.userData['tipo_cuenta'] == 'Admin' ||
            widget.userData['tipo_cuenta'] == 'Root') &&
        (widget.userData['cargo'] == 'Administrador');
  }

  // Formatea la fecha ISO a un formato legible.
  String _formatDate(String isoDate) {
    try {
      DateTime date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      debugPrint("Error al formatear la fecha: $e");
      return 'Fecha no disponible';
    }
  }

  /// Muestra un menú emergente con la información del usuario.
  void _showUserModal(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const menuWidth = 280.0;
    const rightMargin = 20.0;
    const topMargin = 50.0;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        screenWidth - menuWidth - rightMargin,
        topMargin,
        0,
        0,
      ),
      items: [
        PopupMenuItem(
          height: 10,
          enabled: false,
          child: Container(
            padding: const EdgeInsets.all(16),
            width: menuWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUserInfoRow(
                    'Nombre completo:', widget.userData['nombre']),
                const SizedBox(height: 12),
                _buildUserInfoRow('Usuario:', widget.userData['usuario']),
                const SizedBox(height: 12),
                _buildUserInfoRow('Cargo:', widget.userData['cargo'] ?? ''),
                const SizedBox(height: 12),
                _buildUserInfoRow(
                    'Tipo de cuenta:', widget.userData['tipo_cuenta'] ?? ''),
                const SizedBox(height: 12),
                _buildUserInfoRow('Inicio de sesión:',
                    _formatDate(widget.userData['fecha_inicio'] ?? '')),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.logout, size: 18),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red.shade800,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.red.shade100),
                      ),
                    ),
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('token');
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginScreen()),
                      );
                    },
                    label: const Text('Cerrar Sesión'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
    );
  }

  /// Construye una fila con la información del usuario.
  Widget _buildUserInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/logos/logoEmpresa.png', height: 150),
            const SizedBox(width: 8),
            const Text('GRUPO RAMOS',
                style: TextStyle(fontFamily: 'GoogleSans')),
          ],
        ),
        centerTitle: false,
        titleSpacing: 16.0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 0.5),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0, top: 0.0),
            child: GestureDetector(
              onTap: () => _showUserModal(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_outline,
                        size: 20, color: colorScheme.onSurface),
                    const SizedBox(width: 8),
                    Text(
                      widget.userData['usuario'],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_drop_down,
                        size: 18, color: colorScheme.onSurface),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Image.asset('assets/logos/logo1.png', height: 100),
                  Image.asset('assets/logos/logo2.png', height: 100),
                  Image.asset('assets/logos/logo3.png', height: 100),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount;
                    if (constraints.maxWidth >= 1000) {
                      crossAxisCount = 4;
                    } else if (constraints.maxWidth >= 600) {
                      crossAxisCount = 3;
                    } else if (constraints.maxWidth >= 400) {
                      crossAxisCount = 2;
                    } else {
                      crossAxisCount = 1;
                    }
                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                      childAspectRatio: 1.8,
                      children: [
                        // Tarjeta para Usuarios (índice 0)
                        DashboardCard(
                          index: 0,
                          hoveredCardIndex: _hoveredCardIndex,
                          onHoverChanged: (i) {
                            setState(() {
                              _hoveredCardIndex = i;
                            });
                          },
                          title: 'Usuarios',
                          icon: Icons.group,
                          color: const Color.fromARGB(255, 96, 145, 241),
                          onTap: () {
                            if (!_hasAdminAccess()) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Acceso Denegado"),
                                  content: const Text(
                                      "No tiene permisos para acceder a la sección de usuarios."),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("Aceptar"),
                                    )
                                  ],
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const UsuariosScreen()),
                              );
                            }
                          },
                        ),
                        // Tarjeta para Empleados (índice 1)
                        DashboardCard(
                          index: 1,
                          hoveredCardIndex: _hoveredCardIndex,
                          onHoverChanged: (i) {
                            setState(() {
                              _hoveredCardIndex = i;
                            });
                          },
                          title: 'Empleados',
                          icon: Icons.work,
                          color: Colors.indigo,
                          onTap: () {
                            if (!_hasAdminAccess()) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Acceso Denegado"),
                                  content: const Text(
                                      "No tiene permisos para acceder a la sección de empleados."),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("Aceptar"),
                                    )
                                  ],
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const EmpleadosScreen()),
                              );
                            }
                          },
                        ),
                        // Tarjeta para Inventario (índice 2)
                        DashboardCard(
                          index: 2,
                          hoveredCardIndex: _hoveredCardIndex,
                          onHoverChanged: (i) {
                            setState(() {
                              _hoveredCardIndex = i;
                            });
                          },
                          title: 'Ver inventario',
                          icon: Icons.inventory_2,
                          color: colorScheme.primary,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => InventarioScreen()),
                            );
                          },
                        ),
                        DashboardCard(
                          index: 2,
                          hoveredCardIndex: _hoveredCardIndex,
                          onHoverChanged: (i) {
                            setState(() {
                              _hoveredCardIndex = i;
                            });
                          },
                          title: 'Entradas',
                          icon: Icons.inventory_2,
                          color: colorScheme.primary,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => RegistrarProductos()),
                            );
                          },
                        ),
                        DashboardCard(
                          index: 2,
                          hoveredCardIndex: _hoveredCardIndex,
                          onHoverChanged: (i) {
                            setState(() {
                              _hoveredCardIndex = i;
                            });
                          },
                          title: 'Ubicaciones',
                          icon: Icons.inventory_2,
                          color: colorScheme.primary,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ListaUbicaciones()),
                            );
                          },
                        ),
                        DashboardCard(
                          index: 2,
                          hoveredCardIndex: _hoveredCardIndex,
                          onHoverChanged: (i) {
                            setState(() {
                              _hoveredCardIndex = i;
                            });
                          },
                          title: 'Catalogo',
                          icon: Icons.inventory_2,
                          color: colorScheme.primary,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ListaCatalogo()),
                            );
                          },
                        ),
                        // Tarjeta para Proveedores (índice 3)
                        DashboardCard(
                          index: 3,
                          hoveredCardIndex: _hoveredCardIndex,
                          onHoverChanged: (i) {
                            setState(() {
                              _hoveredCardIndex = i;
                            });
                          },
                          title: 'Proveedores',
                          icon: Icons.person_remove_rounded,
                          color: colorScheme.tertiary,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const ProveedoresScreen()),
                            );
                          },
                        ),
                        // Tarjeta para Categorías (índice 4)
                        DashboardCard(
                          index: 4,
                          hoveredCardIndex: _hoveredCardIndex,
                          onHoverChanged: (i) {
                            setState(() {
                              _hoveredCardIndex = i;
                            });
                          },
                          title: 'Categorias',
                          icon: Icons.category,
                          color: colorScheme.tertiary,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ListaCategorias()),
                            );
                          },
                        ),
                        // Tarjeta para Sucursales (índice 5)
                        DashboardCard(
                          index: 5,
                          hoveredCardIndex: _hoveredCardIndex,
                          onHoverChanged: (i) {
                            setState(() {
                              _hoveredCardIndex = i;
                            });
                          },
                          title: 'Sucursales',
                          icon: Icons.store,
                          color: colorScheme.tertiary,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => MostrarSucursales()),
                            );
                          },
                        ),
                        // Tarjeta para Facturación (índice 6)
                        DashboardCard(
                          index: 6,
                          hoveredCardIndex: _hoveredCardIndex,
                          onHoverChanged: (i) {
                            setState(() {
                              _hoveredCardIndex = i;
                            });
                          },
                          title: 'Facturación',
                          icon: Icons.swap_horiz,
                          color: Colors.orange,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const MovimientosScreen()),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget de tarjeta del dashboard que reacciona al estado global de hover.
/// En esta versión, solo la tarjeta en la que se pasa el mouse se reduce a 0.95, mientras las demás mantienen su tamaño.
class DashboardCard extends StatefulWidget {
  final int index;
  final int? hoveredCardIndex;
  final Function(int?) onHoverChanged;
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const DashboardCard({
    super.key,
    required this.index,
    required this.hoveredCardIndex,
    required this.onHoverChanged,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<DashboardCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Si esta tarjeta está hover, se reduce a 0.95; en caso contrario, se mantiene en 1.0.
    final bool isHovered = widget.hoveredCardIndex == widget.index;
    final double scale = isHovered ? 0.95 : 1.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => widget.onHoverChanged(widget.index),
      onExit: (_) => widget.onHoverChanged(null),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          transform: Matrix4.identity()..scale(scale),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: theme.cardColor,
            border: Border.all(color: Colors.grey.shade300, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isHovered ? 0.2 : 0.15),
                blurRadius: isHovered ? 12 : 10,
                offset: Offset(0, isHovered ? 4 : 2),
              ),
            ],
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(widget.icon, size: 36, color: widget.color),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: widget.title.contains('\n') ? 18 : 16,
                      color: Colors.black87,
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
