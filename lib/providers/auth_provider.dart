import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/session_service.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider with ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _user != null;
  bool get isLoading => _status == AuthStatus.loading;

  // Inicializar el provider
  Future<void> initialize() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      // Verificar si la sesión es válida
      final isSessionValid = await SessionService.isSessionValid();
      
      if (isSessionValid) {
        final token = await StorageService.getToken();
        final user = await StorageService.getUser();

        if (token != null && user != null) {
          _user = user;
          _status = AuthStatus.authenticated;
          
          // Actualizar última actividad
          await SessionService.updateLastActivity();
          
          debugPrint('✅ AuthProvider: Sesión válida restaurada para ${user.username}');
        } else {
          await SessionService.clearPreviousSession();
          _status = AuthStatus.unauthenticated;
        }
      } else {
        debugPrint('❌ AuthProvider: Sesión inválida, limpiando datos');
        await SessionService.clearPreviousSession();
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      debugPrint('❌ AuthProvider: Error inicializando: $e');
      await SessionService.clearPreviousSession();
      _status = AuthStatus.error;
      _errorMessage = 'Error al inicializar: ${e.toString()}';
    }

    notifyListeners();
  }

  // Login
  Future<bool> login(String username, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Verificar si el usuario ha cambiado
      final userChanged = await SessionService.hasUserChanged(username);
      if (userChanged) {
        debugPrint('🔍 AuthProvider: Usuario cambió, limpiando sesión anterior');
        await SessionService.clearPreviousSession();
      }

      final response = await ApiService.login(username, password);

      if (response.success && response.user != null) {
        _user = response.user;
        _status = AuthStatus.authenticated;
        
        // Guardar datos localmente
        await StorageService.saveToken(_user!.token);
        await StorageService.saveUser(_user!);
        
        // Guardar información de sesión
        await SessionService.saveCurrentSession(username);
        
        debugPrint('Login exitoso para usuario: ${_user!.username}');
        debugPrint('Rol: ${_user!.rol}');
        debugPrint('Token: ${_user!.token.substring(0, 10)}...');
        
        notifyListeners();
        return true;
      } else {
        _status = AuthStatus.error;
        _errorMessage = response.message ?? 'Error de autenticación';
        debugPrint('Error en login: $_errorMessage');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Error de conexión: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      if (_user != null) {
        debugPrint('Iniciando logout para usuario: ${_user!.username}');
        final success = await ApiService.logout(_user!.token);
        debugPrint('Logout en servidor: ${success ? "exitoso" : "falló"}');
      }
    } catch (e) {
      debugPrint('Error en logout: $e');
    } finally {
      // Limpiar datos locales independientemente del resultado del servidor
      debugPrint('Limpiando datos locales...');
      await SessionService.clearPreviousSession();
      _user = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
      debugPrint('Logout completado');
      notifyListeners();
    }
  }

  // Limpiar datos de sesión (para cambios de usuario)
  Future<void> clearSession() async {
    debugPrint('Limpiando sesión actual...');
    await SessionService.clearPreviousSession();
    _user = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }

  // Limpiar error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Verificar si el usuario es residente
  bool get isResidente => _user?.isResidente ?? false;
  
  // Verificar si el usuario es empleado
  bool get isEmpleado => _user?.isEmpleado ?? false;
  
  // Verificar si el usuario es seguridad
  bool get isSeguridad => _user?.isSeguridad ?? false;
  
  // Verificar si el usuario es admin
  bool get isAdmin => _user?.isAdmin ?? false;
  
  // Verificar si puede acceder desde la app móvil
  bool get canAccessMobile => _user?.canAccessMobile ?? false;
}
