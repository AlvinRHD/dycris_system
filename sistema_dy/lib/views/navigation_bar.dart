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

/// Aplicación principal con tema Material 3 y paleta de colores claros.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Colores base
    const Color primaryColor = Color(0xFF2A2D3E);
    const Color darkText = Color(0xFF3C3C3C);
    const Color scaffoldBg = Color(0xFFF8F9FA);
    const Color white = Color(0xFFFFFFFF);

    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: scaffoldBg,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        surface: white,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(
          fontSize: 14,
          color: darkText,
          fontFamily: 'Roboto',
          letterSpacing: 0.5,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: scaffoldBg,
        elevation: 0,
        iconTheme: IconThemeData(color: darkText),
      ),
      cardTheme: CardTheme(
        color: white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
        shadowColor: Colors.black54,
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sistema Dycris - Minimal',
      theme: baseTheme,
      home: const CustomNavigationBar(child: UsuariosScreen()),
      routes: {
        '/usuarios': (context) => const UsuariosScreen(),
        '/empleados': (context) => const EmpleadosScreen(),
      },
    );
  }
}

/// Barra lateral con animaciones avanzadas para desplegarse y efectos de hover.
/// El botón (con ícono) permite expandir o contraer la barra sin logotipo ni texto extra.
class CustomNavigationBar extends StatefulWidget {
  final Widget child; // Contenido principal

  const CustomNavigationBar({super.key, required this.child});

  @override
  State<CustomNavigationBar> createState() => _CustomNavigationBarState();
}

class _CustomNavigationBarState extends State<CustomNavigationBar> {
  bool _isExpanded = false;
  String? _selectedRoute; // Controla el ítem seleccionado

