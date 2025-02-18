class Cliente {
  final int idCliente;
  final String nombre;
  final String? direccion;
  final String? dui;
  final String? nit;
  final String tipoCliente;
  final String? registroContribuyente;
  final String? representanteLegal;
  final String? direccionRepresentante;
  final String? razonSocial;
  final String email;
  final String telefono;
  final String? fechaInicio;
  final String? fechaFin;
  final double? porcentajeRetencion;

  Cliente({
    required this.idCliente,
    required this.nombre,
    this.direccion,
    this.dui,
    this.nit,
    required this.tipoCliente,
    this.registroContribuyente,
    this.representanteLegal,
    this.direccionRepresentante,
    this.razonSocial,
    required this.email,
    required this.telefono,
    this.fechaInicio,
    this.fechaFin,
    this.porcentajeRetencion,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      idCliente: json['idCliente'],
      nombre: json['nombre'],
      direccion: json['direccion'],
      dui: json['dui'],
      nit: json['nit'],
      tipoCliente: json['tipo_cliente'],
      registroContribuyente: json['registro_contribuyente'],
      representanteLegal: json['representante_legal'],
      direccionRepresentante: json['direccion_representante'],
      razonSocial: json['razon_social'],
      email: json['email'],
      telefono: json['telefono'],
      fechaInicio: json['fecha_inicio'],
      fechaFin: json['fecha_fin'],
      porcentajeRetencion: json['porcentaje_retencion']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idCliente': idCliente,
      'nombre': nombre,
      'direccion': direccion,
      'dui': dui,
      'nit': nit,
      'tipo_cliente': tipoCliente,
      'registro_contribuyente': registroContribuyente,
      'representante_legal': representanteLegal,
      'direccion_representante': direccionRepresentante,
      'razon_social': razonSocial,
      'email': email,
      'telefono': telefono,
      'fecha_inicio': fechaInicio,
      'fecha_fin': fechaFin,
      'porcentaje_retencion': porcentajeRetencion,
    };
  }
}
