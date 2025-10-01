import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../config/app_config.dart';

class ApiService {

  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> getAuthHeaders(String token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Token $token',
  };

  // Login
  static Future<LoginResponse> login(String username, String password) async {
    try {
      final url = Uri.parse(AppConfig.loginUrl);
      final request = LoginRequest(username: username, password: password);
      
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return LoginResponse(
          success: true,
          user: UserModel.fromJson(data),
        );
      } else {
        final data = json.decode(response.body);
        return LoginResponse(
          success: false,
          message: data['detail'] ?? 'Error de autenticación',
        );
      }
    } catch (e) {
      return LoginResponse(
        success: false,
        message: 'Error de conexión: ${e.toString()}',
      );
    }
  }

  // Logout
  static Future<bool> logout(String token) async {
    try {
      final url = Uri.parse(AppConfig.logoutUrl);
      
      final response = await http.post(
        url,
        headers: getAuthHeaders(token),
      );

      debugPrint('Logout response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error en logout: $e');
      return false;
    }
  }

  // Verificar token
  static Future<bool> verifyToken(String token) async {
    try {
      // Usar un endpoint protegido para verificar token
      final url = Uri.parse(AppConfig.usuariosUrl);
      
      final response = await http.get(
        url,
        headers: getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        debugPrint('Token verificado exitosamente');
        return true;
      } else if (response.statusCode == 401) {
        debugPrint('Token expirado o inválido: ${response.statusCode}');
        return false;
      } else {
        debugPrint('Error verificando token: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error verificando token: $e');
      return false;
    }
  }
}
