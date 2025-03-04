import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  @override
  void initState() {
    super.initState();

    if (kDebugMode) {
      print("Datos del usuario recibido: ${widget.userData}");
    }
  }

  // Función para formatear la fecha
  String _formatDate(String isoDate) {
    try {
      DateTime date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Fecha no disponible';
    }
  }

  /// Muestra un menú emergente con la información del usuario.
  void _showUserModal(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
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
                color: Colors.grey.shade700),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.black87),
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
                          color: colorScheme.onSurface),
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
                        DashboardCard(
                          title: 'Usuarios',
                          icon: Icons.group,
                          color: const Color.fromARGB(255, 96, 145, 241),
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const UsuariosScreen()));
                          },
                        ),
                        DashboardCard(
                          title: 'Empleados',
                          icon: Icons.work,
                          color: Colors.indigo,
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const EmpleadosScreen()));
                          },
                        ),
                        DashboardCard(
                          title: 'Inventario',
                          icon: Icons.inventory_2,
                          color: colorScheme.primary,
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => InventarioScreen()));
                          },
                        ),
                        DashboardCard(
                          title: 'Proveedores',
                          icon: Icons.person_remove_rounded,
                          color: colorScheme.tertiary,
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const ProveedoresScreen()));
                          },
                        ),
                        DashboardCard(
                          title: 'Categorias',
                          icon: Icons.category,
                          color: colorScheme.tertiary,
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ListaCategorias()));
                          },
                        ),
                        DashboardCard(
                          title: 'Sucursales',
                          icon: Icons.store,
                          color: colorScheme.tertiary,
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => MostrarSucursales()));
                          },
                        ),
                        DashboardCard(
                          title: 'Facturación',
                          icon: Icons.swap_horiz,
                          color: Colors.orange,
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const MovimientosScreen()));
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

  void _showSnack(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sección seleccionada: $text'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const DashboardCard(
      {super.key,
      required this.title,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: theme.cardColor,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: color.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(icon, size: 32, color: color),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: title.contains('\n') ? 18 : 16),
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
