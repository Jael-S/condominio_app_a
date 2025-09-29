class HorarioDisponible {
  final String horaInicio;
  final String horaFin;
  final bool disponible;

  HorarioDisponible({
    required this.horaInicio,
    required this.horaFin,
    required this.disponible,
  });

  factory HorarioDisponible.fromJson(Map<String, dynamic> json) {
    return HorarioDisponible(
      horaInicio: json['hora_inicio'] ?? '',
      horaFin: json['hora_fin'] ?? '',
      disponible: json['disponible'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hora_inicio': horaInicio,
      'hora_fin': horaFin,
      'disponible': disponible,
    };
  }

  String get horarioTexto {
    return '$horaInicio - $horaFin';
  }

  @override
  String toString() {
    return 'HorarioDisponible(horaInicio: $horaInicio, horaFin: $horaFin, disponible: $disponible)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HorarioDisponible && 
           other.horaInicio == horaInicio && 
           other.horaFin == horaFin;
  }

  @override
  int get hashCode => horaInicio.hashCode ^ horaFin.hashCode;
}


