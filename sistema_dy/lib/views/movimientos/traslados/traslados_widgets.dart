import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'traslados_api.dart';

class HistorialCambiosTrasladosDialog extends StatelessWidget {
  final int trasladoId;
  final String codigoTraslado;

  const HistorialCambiosTrasladosDialog({
    required this.trasladoId,
    required this.codigoTraslado,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Historial de Cambios - Traslado $codigoTraslado'),
      content: FutureBuilder<List<dynamic>>(
        future: TrasladosApi().getHistorial(trasladoId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Text('No hay cambios registrados');
          }

          final historial = snapshot.data!;
          print('Historial recibido: $historial'); // Depuración
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                columnSpacing: 20,
                columns: const [
                  DataColumn(label: Text('Fecha')),
                  DataColumn(label: Text('Campo')),
                  DataColumn(label: Text('Antes')),
                  DataColumn(label: Text('Después')),
                ],
                rows: historial.expand<DataRow>((cambio) {
                  // Parsear datos_anteriores y datos_nuevos si son cadenas JSON
                  final datosAnteriores = cambio['datos_anteriores'] is String
                      ? jsonDecode(cambio['datos_anteriores'])
                      : cambio['datos_anteriores'] as Map<String, dynamic>;
                  final datosNuevos = cambio['datos_nuevos'] is String
                      ? jsonDecode(cambio['datos_nuevos'])
                      : cambio['datos_nuevos'] as Map<String, dynamic>;
                  final fecha = DateFormat('dd/MM/yyyy HH:mm')
                      .format(DateTime.parse(cambio['fecha_cambio']));

                  List<DataRow> rows = [];

                  // Manejar campos simples (como estado)
                  datosNuevos.forEach((campo, valorNuevo) {
                    if (campo != 'productos') {
                      final valorAnterior =
                          datosAnteriores[campo]?.toString() ?? 'N/A';
                      final valorNuevoStr = valorNuevo?.toString() ?? 'N/A';
                      if (valorNuevoStr != valorAnterior) {
                        rows.add(DataRow(cells: [
                          DataCell(Text(fecha)),
                          DataCell(Text(campo)),
                          DataCell(Text(valorAnterior)),
                          DataCell(Text(valorNuevoStr)),
                        ]));
                      }
                    }
                  });

                  // Manejar cambios en productos
                  if (datosNuevos['productos'] != null &&
                      datosNuevos['productos'] is List) {
                    final productosNuevos =
                        datosNuevos['productos'] as List<dynamic>;
                    final productosAnteriores =
                        datosAnteriores['productos'] as List<dynamic>? ?? [];

                    for (var productoNuevo in productosNuevos) {
                      final codigo = productoNuevo['codigo_inventario'];
                      final cantidadAntes =
                          productoNuevo['cantidadAntes']?.toString() ?? 'N/A';
                      final cantidadDespues =
                          productoNuevo['cantidadDespues']?.toString() ?? 'N/A';

                      // Buscar el producto anterior correspondiente
                      final productoAnterior = productosAnteriores.firstWhere(
                        (p) => p['codigo_inventario'] == codigo,
                        orElse: () => {'cantidad': 'N/A'},
                      );
                      final valorAnterior =
                          productoAnterior['cantidad']?.toString() ?? 'N/A';

                      if (cantidadDespues != valorAnterior) {
                        rows.add(DataRow(cells: [
                          DataCell(Text(fecha)),
                          DataCell(Text('Cantidad ($codigo)')),
                          DataCell(Text(valorAnterior)),
                          DataCell(Text(cantidadDespues)),
                        ]));
                      }
                    }
                  }

                  return rows;
                }).toList(),
              ),
            ),
          );
        },
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text('Cerrar')),
      ],
    );
  }
}

class DetalleTrasladoWidget extends StatelessWidget {
  final List<dynamic> productos;

  const DetalleTrasladoWidget({required this.productos});

  @override
  Widget build(BuildContext context) {
    if (productos.isEmpty) return Text('N/A');
    return Text(
      productos
          .map((p) => "${p['producto_nombre']} (${p['cantidad']})")
          .join(", "),
      style: TextStyle(fontSize: 14),
    );
  }
}
