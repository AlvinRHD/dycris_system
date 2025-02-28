import 'dart:convert';
import 'package:http/http.dart' as http;

class VentaApiTemporal {
  static const String baseUrl = 'http://localhost:3000/api';

  // Asignar una venta a una sucursal manualmente
  Future<void> asignarSucursalManual(int ventaId, String sucursalNombre) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ventas/sucursal-manual'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'venta_id': ventaId,
        'sucursal_nombre': sucursalNombre,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Error al asignar sucursal: ${response.body}');
    }
  }

  // Obtener todas las asignaciones de sucursales manuales
  Future<List<dynamic>> getAsignacionesManuales() async {
    final response =
        await http.get(Uri.parse('$baseUrl/ventas/sucursal-manual'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Error al cargar asignaciones manuales: ${response.body}');
  }

  // Obtener sucursales disponibles (reutilizamos traslados/sucursales)
  Future<List<dynamic>> getSucursales() async {
    final response = await http.get(Uri.parse('$baseUrl/traslados/sucursales'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Error al cargar sucursales: ${response.body}');
  }
}
