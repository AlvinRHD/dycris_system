import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'modulo_usuarios/login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  /// Verifica si existe un token guardado y si aún es válido.
  void _checkToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    // Si el token existe, no está vacío y no ha expirado...
    if (token != null && token.isNotEmpty && !JwtDecoder.isExpired(token)) {
      // Decodificar el token para obtener datos del usuario
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      // Redirigir al dashboard con los datos del token
      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(
          builder: (_) => DashboardScreen(userData: decodedToken),
        ),
      );
    } else {
      // Sino, redirigir al login
      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar un indicador de carga mientras se verifica el token
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
