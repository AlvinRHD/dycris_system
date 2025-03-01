import 'package:flutter/material.dart';
import 'package:sistema_dy/views/navigation_bar.dart';
import '../navigation_bar.dart';

class SalidasScreen extends StatelessWidget {
  const SalidasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomNavigationBar(
        child: Scaffold(
      appBar: AppBar(title: const Text('Salidas')),
      body: const Center(child: Text('Pantalla de Salidas')),
    ));
  }
}
