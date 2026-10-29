import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/flight.dart';

class FlightServiceException implements Exception {
  const FlightServiceException(this.message);
  final String message;

  @override
  String toString() => message;
}

class FlightService {
  FlightService({
    http.Client? client,
    this.baseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://127.0.0.1:5001',
    ),
    this.timeout = const Duration(seconds: 30),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;
  final Duration timeout;

  Future<FlightSearchResult> fetchFlights({
    required String airport,
    required FlightType type,
  }) async {
    try {
      final uri = Uri.parse(baseUrl).replace(
        path: '/api/voos',
        queryParameters: {'aeroporto': airport, 'tipo': type.value},
      );
      final response = await _client.get(uri).timeout(timeout);
      if (response.statusCode != 200) {
        String message = 'A API retornou o erro HTTP ${response.statusCode}.';
        try {
          final body = jsonDecode(utf8.decode(response.bodyBytes));
          if (body is Map<String, dynamic> && body['erro'] is String) {
            message = body['erro'] as String;
          }
        } on FormatException {
          // Flask pode retornar HTML em uma falha interna.
        }
        throw FlightServiceException(message);
      }
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is! Map<String, dynamic>) {
        throw const FormatException('Objeto JSON esperado.');
      }
      return FlightSearchResult.fromJson(body);
    } on TimeoutException {
      throw const FlightServiceException(
        'A consulta demorou demais. Tente novamente em alguns instantes.',
      );
    } on http.ClientException {
      throw const FlightServiceException(
        'Não foi possível conectar à API. Verifique se o Python está rodando e confira o endereço configurado.',
      );
    } on FormatException {
      throw const FlightServiceException(
        'A API retornou dados em formato inválido.',
      );
    }
  }

  void dispose() => _client.close();
}
