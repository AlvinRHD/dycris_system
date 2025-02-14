import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ofertas_model.dart';

class OfertasService {
  final String baseUrl = 'http://localhost:3000/api/ofertas';

  Future<List<Oferta>> obtenerOfertas() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      return jsonResponse.map((oferta) => Oferta.fromJson(oferta)).toList();
    } else {
      throw Exception('Error al cargar las ofertas');
    }
  }

  // Obtener oferta activa por producto
  Future<Map<String, dynamic>?> obtenerOfertaPorProducto(int productoId) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/producto/$productoId'));
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse; // Retorna la oferta si existe
      } else if (response.statusCode == 404) {
        return null; // No hay oferta activa para este producto
      } else {
        throw Exception('Error al obtener la oferta');
      }
    } catch (e) {
      print("Error al obtener oferta por producto: $e");
      return null;
    }
  }

  Future<void> agregarOferta(Oferta oferta) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(oferta.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('Error al agregar la oferta');
    }
  }

  Future<void> actualizarOferta(Oferta oferta) async {
    final response = await http.put(
      Uri.parse('$baseUrl/${oferta.id}'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(oferta.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al actualizar la oferta');
    }
  }

  Future<void> eliminarOferta(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));

    if (response.statusCode != 200) {
      throw Exception('Error al eliminar la oferta');
    }
  }
}
