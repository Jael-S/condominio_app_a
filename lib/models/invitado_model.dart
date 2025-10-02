// (no imports needed)

class Invitado {
  final int id;
  final String nombre;
  final String ci;
  final String tipo; // 'evento' | 'casual'
  final String? placa;
  final String? evento; // requerido por backend si tipo = evento
  final String? residenteNombre;
  final DateTime? horaEntrada;
  final DateTime? horaSalida;
  final String estado; // pendiente | en_casa | finalizado

  Invitado({
    required this.id,
    required this.nombre,
    required this.ci,
    required this.tipo,
    this.placa,
    this.evento,
    this.residenteNombre,
    this.horaEntrada,
    this.horaSalida,
    required this.estado,
  });

  static String _normalizeTipo(dynamic v){
    final s = v?.toString().toLowerCase().trim() ?? 'casual';
    if (s.startsWith('ev')) return 'evento';
    return 'casual';
  }

  factory Invitado.fromJson(Map<String, dynamic> json) {
    DateTime? _parseDt(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    String? _residenteNombreFrom(dynamic v){
      try{
        if (v is Map<String, dynamic>) {
          final n = v['nombre'];
          return n?.toString();
        }
      }catch(_){ }
      return null;
    }

    return Invitado(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      nombre: json['nombre']?.toString() ?? '',
      ci: json['ci']?.toString() ?? '',
      tipo: _normalizeTipo(json['tipo']),
      placa: json['vehiculo_placa']?.toString() ?? json['placa']?.toString(),
      evento: json['evento']?.toString(),
      residenteNombre: json['residente_nombre']?.toString() ?? _residenteNombreFrom(json['residente']),
      horaEntrada: _parseDt(json['check_in_at'] ?? json['hora_entrada']),
      horaSalida: _parseDt(json['check_out_at'] ?? json['hora_salida']),
      estado: json['estado']?.toString() ?? _inferEstado(
        _parseDt(json['check_in_at'] ?? json['hora_entrada']),
        _parseDt(json['check_out_at'] ?? json['hora_salida']),
      ),
    );
  }

  /// Parser tolerante: acepta Map o id simple
  static Invitado fromAny(dynamic data) {
    if (data is Map<String, dynamic>) {
      return Invitado.fromJson(data);
    }
    if (data is int) {
      return Invitado(
        id: data,
        nombre: '',
        ci: '',
        tipo: 'casual',
        estado: 'pendiente',
      );
    }
    // Si viene como string numérico
    final asInt = int.tryParse('$data');
    if (asInt != null) {
      return Invitado(
        id: asInt,
        nombre: '',
        ci: '',
        tipo: 'casual',
        estado: 'pendiente',
      );
    }
    return Invitado(
      id: 0,
      nombre: '',
      ci: '',
      tipo: 'casual',
      estado: 'pendiente',
    );
  }

  static String _inferEstado(DateTime? entrada, DateTime? salida) {
    if (salida != null) return 'finalizado';
    if (entrada != null) return 'en_casa';
    return 'pendiente';
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'nombre': nombre,
      'ci': ci,
      'tipo': _normalizeTipo(tipo),
      if (placa != null && placa!.isNotEmpty) 'vehiculo_placa': placa,
    };
  }

  static List<Invitado> listFromResponse(dynamic data) {
    if (data is List) {
      return data.map((e) => Invitado.fromAny(e)).toList();
    }
    if (data is Map && data['results'] is List) {
      return (data['results'] as List).map((e) => Invitado.fromAny(e)).toList();
    }
    return [];
  }
}
