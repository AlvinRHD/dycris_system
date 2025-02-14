class Oferta {
  final int id;
  final int?
      inventarioId; // Asegúrate de que este campo esté en la respuesta del servidor
  final double descuento;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String estado;
  final String codigo;
  final String productoNombre;
  final double precioVenta;

  Oferta({
    required this.id,
    this.inventarioId,
    required this.descuento,
    required this.fechaInicio,
    required this.fechaFin,
    required this.estado,
    required this.codigo,
    required this.productoNombre,
    required this.precioVenta,
  });

  factory Oferta.fromJson(Map<String, dynamic> json) {
    return Oferta(
      id: json['id'],
      inventarioId:
          json['inventario_id'], // Acepta null si el campo no está presente
      descuento: double.parse(json['descuento'].toString()) ??
          0.0, // Usa tryParse, // Convierte a double
      fechaInicio: DateTime.parse(json['fecha_inicio']),
      fechaFin: DateTime.parse(json['fecha_fin']),
      estado: json['estado'],
      codigo: json['codigo'],
      productoNombre: json['producto_nombre'],
      precioVenta: double.parse(json['precio_venta'].toString()) ??
          0.0, // Usa tryParse, // Convierte a double
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inventario_id': inventarioId,
      'descuento': descuento,
      'fecha_inicio': fechaInicio.toIso8601String(),
      'fecha_fin': fechaFin.toIso8601String(),
      'estado': estado,
      'codigo': codigo,
      'producto_nombre': productoNombre,
      'precio_venta': precioVenta,
    };
  }
}
