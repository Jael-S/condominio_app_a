import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class DatasetService {
  static Future<Map<String, dynamic>?> getDataset(String name, String token) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/datasets/$name/');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
