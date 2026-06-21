import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class GoogleWalletService {
  final String _baseUrl = '${AppConstants.baseUrl}/wallet';

  Future<Map<String, String>> _headers() async {
    return {
      'Content-Type': 'application/json',
    };
  }

  /// Obtiene el enlace de Google Wallet para guardar la tarjeta de lealtad del cliente
  /// 
  /// Parámetros:
  /// - [userId]: ID del cliente
  /// 
  /// Retorna:
  /// - URL de Google Wallet para guardar la tarjeta
  /// 
  /// Lanza excepción si falla
  Future<String> getGoogleWalletSaveLink(String userId) async {
    try {
      final uri = Uri.parse('$_baseUrl/google/save-link/$userId');

      final response = await http.get(
        uri,
        headers: await _headers(),
      );

      if (response.statusCode == 200) {
        final dynamic body = json.decode(response.body);

        if (body is Map<String, dynamic>) {
          final url = body['url'];
          if (url is String) {
            return url;
          }
        }

        throw Exception('Invalid response format: missing or invalid URL');
      } else if (response.statusCode == 404) {
        throw Exception('Usuario no encontrado');
      } else if (response.statusCode == 500) {
        throw Exception(
          'Error en el servidor. Por favor, intenta más tarde.',
        );
      } else {
        throw Exception(
          'Error al obtener enlace de Google Wallet (${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Error al conectar con Google Wallet: $e');
    }
  }
}
