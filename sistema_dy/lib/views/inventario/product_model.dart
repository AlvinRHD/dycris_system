import 'package:intl/intl.dart';

class Product {
  final int id;
  final String codigo;
  final String nombre;
  final String descripcion;
  // ignore: non_constant_identifier_names
  final String nro_motor;
  // ignore: non_constant_identifier_names
  final String nro_chasis;
  final String categoria;
  final String sucursal;
  final double precioCompra;
  final double credito;
  final double precioVenta;
  final int stockExistencia;
  final int stockMinimo;
  final DateTime fechaIngreso;
  final DateTime fechaReingreso;
  final String nroPoliza;
  final String nroLote;

  Product({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.descripcion,
    // ignore: non_constant_identifier_names
    required this.nro_motor,
    // ignore: non_constant_identifier_names
    required this.nro_chasis,
    required this.categoria,
    required this.sucursal,
    required this.precioCompra,
    required this.credito,
    required this.precioVenta,
    required this.stockExistencia,
    required this.stockMinimo,
    required this.fechaIngreso,
    required this.fechaReingreso,
    required this.nroPoliza,
    required this.nroLote,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      codigo: json['codigo'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      nro_motor: json['nro_motor'],
      nro_chasis: json['nro_chasis'],
      categoria: json['categoria'],
      sucursal: json['sucursal'],
      precioCompra: (json['costo'] is String)
          ? double.tryParse(json['costo']) ?? 0.0
          : json['costo'].toDouble(),
      credito: (json['credito'] is String)
          ? double.tryParse(json['credito']) ?? 0.0
          : json['credito'].toDouble(),
      precioVenta: (json['precio_venta'] is String)
          ? double.tryParse(json['precio_venta']) ?? 0.0
          : json['precio_venta'].toDouble(),
      stockExistencia: json['stock_existencia'],
      stockMinimo: json['stock_minimo'],
      fechaIngreso: DateTime.parse(json['fecha_ingreso']),
      fechaReingreso: DateTime.parse(json['fecha_reingreso']),
      nroPoliza: json['nro_poliza'],
      nroLote: json['nro_lote'],
    );
  }

  Map<String, dynamic> toJson() {
    final DateFormat mysqlDateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    return {
      'id': id,
      'codigo': codigo,
      'nombre': nombre,
      'descripcion': descripcion,
      'nro_motor': nro_motor,
      'nro_chasis': nro_chasis,
      'categoria': categoria,
      'sucursal': sucursal,
      'costo': precioCompra,
      'credito': credito,
      'precio_venta': precioVenta,
      'stock_existencia': stockExistencia,
      'stock_minimo': stockMinimo,
      'fecha_ingreso':
          mysqlDateFormat.format(fechaIngreso), // Convertido a MySQL DATETIME
      'fecha_reingreso':
          mysqlDateFormat.format(fechaReingreso), // Convertido a MySQL DATETIME
      'nro_poliza': nroPoliza,
      'nro_lote': nroLote,
    };
  }
}
