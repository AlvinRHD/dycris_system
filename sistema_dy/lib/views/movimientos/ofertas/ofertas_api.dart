import 'dart:convert';
import 'package:http/http.dart' as http;

class OfertasApi {
  static const String baseUrl = 'http://localhost:3000/api';

  // Obtener ofertas con filtros opcionales
  Future<Map<String, dynamic>> getOfertas(
      {int? categoriaId,
      String? searchQuery,
      String? estado,
      int page = 1,
      int limit = 10}) async {
    String url = '$baseUrl/ofertas?page=$page&limit=$limit';
    if (categoriaId != null ||
        (searchQuery != null && searchQuery.isNotEmpty) ||
        estado != null) {
      url += '&';
      List<String> params = [];
      if (categoriaId != null) params.add('categoria_id=$categoriaId');
      if (searchQuery != null && searchQuery.isNotEmpty)
        params.add('nombre=$searchQuery');
      if (estado != null) params.add('estado=$estado');
      url += params.join('&');
    }
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Error al cargar ofertas');
  }

  // Agregar oferta
  Future<void> addOferta(Map<String, dynamic> oferta) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ofertas'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(oferta),
    );
    if (response.statusCode != 201) {
      throw Exception('Error al agregar oferta: ${response.body}');
    }
  }

  // Actualizar oferta
  Future<void> updateOferta(int id, Map<String, dynamic> datos) async {
    final response = await http.put(
      Uri.parse('$baseUrl/ofertas/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(datos),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar oferta: ${response.body}');
    }
  }

  // Eliminar oferta
  Future<void> deleteOferta(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/ofertas/$id'));
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar oferta: ${response.body}');
    }
  }

  // Obtener categorías
  Future<List<dynamic>> getCategorias() async {
    final response = await http.get(Uri.parse('$baseUrl/categorias'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Error al cargar categorías');
  }

  // Buscar productos
  Future<List<dynamic>> searchProductos(
      {int? categoriaId, String? nombre}) async {
    String url = '$baseUrl/buscar-inventario';
    if (categoriaId != null || (nombre != null && nombre.isNotEmpty)) {
      url += '?';
      List<String> params = [];
      if (categoriaId != null) params.add('categoria_id=$categoriaId');
      if (nombre != null && nombre.isNotEmpty) params.add('nombre=$nombre');
      url += params.join('&');
    }
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Error al buscar productos');
  }

  // Historial de cambios de una oferta
  Future<List<dynamic>> getHistorial(int ofertaId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/ofertas/$ofertaId/historial'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Error al cargar historial');
  }
}