  // Opciones del menú (algunos con subítems).
  final List<Map<String, dynamic>> _menuItems = [
    {
      'title': 'Usuarios',
      'icon': Icons.group,
      'screen': const UsuariosScreen(),
    },
    {
      'title': 'Empleados',
      'icon': Icons.work,
      'screen': const EmpleadosScreen(),
    },
    {
      'title': 'Inventario',
      'icon': Icons.inventory_2,
      'screen': InventarioScreen(),
    },
    {
      'title': 'Proveedores',
      'icon': Icons.person_remove_rounded,
      'screen': const ProveedoresScreen(),
    },
    {
      'title': 'Categorías',
      'icon': Icons.category,
      'screen': ListaCategorias(),
    },
    {
      'title': 'Sucursales',
      'icon': Icons.store,
      'screen': MostrarSucursales(),
    },
    {
      'title': 'Facturación',
      'icon': Icons.swap_horiz,
      'screen': const MovimientosScreen(),
      'subItems': [
        {
          'title': 'Facturación',
          'icon': Icons.shopping_cart,
          'screen': MovimientosScreen(),
        },
        {
          'title': 'Ventas',
          'icon': Icons.shopping_cart,
          'screen': VentasScreen(),
        },
        {
          'title': 'Clientes',
          'icon': Icons.people_outline,
          'screen': ClientesScreen(),
        },
        {
          'title': 'Traslados',
          'icon': Icons.local_shipping,
          'screen': TrasladosScreen(),
        },
        {
          'title': 'Ofertas',
          'icon': Icons.discount,
          'screen': OfertasScreen(),
        },
        {
          'title': 'Compras',
          'icon': Icons.shopping_bag,
          'screen': const ComprasScreen(),
        },
        {
          'title': 'Salidas',
          'icon': Icons.exit_to_app,
          'screen': const SalidasScreen(),
        },
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Colores claros.
    const Color sidebarBg = Color(0xFFF8F9FA);
    const Color textColor = Color(0xFF3C3C3C);
    final Color dividerColor = Colors.grey.shade300;
    const Duration duration = Duration(milliseconds: 300);

    return Scaffold(
      body: Row(
        children: [
          AnimatedContainer(
            duration: duration,
            curve: Curves.easeInOut,
            width: _isExpanded ? 240 : 70,
            height: double.infinity,
            decoration: BoxDecoration(
              color: sidebarBg,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                // Botón para expandir/contraer la barra.
                Container(
                  height: 60,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    icon: AnimatedRotation(
                      turns: _isExpanded ? 0.0 : 0.25,
                      duration: duration,
                      child: Icon(
                        _isExpanded ? Icons.chevron_left : Icons.dashboard,
                        color: textColor,
                        size: 26,
                      ),
                    ),
                  ),
                ),
                Divider(color: dividerColor, height: 1),
                // Lista de ítems del menú.
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: _menuItems.length,
                    itemBuilder: (context, index) {
                      final item = _menuItems[index];
                      final bool hasSubItems = item['subItems'] != null;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MainMenuItemWidget(
                            title: item['title'],
                            icon: item['icon'],
                            isExpanded: _isExpanded,
                            isSelected: _selectedRoute == item['title'],
                            hasSubItems: hasSubItems,
                            onTap: () {
                              setState(() {
                                if (hasSubItems) {
                                  _selectedRoute =
                                      _selectedRoute == item['title']
                                          ? null
                                          : item['title'];
                                } else {
                                  _selectedRoute = item['title'];
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => item['screen'],
                                    ),
                                  );
                                }
                              });
                            },
                          ),
                          if (_isExpanded &&
                              hasSubItems &&
                              _selectedRoute == item['title'])
                            Column(
                              children: (item['subItems']
                                      as List<Map<String, dynamic>>)
                                  .map(
                                    (subItem) => SubMenuItemWidget(
                                      title: subItem['title'],
                                      icon: subItem['icon'],
                                      isSelected:
                                          _selectedRoute == subItem['title'],
                                      onTap: () {
                                        setState(() {
                                          _selectedRoute = subItem['title'];
                                        });
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => subItem['screen'],
                                          ),
                                        );
                                      },
                                      parentExpanded: _isExpanded,
                                    ),
                                  )
                                  .toList(),
                            ),
                          if (_isExpanded)
                            Divider(color: dividerColor, height: 1),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Contenido principal.
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}

/// Ítem del menú principal con animaciones de hover, traslación y escalado.
class MainMenuItemWidget extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool isExpanded;
  final bool isSelected;
  final bool hasSubItems;
  final VoidCallback onTap;

  const MainMenuItemWidget({
    super.key,
    required this.title,
    required this.icon,
    required this.isExpanded,
    required this.isSelected,
    required this.hasSubItems,
    required this.onTap,
  });

  @override
  State<MainMenuItemWidget> createState() => _MainMenuItemWidgetState();
}

class _MainMenuItemWidgetState extends State<MainMenuItemWidget> {
  bool _isHovered = false;
  final Duration duration = const Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    const Color textColor = Color(0xFF3C3C3C);
    final Color hoverBg = Colors.grey.shade200;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: duration,
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? Colors.blue.shade50
                : (_isHovered ? hoverBg : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: TweenAnimationBuilder<Offset>(
            tween: Tween<Offset>(
              begin: Offset.zero,
              end: _isHovered ? const Offset(5, 0) : Offset.zero,
            ),
            duration: duration,
            builder: (context, offset, child) {
              return Transform.translate(
                offset: offset,
                child: child,
              );
            },
            child: Row(
              // Usa MainAxisSize.min en modo contraído para ocupar solo lo necesario.
              mainAxisSize:
                  widget.isExpanded ? MainAxisSize.max : MainAxisSize.min,
              children: [
                // Indicador lateral para el ítem seleccionado.
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: widget.isSelected ? textColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                widget.isExpanded
                    ? Icon(widget.icon, color: textColor, size: 24)
                    : Tooltip(
                        message: widget.title,
                        child: Icon(widget.icon, color: textColor, size: 24),
                      ),
                if (widget.isExpanded) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return AnimatedDefaultTextStyle(
                          duration: duration,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: widget.isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            letterSpacing: _isHovered ? 1.0 : 0.5,
                          ),
                          child: ConstrainedBox(
                            constraints:
                                BoxConstraints(maxWidth: constraints.maxWidth),
                            child: Text(
                              widget.title,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (widget.hasSubItems)
                    Icon(
                      widget.isSelected
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: textColor,
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ítem del submenú con animaciones de hover, traslación y escalado.
class SubMenuItemWidget extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool parentExpanded;

  const SubMenuItemWidget({
    super.key,
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.parentExpanded,
  });

  @override
  State<SubMenuItemWidget> createState() => _SubMenuItemWidgetState();
}

class _SubMenuItemWidgetState extends State<SubMenuItemWidget> {
  bool _isHovered = false;
  final Duration duration = const Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    const Color textColor = Color(0xFF3C3C3C);
    final Color hoverBg = Colors.grey.shade200;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: duration,
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? Colors.blue.shade50.withOpacity(0.7)
                : (_isHovered ? hoverBg : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: TweenAnimationBuilder<Offset>(
            tween: Tween<Offset>(
              begin: Offset.zero,
              end: _isHovered ? const Offset(5, 0) : Offset.zero,
            ),
            duration: duration,
            builder: (context, offset, child) {
              return Transform.translate(
                offset: offset,
                child: child,
              );
            },
            child: Row(
              mainAxisSize:
                  widget.parentExpanded ? MainAxisSize.max : MainAxisSize.min,
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: widget.isSelected ? textColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                widget.parentExpanded
                    ? Icon(widget.icon,
                        color: textColor.withOpacity(0.9), size: 20)
                    : Tooltip(
                        message: widget.title,
                        child: Icon(widget.icon,
                            color: textColor.withOpacity(0.9), size: 20),
                      ),
                if (widget.parentExpanded) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return AnimatedDefaultTextStyle(
                          duration: duration,
                          style: TextStyle(
                            // ignore: deprecated_member_use
                            color: textColor.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: widget.isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            letterSpacing: _isHovered ? 1.0 : 0.5,
                          ),
                          child: ConstrainedBox(
                            constraints:
                                BoxConstraints(maxWidth: constraints.maxWidth),
                            child: Text(
                              widget.title,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
