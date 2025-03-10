import 'dart:convert';
import 'package:http/http.dart' as http;

class TrasladosApi {
  static const String baseUrl = 'http://localhost:3000/api';

  Future<Map<String, dynamic>> getTraslados({
    String? searchQuery,
    String? sucursalOrigen,
    int page = 1,
    int limit = 10,
  }) async {
    String url = '$baseUrl/traslados?page=$page&limit=$limit';
    if (searchQuery != null || sucursalOrigen != null) {
      url += '&';
      List<String> params = [];
      if (searchQuery != null && searchQuery.isNotEmpty)
        params.add('search=$searchQuery');
      if (sucursalOrigen != null)
        params.add('codigo_sucursal_origen=$sucursalOrigen');
      url += params.join('&');
    }
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'traslados': (data['traslados'] as List)
            .map((t) => t as Map<String, dynamic>)
            .map((t) => {
                  ...t,
                  'productos': (t['productos'] as List)
                      .map((p) => p as Map<String, dynamic>)
                      .map((p) => {
                            'codigo_inventario':
                                p['codigo_inventario'] as String,
                            'cantidad': p['cantidad'] as int,
                            'producto_nombre': p['producto_nombre'] as String,
                            'numero_motor': p['numero_motor'] as String?,
                            'numero_chasis': p['numero_chasis'] as String?,
                            'descripcion': p['descripcion'] as String?,
                          })
                      .toList(),
                })
            .toList(),
        'total': data['total'] as int,
      };
    }
    throw Exception('Error al cargar traslados');
  }

  Future<void> addTraslado(Map<String, dynamic> traslado) async {
    final response = await http.post(
      Uri.parse('$baseUrl/traslados'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(traslado),
    );
    if (response.statusCode != 201) {
      throw Exception('Error al agregar traslado: ${response.body}');
    }
  }

  Future<void> updateTraslado(int id, Map<String, dynamic> datos) async {
    final response = await http.put(
      Uri.parse('$baseUrl/traslados/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(datos),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar traslado: ${response.body}');
    }
  }

  Future<void> deleteTraslado(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/traslados/$id'));
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar traslado: ${response.body}');
    }
  }

  Future<List<dynamic>> searchProductos(String? query) async {
    String url = '$baseUrl/buscar-inventario';
    if (query != null && query.isNotEmpty) url += '?nombre=$query';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Error al buscar productos');
  }

  Future<List<dynamic>> getSucursales() async {
    final response = await http.get(Uri.parse('$baseUrl/traslados/sucursales'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Error al cargar sucursales: ${response.body}');
  }

  Future<List<dynamic>> getHistorial(int trasladoId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/traslados/$trasladoId/historial'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Error al cargar historial');
  }
}
