import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../home_screen.dart';

// Configurar Logger
final Logger logger = Logger(
  printer: PrettyPrinter(),
);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordFocusNode = FocusNode();

  String _usuario = '';
  String _password = '';
  bool _obscureText = true;
  bool _isLoading = false;

  // Colores base de la paleta
  final Color accentColor = const Color(0xFF2A2D3E);
  final Color baseGrey = Colors.grey[200]!;

  // Derivaciones y variaciones basadas en la paleta
  final Color outerGradientStart = Colors
      .grey[300]!; // Un gris un poco más oscuro para el gradiente exterior
  late final Color outerGradientEnd = baseGrey;
  late final Color cardBackgroundColor = baseGrey;
  late final Color cardBorderColor =
      accentColor.withOpacity(0.3); // Sutil borde derivado del tono oscuro
  late final Color welcomeGradientStart =
      const Color(0xFF484B5C); // Versión más clara derivada de accentColor
  late final Color welcomeGradientEnd = accentColor; // Tono oscuro base

  // En este caso, usaremos el mismo color oscuro para inputs y etiquetas
  late final Color inputColor = accentColor;

  @override
  void dispose() {
    _passwordFocusNode.dispose();
    super.dispose();
  }

  /// Lógica de inicio de sesión
  void _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });
      final userData = await autenticarUsuario(_usuario, _password);
      setState(() {
        _isLoading = false;
      });
      if (userData != null) {
        if (!kReleaseMode) {
          logger.d("Inicio de sesión exitoso para: ${userData['usuario']}");
        }
        // Mostrar modal y redirigir al home tan pronto se toque o transcurran 2 segundos
        await _showSuccessDialog();
        // ignore: use_build_context_synchronously
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => DashboardScreen(userData: userData)),
        );
      } else {
        if (!kReleaseMode) {
          logger.w("Intento de inicio de sesión fallido");
        }
        await _showErrorDialog();
      }
    }
  }

  Future<void> _showSuccessDialog() async {
    // Se utiliza Future.any para que, si el usuario toca (lo que cierra el modal) o pasan 2 segundos, se complete.
    await Future.any([
      showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (context) => GestureDetector(
          // Cualquier toque dentro del modal cierra el dialog
          onTap: () => Navigator.of(context, rootNavigator: true).pop(),
          child: AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.check_circle, color: Colors.green, size: 52),
                SizedBox(height: 16),
                Text('Inicio de sesión exitoso', textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
      Future.delayed(const Duration(seconds: 2)),
    ]);
    // Si el dialog aún está abierto, se cierra.
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> _showErrorDialog() async {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.error, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text('Usuario o contraseña incorrectos',
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
    await Future.delayed(const Duration(seconds: 1));
    Navigator.of(context, rootNavigator: true).pop();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: inputColor),
      prefixIcon: Icon(icon, color: inputColor),
      filled: true,
      fillColor: Colors.grey[200],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: inputColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: inputColor.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: accentColor, width: 2),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Expanded(
      flex: 2,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              welcomeGradientStart,
              welcomeGradientEnd,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shopping_cart, color: Colors.white, size: 80),
                const SizedBox(height: 16),
                const Text(
                  'Bienvenido',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Inicia sesión para continuar',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Expanded(
      flex: 3,
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 350),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: inputColor.withOpacity(0.1),
                    child: Icon(Icons.person, size: 50, color: inputColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Iniciar Sesión',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) => FocusScope.of(context)
                              .requestFocus(_passwordFocusNode),
                          decoration:
                              _buildInputDecoration('Usuario', Icons.person),
                          onChanged: (value) => _usuario = value,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Ingrese su usuario'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          focusNode: _passwordFocusNode,
                          textInputAction: TextInputAction.done,
                          obscureText: _obscureText,
                          decoration:
                              _buildInputDecoration('Contraseña', Icons.lock)
                                  .copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: inputColor,
                              ),
                              onPressed: _togglePasswordVisibility,
                            ),
                          ),
                          onChanged: (value) => _password = value,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Ingrese su contraseña'
                              : null,
                          onFieldSubmitted: (_) => _login(),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: accentColor,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 50, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 5,
                            ),
                            child: Text(
                              'Iniciar Sesión',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: accentColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    outerGradientStart,
                    outerGradientEnd,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    bool isMobile = constraints.maxWidth < 700;
                    return Container(
                      constraints: const BoxConstraints(
                        maxWidth: 900,
                        maxHeight: 500,
                      ),
                      decoration: BoxDecoration(
                        color: cardBackgroundColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cardBorderColor, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26.withOpacity(0.1),
                            offset: const Offset(0, 10),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: isMobile
                          ? Column(
                              children: [
                                _buildWelcomeSection(),
                                _buildLoginForm(),
                              ],
                            )
                          : Row(
                              children: [
                                _buildWelcomeSection(),
                                _buildLoginForm(),
                              ],
                            ),
                    );
                  },
                ),
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black45,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> autenticarUsuario(
      String usuario, String password) async {
    try {
      // Si usas emulador Android, reemplaza 'localhost' por '10.0.2.2'
      final response = await http.post(
        Uri.parse('http://localhost:3000/login'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({'usuario': usuario, 'password': password}),
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', responseData['token']);
          if (!kReleaseMode) {
            logger.d("Usuario autenticado: ${responseData['user']['usuario']}");
          }
          return responseData['user'];
        }
      }
      return null;
    } catch (e) {
      if (!kReleaseMode) {
        logger.e("Error al autenticar: $e");
      }
      return null;
    }
  }
}
