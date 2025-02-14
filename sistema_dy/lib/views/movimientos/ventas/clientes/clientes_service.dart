import 'dart:convert';
import 'package:http/http.dart' as http;
import 'clientes_model.dart';

class ClientesService {
  final String baseUrl = 'http://localhost:3000/api/clientes';

  Future<List<Cliente>> obtenerClientes() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      return jsonResponse.map((cliente) => Cliente.fromJson(cliente)).toList();
    } else {
      throw Exception('Error al cargar clientes');
    }
  }

  Future<void> agregarCliente(Cliente cliente) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(cliente.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('Error al agregar cliente');
    }
  }

  Future<void> actualizarCliente(Cliente cliente) async {
    final response = await http.put(
      Uri.parse('$baseUrl/${cliente.idCliente}'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(cliente.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al actualizar cliente');
    }
  }

  Future<void> eliminarCliente(int idCliente) async {
    final response = await http.delete(Uri.parse('$baseUrl/$idCliente'));

    if (response.statusCode != 200) {
      throw Exception('Error al eliminar cliente');
    }
  }
}
