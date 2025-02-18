import 'package:flutter/material.dart';
import 'clientes_service.dart';
import 'clientes_model.dart';

class ClientesController {
  final ClientesService _clientesService = ClientesService();

  Future<List<Cliente>> obtenerClientes() async {
    return await _clientesService.obtenerClientes();
  }

  Future<void> agregarCliente({
    required String nombre,
    String? direccion,
    String? dui,
    String? nit,
    required String tipoCliente,
    String? registroContribuyente,
    String? representanteLegal,
    String? direccionRepresentante,
    String? razonSocial,
    required String email,
    required String telefono,
    String? fechaInicio,
    String? fechaFin,
    double? porcentajeRetencion,
    required BuildContext context,
  }) async {
    final cliente = Cliente(
      idCliente: 0,
      nombre: nombre,
      direccion: direccion,
      dui: dui,
      nit: nit,
      tipoCliente: tipoCliente,
      registroContribuyente: registroContribuyente,
      representanteLegal: representanteLegal,
      direccionRepresentante: direccionRepresentante,
      razonSocial: razonSocial,
      email: email,
      telefono: telefono,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      porcentajeRetencion: porcentajeRetencion,
    );

    try {
      await _clientesService.agregarCliente(cliente);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cliente agregado correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al agregar cliente: $e')),
      );
    }
  }

  Future<void> actualizarCliente(Cliente cliente, BuildContext context) async {
    try {
      await _clientesService.actualizarCliente(cliente);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cliente actualizado correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar cliente: $e')),
      );
    }
  }

  Future<void> eliminarCliente(int idCliente, BuildContext context) async {
    try {
      await _clientesService.eliminarCliente(idCliente);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cliente eliminado correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar cliente: $e')),
      );
    }
  }
}
