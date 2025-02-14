import 'dart:convert';
import 'package:http/http.dart' as http;

import 'product_model.dart';

/// Controlador para gestionar operaciones de inventario mediante API REST
class InventoryController {
  static const String _baseUrl = "http://localhost:3000/api/inventario";

  /// Obtener URI base para operaciones CRUD
  Uri get _baseUri => Uri.parse(_baseUrl);

  /// Cargar lista de productos desde el servidor
  Future<List<Product>> loadProducts() async {
    try {
      final response = await http.get(_baseUri);

      if (response.statusCode == 200) {
        final decodedBody = json.decode(utf8.decode(response.bodyBytes));

        if (decodedBody is! List) {
          throw const FormatException(
              "Respuesta inválida: Se esperaba una lista");
        }

        return decodedBody.map<Product>((item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException(
                "Formato inválido: Item no es un mapa válido");
          }
          return Product.fromJson(item);
        }).toList();
      } else {
        throw http.ClientException(
            "Error al cargar productos: ${response.statusCode}", _baseUri);
      }
    } on FormatException catch (e) {
      print("Error de formato: $e");
      throw Exception("Error en formato de datos del servidor");
    } catch (e) {
      print("Error de conexión: $e");
      throw Exception("No se pudo conectar con el servidor");
    }
  }

  /// Agregar un nuevo producto al inventario
  Future<void> addProduct(Product product) async {
    try {
      final response = await http.post(
        _baseUri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(product.toJson()),
      );

      if (response.statusCode != 201) {
        throw http.ClientException(
            "Error al crear producto: ${response.statusCode}", _baseUri);
      }
    } catch (e) {
      print("Error inesperado al crear producto: $e");
      throw Exception("Error desconocido al crear producto");
    }
  }

  Future<Product> getProductById(String productId) async {
    try {
      final response = await http.get(Uri.parse("$_baseUrl/$productId"));

      if (response.statusCode == 200) {
        final decodedBody = json.decode(utf8.decode(response.bodyBytes));

        if (decodedBody is! Map<String, dynamic>) {
          throw const FormatException(
              "Respuesta inválida: Se esperaba un objeto");
        }

        return Product.fromJson(decodedBody);
      } else {
        throw http.ClientException(
            "Error al obtener producto: ${response.statusCode}",
            Uri.parse("$_baseUrl/$productId"));
      }
    } on FormatException catch (e) {
      print("Error de formato: $e");
      throw Exception("Error en formato de datos del servidor");
    } catch (e) {
      print("Error de conexión: $e");
      throw Exception("No se pudo conectar con el servidor");
    }
  }

  /// Actualizar un producto existente
  Future<void> updateProduct(String id, Product product) async {
    try {
      final response = await http.put(
        Uri.parse("$_baseUrl/$id"), // Aquí se usa el ID en la URL
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(product.toJson()), // Aquí pasas los datos actualizados
      );

      if (response.statusCode != 200) {
        throw http.ClientException(
            "Error al actualizar: ${response.statusCode}",
            Uri.parse("$_baseUrl/$id"));
      }
    } catch (e) {
      print("Error de actualización: $e");
      throw Exception("Error al actualizar producto");
    }
  }

  /// Eliminar un producto del inventario
  Future<void> deleteProduct(String id) async {
    try {
      final deleteUri = Uri.parse("$_baseUrl/$id");
      final response = await http.delete(deleteUri);

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw http.ClientException(
            "Error al eliminar: ${response.statusCode}", deleteUri);
      }
    } catch (e) {
      print("Error al eliminar producto: $e");
      throw Exception("No se pudo eliminar el producto");
    }
  }
}
