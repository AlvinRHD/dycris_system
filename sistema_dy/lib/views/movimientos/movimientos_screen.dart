import 'package:flutter/material.dart';
import 'traslados/traslados_screen.dart';
import 'compras_screen.dart';
import 'salidas_screen.dart';
import 'ofertas/ofertas_screen.dart';
import 'ventas/ventas_screen.dart';

class MovimientosScreen extends StatelessWidget {
  const MovimientosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Movimientos')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Ventas'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => VentasScreen()),
              );
            },
          ),
          ListTile(
            title: const Text('Traslados'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TrasladosScreen()),
              );
            },
          ),
          ListTile(
            title: const Text('Compras'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ComprasScreen()),
              );
            },
          ),
          ListTile(
            title: const Text('Salidas'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SalidasScreen()),
              );
            },
          ),
          ListTile(
            title: const Text('Ofertas'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => OfertasScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
