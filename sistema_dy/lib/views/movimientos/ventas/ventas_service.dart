import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ventas_model.dart';

class VentasService {
  final String baseUrl = 'http://localhost:3000/api/ventas';

  Future<List<Venta>> obtenerVentas() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      return jsonResponse.map((venta) => Venta.fromJson(venta)).toList();
    } else {
      throw Exception('Error al cargar ventas');
    }
  }

  Future<void> agregarVenta(Venta venta) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(venta.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('Error al agregar venta');
    }
  }

  Future<void> actualizarVenta(Venta venta) async {
    final response = await http.put(
      Uri.parse('$baseUrl/${venta.idVentas}'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(venta.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al actualizar venta');
    }
  }

  Future<void> eliminarVenta(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));

    if (response.statusCode != 200) {
      throw Exception('Error al eliminar venta');
    }
  }
}
