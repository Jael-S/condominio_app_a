import 'network_config.dart';

class AppConfig {
  // URL base del backend Django
  static String get baseUrl => NetworkConfig.baseUrl;
  
  // Endpoints de autenticación
  static const String loginEndpoint = '/auth/login/';
  static const String logoutEndpoint = '/auth/logout/';
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Configuración de la app
  static const String appName = 'Condominio App';
  static const String appVersion = '1.0.0';
  
  // Configuración de desarrollo
  static const bool isDebugMode = true;
  
  // URLs completas
  static String get loginUrl => '$baseUrl$loginEndpoint';
  static String get logoutUrl => '$baseUrl$logoutEndpoint';
}
