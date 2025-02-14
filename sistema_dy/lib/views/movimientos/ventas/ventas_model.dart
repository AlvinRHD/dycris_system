class Venta {
  final int? idVentas;
  final DateTime fechaVenta;
  final int clienteId;
  final String tipoFactura;
  final String metodoPago;
  final double total;
  final String descripcionCompra;
  final List<DetalleVenta> productos;

  Venta({
    this.idVentas,
    required this.fechaVenta,
    required this.clienteId,
    required this.tipoFactura,
    required this.metodoPago,
    required this.total,
    required this.descripcionCompra,
    required this.productos,
  });

  factory Venta.fromJson(Map<String, dynamic> json) {
    return Venta(
      idVentas: json['idVentas'],
      fechaVenta: DateTime.parse(json['fecha_venta']),
      clienteId: json['cliente_id'],
      tipoFactura: json['tipo_factura'],
      metodoPago: json['metodo_pago'],
      total: json['total'],
      descripcionCompra: json['descripcion_compra'],
      productos: List<DetalleVenta>.from(
          json['productos'].map((x) => DetalleVenta.fromJson(x))),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idVentas': idVentas,
      'fecha_venta': fechaVenta.toIso8601String(),
      'cliente_id': clienteId,
      'tipo_factura': tipoFactura,
      'metodo_pago': metodoPago,
      'total': total,
      'descripcion_compra': descripcionCompra,
      'productos': productos.map((x) => x.toJson()).toList(),
    };
  }
}

class DetalleVenta {
  final String codigoProducto;
  final String nombre;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;

  DetalleVenta({
    required this.codigoProducto,
    required this.nombre,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  factory DetalleVenta.fromJson(Map<String, dynamic> json) {
    return DetalleVenta(
      codigoProducto: json['codigo_producto'],
      nombre: json['nombre'],
      cantidad: json['cantidad'],
      precioUnitario: json['precio_unitario'],
      subtotal: json['subtotal'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codigo_producto': codigoProducto,
      'nombre': nombre,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'subtotal': subtotal,
    };
  }
}
