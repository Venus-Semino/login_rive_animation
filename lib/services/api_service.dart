import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8080';

  static Future<List<dynamic>> obtenerProductos() async {
    final response = await http.get(Uri.parse('$baseUrl/products'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is List) {
        return data;
      }

      throw Exception('La API no devolvió una lista de productos');
    }

    throw Exception('Error al obtener productos: ${response.statusCode}');
  }
}
