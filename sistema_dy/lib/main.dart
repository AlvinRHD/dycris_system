import 'package:flutter/material.dart';
import 'views/splash_screen.dart';

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
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFF2A2D3E), // Color del cursor
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
