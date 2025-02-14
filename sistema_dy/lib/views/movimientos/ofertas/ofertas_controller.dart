import 'package:flutter/material.dart';
import 'ofertas_service.dart';
import 'ofertas_model.dart';

class OfertasController {
  final OfertasService _ofertasService = OfertasService();

  Future<List<Oferta>> obtenerOfertas() async {
    return await _ofertasService.obtenerOfertas();
  }

  Future<void> agregarOferta({
    required int inventarioId,
    required double descuento,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required BuildContext context,
  }) async {
    final oferta = Oferta(
      id: 0, // El ID se genera automáticamente en la base de datos
      inventarioId: inventarioId,
      descuento: descuento,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      estado: 'Activa',
      codigo: '', // Estos campos se pueden ajustar según sea necesario
      productoNombre: '',
      precioVenta: 0.0,
    );

    try {
      await _ofertasService.agregarOferta(oferta);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Oferta agregada correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al agregar la oferta: $e')),
      );
    }
  }

  Future<void> actualizarOferta(Oferta oferta, BuildContext context) async {
    try {
      await _ofertasService.actualizarOferta(oferta);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Oferta actualizada correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar la oferta: $e')),
      );
    }
  }

  Future<void> eliminarOferta(int id, BuildContext context) async {
    try {
      await _ofertasService.eliminarOferta(id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Oferta eliminada correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar la oferta: $e')),
      );
    }
  }
}
