import 'package:flutter/material.dart';

import 'views/home_screen.dart';
import 'views/login/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sistema de Inventario',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/login', // Ruta inicial apuntando a login
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const DashboardScreen(
              userData: {},
            ),
      },
    );
  }
}
