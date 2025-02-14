import 'dart:convert';
import 'package:http/http.dart' as http;

class VentasController {
  final String baseUrl = 'http://localhost:3000/api/ventas';

  // Obtener todas las ventas
  Future<List<dynamic>> obtenerVentas() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al cargar las ventas');
    }
  }

  // Agregar una nueva venta
  Future<void> agregarVenta(Map<String, dynamic> nuevaVenta) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(nuevaVenta),
    );

    if (response.statusCode != 201) {
      throw Exception('Error al agregar la venta');
    }
  }

  // Actualizar una venta
  Future<void> actualizarVenta(int id, Map<String, dynamic> datos) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "direccion_cliente": datos["direccion_cliente"],
        "descripcion_compra": datos["descripcion_compra"],
        "tipo_factura": datos["tipo_factura"],
        "metodo_pago": datos["metodo_pago"]
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error: ${jsonDecode(response.body)["message"]}');
    }
  }

  // Eliminar una venta
  Future<void> eliminarVenta(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));

    if (response.statusCode != 200) {
      throw Exception('Error al eliminar la venta');
    }
  }
}
