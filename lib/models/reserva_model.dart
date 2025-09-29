import 'area_comun_model.dart';

class Reserva {
  final int id;
  final String fecha;
  final String horaInicio;
  final String horaFin;
  final int residenteId;
  final int areaId;
  final String estado;
  final String? motivo;
  final double costo;
  final bool pagado;
  
  // Campos adicionales para mostrar información relacionada
  final String? areaNombre;
  final String? areaTipo;
  final String? residenteNombre;
  final String? residenteApellido;
  final AreaComun? area;

  Reserva({
    required this.id,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    required this.residenteId,
    required this.areaId,
    required this.estado,
    this.motivo,
    required this.costo,
    required this.pagado,
    this.areaNombre,
    this.areaTipo,
    this.residenteNombre,
    this.residenteApellido,
    this.area,
  });

  factory Reserva.fromJson(Map<String, dynamic> json) {
    return Reserva(
      id: json['id'] ?? 0,
      fecha: json['fecha'] ?? '',
      horaInicio: json['hora_inicio'] ?? '',
      horaFin: json['hora_fin'] ?? '',
      residenteId: json['residente_id'] ?? json['residente'] ?? 0, // ID del residente desde el backend
      areaId: json['area'] ?? 0, // ID del área desde el backend
      estado: json['estado'] ?? 'pendiente',
      motivo: json['motivo'],
      costo: _parseDouble(json['costo']),
      pagado: json['pagado'] ?? false,
      areaNombre: json['area_nombre'],
      areaTipo: json['area_tipo'],
      residenteNombre: json['residente_nombre'],
      residenteApellido: json['residente_apellido'],
      area: null, // El área se maneja por separado con areaNombre y areaTipo
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fecha': fecha,
      'hora_inicio': horaInicio,
      'hora_fin': horaFin,
      'residente': residenteId,
      'area': areaId,
      'estado': estado,
      'motivo': motivo,
      'costo': costo,
      'pagado': pagado,
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'area': areaId,
      'fecha': fecha,
      'hora_inicio': horaInicio,
      'hora_fin': horaFin,
      'motivo': motivo,
      'costo': costo,
    };
  }

  Reserva copyWith({
    int? id,
    String? fecha,
    String? horaInicio,
    String? horaFin,
    int? residenteId,
    int? areaId,
    String? estado,
    String? motivo,
    double? costo,
    bool? pagado,
    String? areaNombre,
    String? areaTipo,
    String? residenteNombre,
    String? residenteApellido,
    AreaComun? area,
  }) {
    return Reserva(
      id: id ?? this.id,
      fecha: fecha ?? this.fecha,
      horaInicio: horaInicio ?? this.horaInicio,
      horaFin: horaFin ?? this.horaFin,
      residenteId: residenteId ?? this.residenteId,
      areaId: areaId ?? this.areaId,
      estado: estado ?? this.estado,
      motivo: motivo ?? this.motivo,
      costo: costo ?? this.costo,
      pagado: pagado ?? this.pagado,
      areaNombre: areaNombre ?? this.areaNombre,
      areaTipo: areaTipo ?? this.areaTipo,
      residenteNombre: residenteNombre ?? this.residenteNombre,
      residenteApellido: residenteApellido ?? this.residenteApellido,
      area: area ?? this.area,
    );
  }

  String get estadoTexto {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'confirmada':
        return 'Confirmada';
      case 'cancelada':
        return 'Cancelada';
      case 'completada':
        return 'Completada';
      default:
        return estado;
    }
  }

  String get nombreCompletoResidente {
    if (residenteNombre != null && residenteApellido != null) {
      return '$residenteNombre $residenteApellido';
    }
    return 'Residente #$residenteId';
  }

  String get nombreArea {
    return areaNombre ?? 'Área #$areaId';
  }

  String get tipoArea {
    return areaTipo ?? '';
  }

  @override
  String toString() {
    return 'Reserva(id: $id, fecha: $fecha, horaInicio: $horaInicio, horaFin: $horaFin, estado: $estado)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Reserva && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// Helper method to safely parse double values from JSON
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
}


