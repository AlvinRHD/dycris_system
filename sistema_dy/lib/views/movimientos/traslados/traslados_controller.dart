import 'package:flutter/material.dart';
import 'traslados_service.dart';
import 'traslados_model.dart';

class TrasladosController {
  final TrasladosService _trasladosService = TrasladosService();

  Future<List<Traslado>> obtenerTraslados() async {
    return await _trasladosService.obtenerTraslados();
  }

  Future<List<Traslado>> filtrarTrasladosPorFecha(String fecha) async {
    return await _trasladosService.filtrarTrasladosPorFecha(fecha);
  }

  Future<void> agregarTraslado(Traslado traslado, BuildContext context) async {
    try {
      await _trasladosService.agregarTraslado(traslado);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Traslado agregado correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al agregar el traslado: $e')),
      );
    }
  }

  Future<void> actualizarTraslado(
      Traslado traslado, BuildContext context) async {
    try {
      await _trasladosService.actualizarTraslado(traslado);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Traslado actualizado correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar el traslado: $e')),
      );
    }
  }

  Future<void> eliminarTraslado(int id, BuildContext context) async {
    try {
      await _trasladosService.eliminarTraslado(id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Traslado eliminado correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar el traslado: $e')),
      );
    }
  }
}
