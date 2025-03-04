import 'package:http/http.dart' as http;
import 'dart:convert';

class CajasApi {
  static const String baseUrl = 'http://localhost:3000/api';

  Future<List<dynamic>> getCajasAbiertas() async {
    final response = await http.get(Uri.parse('$baseUrl/cajas'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error al cargar cajas abiertas');
  }

  Future<List<dynamic>> getTodasCajas() async {
    final response = await http.get(Uri.parse('$baseUrl/cajas/todas'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error al cargar todas las cajas');
  }

  Future<List<dynamic>> getAperturasActivas() async {
    final response = await http.get(Uri.parse('$baseUrl/aperturas_cierres'));
    if (response.statusCode == 200) {
      final aperturas = jsonDecode(response.body);
      return aperturas.where((a) => a['fecha_cierre'] == null).toList();
    }
    throw Exception('Error al cargar aperturas activas');
  }

  Future<Map<String, dynamic>> abrirCaja(
      int cajaId, int usuarioId, double montoApertura) async {
    final response = await http.post(
      Uri.parse('$baseUrl/aperturas_caja'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'caja_id': cajaId,
        'usuario_id': usuarioId,
        'monto_apertura': montoApertura
      }),
    );
    if (response.statusCode == 201) return jsonDecode(response.body);
    throw Exception('Error al abrir caja: ${response.body}');
  }

  Future<void> cerrarCaja(int aperturaId, double totalVentas,
      double efectivoEnCaja, String observaciones) async {
    final response = await http.post(
      Uri.parse('$baseUrl/cierres_caja'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'apertura_id': aperturaId,
        'total_ventas': totalVentas,
        'efectivo_en_caja': efectivoEnCaja,
        'observaciones': observaciones,
      }),
    );
    if (response.statusCode != 201)
      throw Exception('Error al cerrar caja: ${response.body}');
  }

  Future<List<dynamic>> getAperturasCierres() async {
    final response = await http.get(Uri.parse('$baseUrl/aperturas_cierres'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error al cargar aperturas y cierres');
  }

  Future<List<dynamic>> getSucursales() async {
    final response = await http.get(Uri.parse('$baseUrl/traslados/sucursales'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error al cargar sucursales');
  }

  // Nueva función para obtener la fecha de apertura
  Future<DateTime?> getFechaApertura(int aperturaId) async {
    final response = await http
        .get(Uri.parse('$baseUrl/aperturas_cierres?apertura_id=$aperturaId'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data.isNotEmpty) {
        return DateTime.parse(data[0]['fecha_apertura']);
      }
    }
    throw Exception('Error al cargar fecha de apertura');
  }

  // Nueva función para agregar una caja
  Future<Map<String, dynamic>> addCaja(
      String numeroCaja, String sucursalId, String estado) async {
    final response = await http.post(
      Uri.parse('$baseUrl/cajas'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'numero_caja': numeroCaja,
        'sucursal_id': sucursalId,
        'estado': estado,
      }),
    );
    if (response.statusCode == 201) return jsonDecode(response.body);
    throw Exception('Error al agregar caja: ${response.body}');
  }
}
