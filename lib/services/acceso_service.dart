import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class AccesoService {
  static Future<Map<String, dynamic>?> getDashboardData(String token) async {
    try {
      final url = Uri.parse(AppConfig.dashboardAccesoUrl);
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

  static Future<List<dynamic>?> getRegistrosAcceso(String token, {Map<String, String>? params}) async {
    try {
      String url = AppConfig.registrosAccesoUrl;
      if (params != null && params.isNotEmpty) {
        final queryParams = params.entries.map((e) => '${e.key}=${e.value}').join('&');
        url += '?$queryParams';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['results'] ?? data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> autorizarRegistro(String token, int id) async {
    try {
      final url = Uri.parse('${AppConfig.registrosAccesoUrl}$id/autorizar/');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> denegarRegistro(String token, int id) async {
    try {
      final url = Uri.parse('${AppConfig.registrosAccesoUrl}$id/denegar/');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> eliminarRegistro(String token, int id) async {
    try {
      final url = Uri.parse('${AppConfig.registrosAccesoUrl}$id/eliminar/');
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

}
