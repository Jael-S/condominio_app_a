import 'package:flutter/foundation.dart';
import 'storage_service.dart';
import 'api_service.dart';

class SessionService {
  static const String _sessionKey = 'current_session_user';
  static const String _lastActivityKey = 'last_activity';

  /// Verificar si la sesión actual es válida
  static Future<bool> isSessionValid() async {
    try {
      final token = await StorageService.getToken();
      final user = await StorageService.getUser();
      
      if (token == null || user == null) {
        debugPrint('🔍 SessionService: No hay token o usuario almacenado');
        return false;
      }

      // Verificar si el token sigue siendo válido
      final isValid = await ApiService.verifyToken(token);
      debugPrint('🔍 SessionService: Token válido: $isValid');
      
      return isValid;
    } catch (e) {
      debugPrint('❌ SessionService: Error verificando sesión: $e');
      return false;
    }
  }

  /// Limpiar datos de sesión anterior
  static Future<void> clearPreviousSession() async {
    try {
      debugPrint('🔍 SessionService: Limpiando sesión anterior...');
      await StorageService.clearAuth();
      await StorageService.removeKey(_sessionKey);
      await StorageService.removeKey(_lastActivityKey);
      debugPrint('✅ SessionService: Sesión anterior limpiada');
    } catch (e) {
      debugPrint('❌ SessionService: Error limpiando sesión: $e');
    }
  }

  /// Guardar información de la sesión actual
  static Future<void> saveCurrentSession(String username) async {
    try {
      await StorageService.saveString(_sessionKey, username);
      await StorageService.saveString(_lastActivityKey, DateTime.now().toIso8601String());
      debugPrint('✅ SessionService: Sesión guardada para $username');
    } catch (e) {
      debugPrint('❌ SessionService: Error guardando sesión: $e');
    }
  }

  /// Verificar si el usuario ha cambiado
  static Future<bool> hasUserChanged(String currentUsername) async {
    try {
      final lastUsername = await StorageService.getString(_sessionKey);
      if (lastUsername == null) {
        debugPrint('🔍 SessionService: No hay usuario anterior');
        return false;
      }
      
      final hasChanged = lastUsername != currentUsername;
      debugPrint('🔍 SessionService: Usuario cambió: $hasChanged ($lastUsername -> $currentUsername)');
      return hasChanged;
    } catch (e) {
      debugPrint('❌ SessionService: Error verificando cambio de usuario: $e');
      return false;
    }
  }

  /// Obtener tiempo de última actividad
  static Future<DateTime?> getLastActivity() async {
    try {
      final lastActivityStr = await StorageService.getString(_lastActivityKey);
      if (lastActivityStr == null) return null;
      return DateTime.parse(lastActivityStr);
    } catch (e) {
      debugPrint('❌ SessionService: Error obteniendo última actividad: $e');
      return null;
    }
  }

  /// Actualizar tiempo de última actividad
  static Future<void> updateLastActivity() async {
    try {
      await StorageService.saveString(_lastActivityKey, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('❌ SessionService: Error actualizando actividad: $e');
    }
  }

  /// Verificar si la sesión ha expirado por tiempo
  static Future<bool> isSessionExpiredByTime({Duration maxInactivity = const Duration(hours: 24)}) async {
    try {
      final lastActivity = await getLastActivity();
      if (lastActivity == null) return true;
      
      final now = DateTime.now();
      final timeDiff = now.difference(lastActivity);
      
      final isExpired = timeDiff > maxInactivity;
      debugPrint('🔍 SessionService: Sesión expirada por tiempo: $isExpired (${timeDiff.inHours}h)');
      
      return isExpired;
    } catch (e) {
      debugPrint('❌ SessionService: Error verificando expiración: $e');
      return true;
    }
  }
}





