import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/notificacion_model.dart';
import 'api_service.dart';
import 'storage_service.dart';

class NotificacionesService {

  static bool _isTruthy(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is double) return value != 0.0;
    final s = value.toString().toLowerCase().trim();
    return s == '1' || s == 'true' || s == 'yes' || s == 'si' || s == 'on';
  }


  static Future<List<NotificacionModel>> listar({String? rol}) async {
    final url = Uri.parse(AppConfig.notificacionesUrl);
    final token = await StorageService.getToken();
    final headers = token != null ? ApiService.getAuthHeaders(token) : ApiService.headers;
    final res = await http.get(url, headers: headers);
    
    print('🔍 DEBUG NotificacionesService:');
    print('   Rol solicitado: $rol');
    print('   Status code: ${res.statusCode}');
    
    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);
      final List<dynamic> dataList = decoded is List
          ? decoded
          : (decoded is Map<String, dynamic> && decoded['results'] is List
              ? decoded['results'] as List<dynamic>
              : <dynamic>[]);
      
      print('   Total comunicados recibidos: ${dataList.length}');
      
      final list = dataList.map((e) => NotificacionModel.fromJson(e as Map<String, dynamic>)).toList();
      
      if (rol == null) {
        print('   Sin filtro de rol, retornando todos: ${list.length}');
        return list;
      }
      
      final filtered = list.where((n) {
        final dest = n.destinatarios;
        print('   Comunicado "${n.titulo}":');
        print('     - Enviar a todos: ${n.enviarATodos}');
        print('     - Destinatarios: $dest');
        print('     - Rol solicitado: ${rol.toLowerCase()}');
        
        // Si está marcado para enviar a todos, incluir siempre
        if (n.enviarATodos == true) {
          print('     ✅ Incluido (enviar a todos)');
          return true;
        }
        
        // Si no hay destinatarios específicos, incluir por defecto
        if (dest.isEmpty) {
          print('     ✅ Incluido (sin destinatarios específicos)');
          return true;
        }
        
        // Lógica mejorada: incluir si el rol está explícitamente incluido O si no está explícitamente excluido
        bool shouldInclude = false;
        
        switch (rol.toLowerCase()) {
          case 'residente':
            // Incluir si está marcado para residentes O si no está explícitamente excluido
            if (dest.containsKey('residentes')) {
              shouldInclude = _isTruthy(dest['residentes']);
            } else {
              // Si no hay campo específico para residentes, incluir por defecto
              shouldInclude = true;
            }
            print('     - Residentes: ${dest['residentes']} -> $shouldInclude');
            break;
          case 'empleado':
            if (dest.containsKey('empleados')) {
              shouldInclude = _isTruthy(dest['empleados']);
            } else {
              shouldInclude = true;
            }
            print('     - Empleados: ${dest['empleados']} -> $shouldInclude');
            break;
          case 'seguridad':
            if (dest.containsKey('seguridad')) {
              shouldInclude = _isTruthy(dest['seguridad']);
            } else {
              shouldInclude = true;
            }
            print('     - Seguridad: ${dest['seguridad']} -> $shouldInclude');
            break;
          default:
            shouldInclude = true;
            print('     ✅ Incluido (rol por defecto)');
            break;
        }
        
        print('     ${shouldInclude ? '✅' : '❌'} ${shouldInclude ? 'Incluido' : 'Excluido'}');
        return shouldInclude;
      }).toList();
      
      print('   Comunicados filtrados para $rol: ${filtered.length}');
      return filtered;
    }
    throw Exception('Error listando notificaciones: ${res.statusCode} ${res.body}');
  }

  /// Confirmar lectura de un comunicado en el backend
  static Future<bool> confirmarLectura(int notificacionId) async {
    final url = Uri.parse('${AppConfig.notificacionesUrl}$notificacionId/confirmar_lectura/');
    final token = await StorageService.getToken();
    final headers = token != null ? ApiService.getAuthHeaders(token) : ApiService.headers;
    
    print('🔍 DEBUG NotificacionesService - Confirmar lectura:');
    print('   URL: $url');
    print('   Notificación ID: $notificacionId');
    
    try {
      final res = await http.post(url, headers: headers);
      print('   Status code: ${res.statusCode}');
      
      if (res.statusCode == 200) {
        final response = json.decode(res.body);
        print('   Respuesta: $response');
        return true;
      } else {
        print('   Error: ${res.body}');
        return false;
      }
    } catch (e) {
      print('   Excepción: $e');
      return false;
    }
  }
}


