import 'dart:convert';
import 'package:http/http.dart' as http;

class ProductService {
  // product_service.dart
  Future<Map<String, dynamic>> obtenerProductoPorCodigo(String codigo) async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/inventario/codigo/$codigo'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      print("Error obteniendo producto: $e");
      return {};
    }
  }
}
