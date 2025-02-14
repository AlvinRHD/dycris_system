import 'dart:convert';
import 'package:http/http.dart' as http;
import 'traslados_model.dart';

class TrasladosService {
  final String baseUrl = 'http://localhost:3000/api/traslados';

  Future<List<Traslado>> obtenerTraslados() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      return jsonResponse
          .map((traslado) => Traslado.fromJson(traslado))
          .toList();
    } else {
      throw Exception('Error al cargar los traslados');
    }
  }

  Future<List<Traslado>> filtrarTrasladosPorFecha(String fecha) async {
    final response = await http.get(Uri.parse('$baseUrl/filtrar?fecha=$fecha'));
    if (response.statusCode == 200) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      return jsonResponse
          .map((traslado) => Traslado.fromJson(traslado))
          .toList();
    } else {
      throw Exception('Error al filtrar los traslados por fecha');
    }
  }

  Future<void> agregarTraslado(Traslado traslado) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(traslado.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('Error al agregar el traslado');
    }
  }

  Future<void> actualizarTraslado(Traslado traslado) async {
    final response = await http.put(
      Uri.parse('$baseUrl/${traslado.id}'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(traslado.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al actualizar el traslado');
    }
  }

  Future<void> eliminarTraslado(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));

    if (response.statusCode != 200) {
      throw Exception('Error al eliminar el traslado');
    }
  }
}
