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
    final s = value.toString().toLowerCase().trim();
    return s == '1' || s == 'true' || s == 'yes' || s == 'si';
  }

  static Future<List<NotificacionModel>> listar({String? rol}) async {
    final url = Uri.parse(AppConfig.notificacionesUrl);
    final token = await StorageService.getToken();
    final headers = token != null ? ApiService.getAuthHeaders(token) : ApiService.headers;
    final res = await http.get(url, headers: headers);
    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);
      final List<dynamic> dataList = decoded is List
          ? decoded
          : (decoded is Map<String, dynamic> && decoded['results'] is List
              ? decoded['results'] as List<dynamic>
              : <dynamic>[]);
      final list = dataList.map((e) => NotificacionModel.fromJson(e as Map<String, dynamic>)).toList();
      if (rol == null) return list;
      return list.where((n) {
        final dest = n.destinatarios;
        if (n.enviarATodos == true) return true;
        switch (rol.toLowerCase()) {
          case 'residente':
            return _isTruthy(dest['residentes']);
          case 'empleado':
            return _isTruthy(dest['empleados']);
          case 'seguridad':
            return _isTruthy(dest['seguridad']);
          default:
            return true;
        }
      }).toList();
    }
    throw Exception('Error listando notificaciones: ${res.statusCode} ${res.body}');
  }
}


