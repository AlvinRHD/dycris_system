import 'package:flutter/material.dart';
import 'categoria/lista_categoria.dart';
import 'inventario/inventario_screen.dart';
import 'modulo_empleados/empleados_screen.dart';
import 'modulo_usuarios/user_screen.dart';

import 'movimientos/compras_screen.dart';
import 'movimientos/movimientos_screen.dart';
import 'movimientos/ofertas/ofertas_screen.dart';
import 'movimientos/salidas_screen.dart';
import 'movimientos/traslados/traslados_screen.dart';
import 'movimientos/ventas/clientes/clientes_screen.dart';
import 'movimientos/ventas/ventas_screen.dart';
import 'proveedores/proveedores_screen.dart';
import 'sucursal/mostrar_sucursales.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sistema Dycris',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const CustomNavigationBar(
        child: UsuariosScreen(),
      ),
    );
  }
}

class CustomNavigationBar extends StatefulWidget {
  final Widget child; // Contenido principal de la pantalla
  const CustomNavigationBar({super.key, required this.child});

  @override
  _CustomNavigationBarState createState() => _CustomNavigationBarState();
}

class _CustomNavigationBarState extends State<CustomNavigationBar> {
  bool _isExpanded = false; // Estado inicial: contraído
  String? _selectedRoute; // Ruta seleccionada actualmente

  // Lista de opciones del menú con título, ícono y pantalla asociada
  final List<Map<String, dynamic>> _menuItems = [
    {
      'title': 'Usuarios',
      'icon': Icons.group,
      'screen': const UsuariosScreen()
    },
    {
      'title': 'Empleados',
      'icon': Icons.work,
      'screen': const EmpleadosScreen()
    },
    {
      'title': 'Inventario',
      'icon': Icons.inventory_2,
      'screen': InventarioScreen()
    },
    {
      'title': 'Proveedores',
      'icon': Icons.person_remove_rounded,
      'screen': const ProveedoresScreen()
    },
    {
      'title': 'Categorías',
      'icon': Icons.category,
      'screen': ListaCategorias()
    },
    {'title': 'Sucursales', 'icon': Icons.store, 'screen': MostrarSucursales()},
    {
      'title': 'Desplegar Facturación',
      'icon': Icons.swap_horiz,
      'screen': const MovimientosScreen(),
      'subItems': [
        {
          'title': 'Facturación',
          'icon': Icons.shopping_cart,
          'screen': MovimientosScreen()
        },
        {
          'title': 'Ventas',
          'icon': Icons.shopping_cart,
          'screen': VentasScreen()
        },
        {
          'title': 'Clientes',
          'icon': Icons.people_outline,
          'screen': ClientesScreen()
        },
        {
          'title': 'Traslados',
          'icon': Icons.local_shipping,
          'screen': TrasladosScreen()
        },
        {'title': 'Ofertas', 'icon': Icons.discount, 'screen': OfertasScreen()},
        {
          'title': 'Compras',
          'icon': Icons.shopping_bag,
          'screen': const ComprasScreen()
        },
        {
          'title': 'Salidas',
          'icon': Icons.exit_to_app,
          'screen': const SalidasScreen()
        },
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: _isExpanded ? 250 : 70, // Expande de 70px a 250px
            color: Theme.of(context).colorScheme.primary.withOpacity(0.9),
            child: Column(
              children: [
                // Botón de expansión/contracción
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: IconButton(
                    icon: Icon(
                      _isExpanded ? Icons.chevron_left : Icons.menu,
                      color: Colors.white,
                    ),
                    onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: _menuItems.map((item) {
                      final hasSubItems = item['subItems'] != null;
                      return _buildMenuItem(
                        title: item['title'],
                        icon: item['icon'],
                        screen: item['screen'],
                        subItems: hasSubItems
                            ? item['subItems'] as List<Map<String, dynamic>>
                            : null,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          // Contenido principal de la pantalla
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required String title,
    required IconData icon,
    required Widget screen,
    List<Map<String, dynamic>>? subItems,
  }) {
    final isSelected = _selectedRoute == title;
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.white, size: 24),
          title: _isExpanded
              ? Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                )
              : null,
          selected: isSelected,
          selectedTileColor: Colors.white.withOpacity(0.2),
          onTap: () {
            setState(() => _selectedRoute = title);
            if (subItems == null) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => screen),
              );
            }
          },
        ),
        if (_isExpanded &&
            subItems != null &&
            _selectedRoute ==
                title) // Mostrar submenú si está expandido y seleccionado
          Padding(
            padding: const EdgeInsets.only(left: 20.0),
            child: Column(
              children: subItems.map((subItem) {
                final isSubSelected = _selectedRoute == subItem['title'];
                return ListTile(
                  leading:
                      Icon(subItem['icon'], color: Colors.white70, size: 20),
                  title: Text(
                    subItem['title'],
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  selected: isSubSelected,
                  selectedTileColor: Colors.white.withOpacity(0.1),
                  onTap: () {
                    setState(() => _selectedRoute = subItem['title']);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => subItem['screen']),
                    );
                  },
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
