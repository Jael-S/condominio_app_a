class AreaComun {
  final int id;
  final String nombre;
  final String tipo;
  final String descripcion;
  final bool estado;

  AreaComun({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.descripcion,
    required this.estado,
  });

  factory AreaComun.fromJson(Map<String, dynamic> json) {
    return AreaComun(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      tipo: json['tipo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      estado: json['estado'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'tipo': tipo,
      'descripcion': descripcion,
      'estado': estado,
    };
  }

  @override
  String toString() {
    return 'AreaComun(id: $id, nombre: $nombre, tipo: $tipo, estado: $estado)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AreaComun && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}


