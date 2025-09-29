import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClearAppData {
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    debugPrint('✅ Todos los datos de la aplicación han sido limpiados');
  }
  
  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    debugPrint('✅ Datos de autenticación limpiados');
  }
}


