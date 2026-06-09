import 'dart:convert';
import 'package:http/http.dart' as http;

class DeepSeekService {
  static const _baseUrl = 'https://api.deepseek.com';

  /// Fetches the account balance for the given API key.
  /// Returns a map with balance info, or throws on error.
  static Future<Map<String, dynamic>> fetchBalance(String apiKey) async {
    final uri = Uri.parse('$_baseUrl/user/balance');
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      final body = response.body;
      String message;
      try {
        final json = jsonDecode(body);
        message = json['error']?['message'] ?? body;
      } catch (_) {
        message = body.isNotEmpty ? body : 'HTTP ${response.statusCode}';
      }
      throw Exception(message);
    }
  }
}
