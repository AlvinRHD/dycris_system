import 'package:flutter/material.dart';
import 'traslados/traslados_screen.dart';
import 'compras_screen.dart';
import 'salidas_screen.dart';
import 'ofertas/ofertas_screen.dart';
import 'ventas/ventas_screen.dart';

import 'ventas/clientes/clientes_screen.dart'; // Para navegar a ClientesScreen
import 'ventas/clientes/clientes_api.dart'; // Para usar ClientesApi

import '../navigation_bar.dart';

class MovimientosScreen extends StatefulWidget {
  const MovimientosScreen({super.key});

  @override
  _MovimientosScreenState createState() => _MovimientosScreenState();
}

class _MovimientosScreenState extends State<MovimientosScreen> {
  int _totalClientes = 0; // Nueva variable

  @override
  void initState() {
    super.initState();
    _cargarTotalClientes(); // Cargar total al iniciar
  }

  // Nueva función para obtener el total de clientes
  Future<void> _cargarTotalClientes() async {
    try {
      final response = await ClientesApi().getClientes(page: 1, limit: 10);
      setState(() {
        _totalClientes = response['total'];
      });
    } catch (e) {
      debugPrint("Error cargando total de clientes: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CustomNavigationBar(
        child: Scaffold(
      appBar: AppBar(
        title: const Text('Movimientos'),
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;

            return GridView.count(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildMovimientoCard(
                  context: context,
                  title: 'Ventas',
                  icon: Icons.shopping_cart,
                  color: colorScheme.primary,
                  screen: VentasScreen(),
                ),
                _buildMovimientoCard(
                  context: context,
                  title: 'Traslados',
                  icon: Icons.local_shipping,
                  color: colorScheme.secondary,
                  screen: TrasladosScreen(),
                ),
                _buildMovimientoCard(
                  context: context,
                  title: 'Compras',
                  icon: Icons.shopping_bag,
                  color: colorScheme.tertiary,
                  screen: const ComprasScreen(),
                ),
                _buildMovimientoCard(
                  context: context,
                  title: 'Salidas',
                  icon: Icons.exit_to_app,
                  color: Colors.orange,
                  screen: const SalidasScreen(),
                ),
                _buildMovimientoCard(
                  context: context,
                  title: 'Ofertas',
                  icon: Icons.discount,
                  color: Colors.purple,
                  screen: OfertasScreen(),
                ),
                _buildMovimientoCard(
                  context: context,
                  title: '$_totalClientes\nClientes',
                  icon: Icons.people_outline,
                  color: Colors.purple,
                  screen: ClientesScreen(),
                ),
              ],
            );
          },
        ),
      ),
    ));
  }

  Widget _buildMovimientoCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required Widget screen,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
        child: Card(
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 32, color: color),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
