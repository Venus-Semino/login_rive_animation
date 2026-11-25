import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/videogame.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class ApiService {
  ApiService({this.auth, http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _ownsClient = client == null,
      _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final FirebaseAuth? auth;
  final http.Client _client;
  final bool _ownsClient;
  final String _baseUrl;

  Future<http.Response> _request({required bool refreshToken}) async {
    final user = (auth ?? FirebaseAuth.instance).currentUser;
    if (user == null) {
      throw const ApiException(
        'Inicia sesión para consultar el catálogo.',
        statusCode: 401,
      );
    }
    String? token;
    try {
      token = await user.getIdToken(refreshToken);
    } catch (_) {
      throw const ApiException(
        'Tu sesión no es válida. Inicia sesión nuevamente.',
        statusCode: 401,
      );
    }
    if (token == null || token.isEmpty) {
      throw const ApiException(
        'Tu sesión no es válida. Inicia sesión nuevamente.',
        statusCode: 401,
      );
    }
    return _client
        .get(
          Uri.parse('$_baseUrl/videogames'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));
  }

  Future<List<Videogame>> obtenerProductos() async {
    http.Response response;
    try {
      response = await _request(refreshToken: false);
      if (response.statusCode == 401) {
        response = await _request(refreshToken: true);
      }
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        'La API tardó demasiado en responder. Intenta nuevamente.',
      );
    } on http.ClientException {
      throw const ApiException(
        'No se pudo conectar con la API. Revisa la conexión y la URL del servidor.',
      );
    }
    if (response.statusCode == 401) {
      throw const ApiException(
        'La API no pudo validar tu sesión. Inicia sesión nuevamente.',
        statusCode: 401,
      );
    }
    if (response.statusCode == 403) {
      throw const ApiException(
        'No tienes permiso para consultar el catálogo.',
        statusCode: 403,
      );
    }
    if (response.statusCode != 200) {
      throw ApiException(
        'No se pudo obtener el catálogo (HTTP ${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }
    try {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is! List) throw const FormatException();
      return data
          .map((item) {
            if (item is! Map<String, dynamic>) throw const FormatException();
            return Videogame.fromJson(item);
          })
          .toList(growable: false);
    } on FormatException {
      throw const ApiException(
        'La API devolvió un catálogo con un formato inesperado.',
      );
    }
  }

  void dispose() {
    if (_ownsClient) _client.close();
  }
}
