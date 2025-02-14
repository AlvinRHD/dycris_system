class Cliente {
  final int idCliente;
  final String nombre;
  final String? direccion;
  final String? dui;
  final String? nit;

  Cliente({
    required this.idCliente,
    required this.nombre,
    this.direccion,
    this.dui,
    this.nit,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      idCliente: json['idCliente'],
      nombre: json['nombre'],
      direccion: json['direccion'],
      dui: json['dui'],
      nit: json['nit'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idCliente': idCliente,
      'nombre': nombre,
      'direccion': direccion,
      'dui': dui,
      'nit': nit,
    };
  }
}
