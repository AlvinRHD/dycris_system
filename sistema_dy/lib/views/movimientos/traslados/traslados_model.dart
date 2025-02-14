class Traslado {
  final int id;
  final String codigoTraslado;
  final int inventarioId;
  final int origenId;
  final int destinoId;
  final int cantidad;
  final DateTime fechaTraslado;
  final int empleadoId;
  final String estado;

  Traslado({
    required this.id,
    required this.codigoTraslado,
    required this.inventarioId,
    required this.origenId,
    required this.destinoId,
    required this.cantidad,
    required this.fechaTraslado,
    required this.empleadoId,
    required this.estado,
  });

  factory Traslado.fromJson(Map<String, dynamic> json) {
    return Traslado(
      id: json['id'],
      codigoTraslado: json['codigo_traslado'],
      inventarioId: json['inventario_id'],
      origenId: json['origen_id'],
      destinoId: json['destino_id'],
      cantidad: json['cantidad'],
      fechaTraslado: DateTime.parse(json['fecha_traslado']),
      empleadoId: json['empleado_id'],
      estado: json['estado'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo_traslado': codigoTraslado,
      'inventario_id': inventarioId,
      'origen_id': origenId,
      'destino_id': destinoId,
      'cantidad': cantidad,
      'fecha_traslado': fechaTraslado.toIso8601String(),
      'empleado_id': empleadoId,
      'estado': estado,
    };
  }
}
