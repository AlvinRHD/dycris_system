import 'package:flutter/material.dart';
import 'package:sistema_dy/views/navigation_bar.dart';
import '../navigation_bar.dart';

class ComprasScreen extends StatelessWidget {
  const ComprasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomNavigationBar(
      child: Scaffold(
        appBar: AppBar(title: const Text('Compras')),
        body: const Center(child: Text('Pantalla de Compras')),
      ),
    );
  }
}
