import 'dart:convert';
import 'package:http/http.dart' as http;

class VentaApi {
  static const String baseUrl = 'http://localhost:3000/api';

  Future<Map<String, dynamic>> getVentas({int page = 1, int limit = 10}) async {
    final response =
        await http.get(Uri.parse('$baseUrl/ventas?page=$page&limit=$limit'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error al cargar ventas');
  }

  Future<Map<String, dynamic>> addVenta(Map<String, dynamic> venta) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ventas'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(venta),
    );
    if (response.statusCode == 201) return jsonDecode(response.body);
    throw Exception('Error al agregar venta: ${response.body}');
  }

  Future<void> updateVenta(int id, Map<String, dynamic> datos) async {
    final response = await http.put(
      Uri.parse('$baseUrl/ventas/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(datos),
    );
    if (response.statusCode != 200)
      throw Exception('Error al actualizar venta: ${response.body}');
  }

  Future<void> deleteVenta(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/ventas/$id'));
    if (response.statusCode != 200)
      throw Exception('Error al eliminar venta: ${response.body}');
  }

  Future<List<dynamic>> getHistorial(int ventaId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/ventas/$ventaId/historial'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error al cargar historial');
  }

  Future<List<dynamic>> searchProductos(
      {String? codigo, String? nombre}) async {
    String url = '$baseUrl/buscar-inventario';
    List<String> params = [];
    if (codigo != null && codigo.isNotEmpty)
      params.add('nombre=$codigo');
    else if (nombre != null && nombre.isNotEmpty) params.add('nombre=$nombre');
    if (params.isNotEmpty) url += '?' + params.join('&');
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error al buscar productos');
  }

  Future<List<dynamic>> searchClientes(String query) async {
    final response = await http.get(Uri.parse('$baseUrl/clientes?q=$query'));
    if (response.statusCode == 200)
      return jsonDecode(response.body)['clientes'];
    throw Exception('Error al buscar clientes');
  }

  Future<bool> autorizarDescuento(String codigo) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ventas/autorizar-descuento'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'codigo': codigo}),
    );
    if (response.statusCode == 200)
      return jsonDecode(response.body)['autorizado'];
    throw Exception('Error al verificar código');
  }

  Future<List<dynamic>> getEmpleados() async {
    final response = await http.get(Uri.parse('$baseUrl/empleados'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error al cargar empleados');
  }

  Future<double> getTotalVentasPorApertura(int aperturaId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/ventas?apertura_id=$aperturaId'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final ventas = data['ventas'] as List;
      return ventas.fold<double>(
        0.0,
        (sum, venta) =>
            sum + (double.tryParse(venta['total'].toString()) ?? 0.0),
      );
    }
    throw Exception('Error al calcular total de ventas');
  }

  Future<Map<String, dynamic>> addClientePaso(String nombre,
      {String? fecha_inicio}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/clientes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'fecha_inicio':
            fecha_inicio ?? DateTime.now().toIso8601String().split('T')[0],
        'tipo_cliente':
            'Cliente de Paso', // Indicamos que es un cliente de paso
      }),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al agregar cliente de paso: ${response.body}');
    }
  }
}
