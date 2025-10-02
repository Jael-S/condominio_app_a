import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/invitado_model.dart';
import 'api_service.dart';

class InvitadosService {
  static Uri _residentUrl() => Uri.parse(AppConfig.invitadosUrl);
  static Uri _seguridadUrl() => Uri.parse('${AppConfig.baseUrl}/registros-acceso/');
  static Uri _detailUrl(int id) => Uri.parse('${AppConfig.invitadosUrl}$id/');

  // Lista de invitados del residente autenticado
  static Future<List<Invitado>> listarDelResidente(String token) async {
    Future<List<Invitado>> _doGet(Uri url) async {
      final res = await http.get(url, headers: ApiService.getAuthHeaders(token));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        // DEBUG: imprimir forma de la respuesta para diagnosticar
        try {
          if (data is List) {
            debugPrint('[InvitadosService] listarDelResidente -> List len=${data.length}; first=${data.isNotEmpty ? data.first.runtimeType : 'EMPTY'}');
          } else if (data is Map) {
            final results = data['results'];
            debugPrint('[InvitadosService] listarDelResidente -> Map keys=${data.keys}; results_type=${results.runtimeType}');
            if (results is List && results.isNotEmpty) {
              debugPrint('[InvitadosService] listarDelResidente -> results first=${results.first.runtimeType}');
            }
          } else {
            debugPrint('[InvitadosService] listarDelResidente -> Unexpected type ${data.runtimeType}');
          }
        } catch (_) {}
        return Invitado.listFromResponse(data);
      }
      throw Exception('Error al obtener invitados (${res.statusCode})');
    }

    // 1) Intento base
    List<Invitado> list = await _doGet(_residentUrl());
    // Completar detalles si vinieron elementos sin datos (ej. sólo id)
    list = await _hydrateIfNeeded(token, list);
    if (list.isNotEmpty) return list;

    // 2) Intento con query comunes en backend: ?mios=1
    try {
      list = await _doGet(_residentUrl().replace(query: 'mios=1'));
      list = await _hydrateIfNeeded(token, list);
      if (list.isNotEmpty) return list;
    } catch (_) {}

    // 3) Intento alterno: ?propios=1
    try {
      list = await _doGet(_residentUrl().replace(query: 'propios=1'));
      list = await _hydrateIfNeeded(token, list);
      if (list.isNotEmpty) return list;
    } catch (_) {}

    return list; // vacío si no hay resultados
  }

  // Si la lista trae invitados incompletos (sin nombre/ci), obtener detalle por id
  static Future<List<Invitado>> _hydrateIfNeeded(String token, List<Invitado> items) async {
    try{
      final need = items.where((e) => (e.nombre.isEmpty && e.id > 0)).toList();
      if (need.isEmpty) return items;
      final futures = need.map((e) => obtenerDetalle(token, e.id));
      final details = await Future.wait(futures);
      final byId = { for (final d in details) d.id : d };
      return items.map((e) => byId[e.id] ?? e).toList();
    }catch(_){
      return items;
    }
  }

  static Future<Invitado> obtenerDetalle(String token, int id) async {
    final res = await http.get(_detailUrl(id), headers: ApiService.getAuthHeaders(token));
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return Invitado.fromAny(data);
    }
    throw Exception('No se pudo obtener detalle de invitado');
  }

  // Crear invitado (residente)
  static Future<Invitado> crearInvitado(String token, Invitado inv) async {
    final res = await http.post(_residentUrl(),
        headers: ApiService.getAuthHeaders(token), body: json.encode(inv.toCreateJson()));
    if (res.statusCode == 201) {
      final data = json.decode(res.body);
      // Algunos backends devuelven solo el id o un objeto mínimo
      if (data is int) {
        return Invitado(
          id: data,
          nombre: inv.nombre,
          ci: inv.ci,
          tipo: inv.tipo,
          placa: inv.placa,
          evento: inv.evento,
          estado: 'pendiente',
        );
      }
      if (data is Map<String, dynamic>) {
        // Si solo trae 'id', completar con lo enviado
        if (data.keys.length == 1 && data.containsKey('id')) {
          final id = data['id'] is int ? data['id'] : int.tryParse('${data['id']}') ?? 0;
          return Invitado(
            id: id,
            nombre: inv.nombre,
            ci: inv.ci,
            tipo: inv.tipo,
            placa: inv.placa,
            evento: inv.evento,
            estado: 'pendiente',
          );
        }
        return Invitado.fromJson(data);
      }
      // Fallback: devolver lo enviado sin id fiable
      return Invitado(
        id: 0,
        nombre: inv.nombre,
        ci: inv.ci,
        tipo: inv.tipo,
        placa: inv.placa,
        evento: inv.evento,
        estado: 'pendiente',
      );
    }
    try{
      final data = json.decode(res.body);
      final nonField = (data['non_field_errors'] is List && (data['non_field_errors'] as List).isNotEmpty)
        ? (data['non_field_errors'][0].toString())
        : null;
      final detail = data['detail']?.toString();
      throw Exception(nonField ?? detail ?? 'No se pudo crear el invitado');
    }catch(_){
      throw Exception('No se pudo crear el invitado');
    }
  }

  // Lista de invitados para seguridad (todos)
  static Future<List<Invitado>> listarParaSeguridad(String token) async {
    final res = await http.get(_seguridadUrl(), headers: ApiService.getAuthHeaders(token));
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return Invitado.listFromResponse(data);
    }
    throw Exception('Error al obtener registros (${res.statusCode})');
  }

  // Marcar entrada (seguridad)
  static Future<void> marcarEntrada(String token, int id) async {
    final url = Uri.parse('${AppConfig.invitadosUrl}$id/check_in/');
    final res = await http.post(url, headers: ApiService.getAuthHeaders(token));
    if (res.statusCode != 200) {
      throw Exception('No se pudo marcar entrada');
    }
  }

  // Marcar salida (seguridad)
  static Future<void> marcarSalida(String token, int id) async {
    final url = Uri.parse('${AppConfig.invitadosUrl}$id/check_out/');
    final res = await http.post(url, headers: ApiService.getAuthHeaders(token));
    if (res.statusCode != 200) {
      throw Exception('No se pudo marcar salida');
    }
  }
}

