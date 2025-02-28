import 'dart:convert';
import 'package:http/http.dart' as http;

class VentaApi {
  static const String baseUrl = 'http://localhost:3000/api';

  // Obtener ventas con paginación
  Future<Map<String, dynamic>> getVentas({int page = 1, int limit = 10}) async {
    final response =
        await http.get(Uri.parse('$baseUrl/ventas?page=$page&limit=$limit'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Error al cargar ventas');
  }

  // Agregar venta
  Future<Map<String, dynamic>> addVenta(Map<String, dynamic> venta) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ventas'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(venta),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception('Error al agregar venta: ${response.body}');
  }

  // Actualizar venta
  Future<void> updateVenta(int id, Map<String, dynamic> datos) async {
    final response = await http.put(
      Uri.parse('$baseUrl/ventas/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(datos),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar venta: ${response.body}');
    }
  }

  // Eliminar venta
  Future<void> deleteVenta(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/ventas/$id'));
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar venta: ${response.body}');
    }
  }

  // Obtener historial de cambios
  Future<List<dynamic>> getHistorial(int ventaId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/ventas/$ventaId/historial'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Error al cargar historial');
  }

// Buscar productos por código o nombre usando /buscar-inventario
  Future<List<dynamic>> searchProductos(
      {String? codigo, String? nombre}) async {
    String url = '$baseUrl/buscar-inventario';
    List<String> params = [];
    if (codigo != null && codigo.isNotEmpty) {
      params
          .add('nombre=$codigo'); // Usamos "nombre" para buscar códigos también
    } else if (nombre != null && nombre.isNotEmpty) {
      params.add('nombre=$nombre');
    }
    if (params.isNotEmpty) {
      url += '?' + params.join('&');
    }
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final productos = jsonDecode(response.body);
      return productos;
    }
    throw Exception('Error al buscar productos');
  }

  // Buscar clientes
  Future<List<dynamic>> searchClientes(String query) async {
    final response = await http.get(Uri.parse('$baseUrl/clientes?q=$query'));
    if (response.statusCode == 200) {
      final clientes = jsonDecode(response.body)['clientes'];
      return clientes; // Ya viene filtrado del backend
    }
    throw Exception('Error al buscar clientes');
  }

  // Autorizar descuento
  Future<bool> autorizarDescuento(String codigo) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ventas/autorizar-descuento'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'codigo': codigo}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['autorizado'];
    }
    throw Exception('Error al verificar código');
  }

  // Obtener empleados
  Future<List<dynamic>> getEmpleados() async {
    final response = await http.get(Uri.parse('$baseUrl/empleados'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Error al cargar empleados');
  }
}
