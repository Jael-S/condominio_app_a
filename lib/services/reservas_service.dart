import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/area_comun_model.dart';
import '../models/reserva_model.dart';
import '../models/horario_disponible_model.dart';

class ReservasService {

  // Headers comunes
  static Map<String, String> _getHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Token $token',
    };
  }

  // Obtener todas las áreas comunes
  static Future<List<AreaComun>> getAreasComunes(String token) async {
    try {
      final url = AppConfig.areasComunesUrl;
      
      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('🔍 Debug: Respuesta del servidor: $data');
        
        // Manejar diferentes formatos de respuesta
        List<dynamic> areasList;
        if (data is List) {
          areasList = data;
        } else if (data is Map && data.containsKey('results')) {
          final results = data['results'];
          if (results is List) {
            areasList = results;
          } else {
            areasList = [];
          }
        } else {
          areasList = [data];
        }
        
        debugPrint('🔍 Debug: Áreas procesadas: ${areasList.length}');
        return areasList.map((json) => AreaComun.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener áreas comunes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener reservas del usuario actual
  static Future<List<Reserva>> getReservas(String token) async {
    try {
      final url = AppConfig.reservasUrl;
      
      debugPrint('🔍 Debug: Obteniendo reservas desde: $url');
      debugPrint('🔍 Debug: Token: ${token.substring(0, 20)}...');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(token),
      );

      debugPrint('🔍 Debug: Status code: ${response.statusCode}');
      debugPrint('🔍 Debug: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('🔍 Debug: Respuesta de reservas: $data');
        
        // Manejar diferentes formatos de respuesta
        List<dynamic> reservasList;
        if (data is List) {
          reservasList = data;
          debugPrint('🔍 Debug: Es una lista directa');
        } else if (data is Map && data.containsKey('results')) {
          final results = data['results'];
          if (results is List) {
            reservasList = results;
            debugPrint('🔍 Debug: Es un objeto con results');
          } else {
            reservasList = [];
            debugPrint('🔍 Debug: Results no es una lista');
          }
        } else {
          reservasList = [data];
          debugPrint('🔍 Debug: Es un objeto único');
        }
        
        debugPrint('🔍 Debug: Reservas procesadas: ${reservasList.length}');
        
        final reservas = reservasList.map((json) {
          debugPrint('🔍 Debug: Procesando reserva: $json');
          return Reserva.fromJson(json);
        }).toList();
        
        debugPrint('🔍 Debug: Reservas finales: ${reservas.length}');
        return reservas;
      } else if (response.statusCode == 401) {
        debugPrint('❌ Debug: Token expirado o inválido');
        throw Exception('Sesión expirada. Por favor, inicia sesión nuevamente.');
      } else {
        debugPrint('❌ Debug: Error en respuesta: ${response.statusCode}');
        throw Exception('Error al obtener reservas: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Debug: Error en getReservas: $e');
      if (e.toString().contains('Sesión expirada')) {
        rethrow;
      }
      throw Exception('Error de conexión: $e');
    }
  }

  // Crear nueva reserva
  static Future<Reserva> crearReserva(String token, Map<String, dynamic> reservaData) async {
    try {
      final url = AppConfig.reservasUrl;
      final headers = _getHeaders(token);
      
      debugPrint('🔍 Debug: Creando reserva en: $url');
      debugPrint('🔍 Debug: Headers: $headers');
      debugPrint('🔍 Debug: Datos: $reservaData');
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(reservaData),
      );

      debugPrint('🔍 Debug: Status code: ${response.statusCode}');
      debugPrint('🔍 Debug: Response body: ${response.body}');

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Reserva.fromJson(data);
      } else {
        // Manejar diferentes formatos de error
        final errorData = json.decode(response.body);
        String errorMessage = 'Error desconocido';
        
        if (errorData is List && errorData.isNotEmpty) {
          // Error como lista de strings
          errorMessage = errorData.first.toString();
        } else if (errorData is Map) {
          // Error como objeto
          errorMessage = errorData['detail'] ?? errorData['message'] ?? errorData['error'] ?? 'Error desconocido';
        } else if (errorData is String) {
          // Error como string directo
          errorMessage = errorData;
        }
        
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('❌ Debug: Error en crearReserva: $e');
      if (e.toString().contains('Sesión expirada')) {
        rethrow;
      }
      throw Exception('Error de conexión: $e');
    }
  }

  // Verificar disponibilidad
  static Future<Map<String, dynamic>> verificarDisponibilidad(
    String token,
    int areaId,
    String fecha,
    String horaInicio,
    String horaFin,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(AppConfig.reservasDisponibilidadUrl).replace(
          queryParameters: {
            'area_id': areaId.toString(),
            'fecha': fecha,
            'hora_inicio': horaInicio,
            'hora_fin': horaFin,
          },
        ),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al verificar disponibilidad: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener horarios disponibles
  static Future<Map<String, dynamic>> getHorariosDisponibles(
    String token,
    int areaId,
    String fecha,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(AppConfig.reservasHorariosDisponiblesUrl).replace(
          queryParameters: {
            'area_id': areaId.toString(),
            'fecha': fecha,
          },
        ),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return {
          'fecha': data['fecha'],
          'area_id': data['area_id'],
          'horarios_disponibles': (data['horarios_disponibles'] as List)
              .map((json) => HorarioDisponible.fromJson(json))
              .toList(),
          'reservas_existentes': (data['reservas_existentes'] as List)
              .map((json) => Reserva.fromJson(json))
              .toList(),
        };
      } else {
        throw Exception('Error al obtener horarios disponibles: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Confirmar reserva
  static Future<Map<String, dynamic>> confirmarReserva(String token, int reservaId) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.reservasUrl}$reservaId/confirmar/'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al confirmar reserva: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Cancelar reserva
  static Future<Map<String, dynamic>> cancelarReserva(String token, int reservaId) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.reservasUrl}$reservaId/cancelar/'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al cancelar reserva: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Actualizar reserva
  static Future<Reserva> actualizarReserva(
    String token,
    int reservaId,
    Map<String, dynamic> reservaData,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConfig.reservasUrl}$reservaId/'),
        headers: _getHeaders(token),
        body: json.encode(reservaData),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Reserva.fromJson(data);
      } else {
        final Map<String, dynamic> error = json.decode(response.body);
        throw Exception('Error al actualizar reserva: ${error['detail'] ?? 'Error desconocido'}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Eliminar reserva
  static Future<void> eliminarReserva(String token, int reservaId) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConfig.reservasUrl}$reservaId/'),
        headers: _getHeaders(token),
      );

      if (response.statusCode != 204) {
        throw Exception('Error al eliminar reserva: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
