import 'dart:convert';

class NotificacionModel {
  final int id;
  final String titulo;
  final String contenido;
  final DateTime fecha;
  final String tipo;
  final String prioridad;
  final bool enviarATodos;
  final Map<String, dynamic> destinatarios;

  NotificacionModel({
    required this.id,
    required this.titulo,
    required this.contenido,
    required this.fecha,
    required this.tipo,
    required this.prioridad,
    required this.enviarATodos,
    required this.destinatarios,
  });

  factory NotificacionModel.fromJson(Map<String, dynamic> jsonMap) {
    return NotificacionModel(
      id: jsonMap['id'] as int,
      titulo: jsonMap['titulo'] ?? '',
      contenido: jsonMap['contenido'] ?? '',
      fecha: DateTime.tryParse(jsonMap['fecha']?.toString() ?? '') ?? DateTime.now(),
      tipo: jsonMap['tipo']?.toString() ?? 'comunicado',
      prioridad: jsonMap['prioridad']?.toString() ?? 'media',
      enviarATodos: (jsonMap['enviar_a_todos'] as bool?) ?? false,
      destinatarios: (jsonMap['destinatarios'] is String)
          ? (json.decode(jsonMap['destinatarios']) as Map<String, dynamic>)
          : (jsonMap['destinatarios'] as Map<String, dynamic>? ?? <String, dynamic>{}),
    );
  }
}


