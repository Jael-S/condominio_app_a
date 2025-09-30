import 'network_config.dart';

class AppConfig {
  // URL base del backend Django
  static String get baseUrl => NetworkConfig.baseUrl;
  
  // Endpoints de autenticación
  static const String loginEndpoint = '/login/';
  static const String logoutEndpoint = '/logout/';
  
  // Endpoints raíz (según backend actual)
  static const String invitadosEndpoint = '/invitados/';
  static const String usuariosEndpoint = '/usuarios/';
  
  // Comunidad
  static const String notificacionesEndpoint = '/notificaciones/';
  static const String reservasEndpoint = '/reservas/';
  static const String reservasDisponibilidadEndpoint = '/reservas/disponibilidad/';
  static const String reservasHorariosEndpoint = '/reservas/horarios_disponibles/';
  
  // Mantenimiento
  static const String areasComunesEndpoint = '/areas-comunes/';
  
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
  static String get usuariosUrl => '$baseUrl$usuariosEndpoint';
  static String get invitadosUrl => '$baseUrl$invitadosEndpoint';
  
  // Comunidad
  static String get notificacionesUrl => '$baseUrl$notificacionesEndpoint';
  static String get reservasUrl => '$baseUrl$reservasEndpoint';
  static String get reservasDisponibilidadUrl => '$baseUrl$reservasDisponibilidadEndpoint';
  static String get reservasHorariosDisponiblesUrl => '$baseUrl$reservasHorariosEndpoint';
  
  // Mantenimiento
  static String get areasComunesUrl => '$baseUrl$areasComunesEndpoint';
}
