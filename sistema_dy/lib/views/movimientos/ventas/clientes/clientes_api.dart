import 'dart:convert';
import 'package:http/http.dart' as http;

class ClientesApi {
  static const String baseUrl = 'http://localhost:3000/api';

  Future<Map<String, dynamic>> getClientes(
      {int page = 1, int limit = 10}) async {
    final response =
        await http.get(Uri.parse('$baseUrl/clientes?page=$page&limit=$limit'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Error al obtener clientes');
  }

  Future<void> addCliente(Map<String, dynamic> cliente) async {
    final response = await http.post(
      Uri.parse('$baseUrl/clientes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(cliente),
    );
    if (response.statusCode != 201) {
      throw Exception('Error al agregar cliente: ${response.body}');
    }
  }

  Future<void> updateCliente(int id, Map<String, dynamic> datos) async {
    final response = await http.put(
      Uri.parse('$baseUrl/clientes/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(datos),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar cliente: ${response.body}');
    }
  }

  Future<void> deleteCliente(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/clientes/$id'));
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar cliente: ${response.body}');
    }
  }

  Future<List<dynamic>> getHistorial(int clienteId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/clientes/$clienteId/historial'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Error al cargar historial');
  }
}
