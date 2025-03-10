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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      backgroundColor: Colors.grey[50],
      title: Text(
        'Historial de Cambios - Traslado $codigoTraslado',
        style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
      content: Container(
        width: double.maxFinite,
        child: FutureBuilder<List<dynamic>>(
          future: TrasladosApi().getHistorial(trasladoId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}',
                  style: TextStyle(fontSize: 14, color: Colors.red[600]));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Text('No hay cambios registrados',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]));
            }

            final historial = snapshot.data!;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  columnSpacing: 20,
                  columns: const [
                    DataColumn(
                        label: Text('Fecha',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('Campo',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('Antes',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('Después',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold))),
                  ],
                  rows: historial.expand<DataRow>((cambio) {
                    final datosAnteriores = cambio['datos_anteriores'] is String
                        ? jsonDecode(cambio['datos_anteriores'])
                        : cambio['datos_anteriores'] as Map<String, dynamic>;
                    final datosNuevos = cambio['datos_nuevos'] is String
                        ? jsonDecode(cambio['datos_nuevos'])
                        : cambio['datos_nuevos'] as Map<String, dynamic>;
                    final fecha = DateFormat('dd/MM/yyyy HH:mm')
                        .format(DateTime.parse(cambio['fecha_cambio']));

                    List<DataRow> rows = [];

                    datosNuevos.forEach((campo, valorNuevo) {
                      if (campo != 'productos') {
                        final valorAnterior =
                            datosAnteriores[campo]?.toString() ?? 'N/A';
                        final valorNuevoStr = valorNuevo?.toString() ?? 'N/A';
                        if (valorNuevoStr != valorAnterior) {
                          rows.add(DataRow(cells: [
                            DataCell(Text(fecha,
                                style: TextStyle(
                                    fontSize: 14, color: Colors.black87))),
                            DataCell(Text(campo,
                                style: TextStyle(
                                    fontSize: 14, color: Colors.black87))),
                            DataCell(Text(valorAnterior,
                                style: TextStyle(
                                    fontSize: 14, color: Colors.black87))),
                            DataCell(Text(valorNuevoStr,
                                style: TextStyle(
                                    fontSize: 14, color: Colors.black87))),
                          ]));
                        }
                      }
                    });

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
                            productoNuevo['cantidadDespues']?.toString() ??
                                'N/A';

                        final productoAnterior = productosAnteriores.firstWhere(
                          (p) => p['codigo_inventario'] == codigo,
                          orElse: () => {'cantidad': 'N/A'},
                        );
                        final valorAnterior =
                            productoAnterior['cantidad']?.toString() ?? 'N/A';

                        if (cantidadDespues != valorAnterior) {
                          rows.add(DataRow(cells: [
                            DataCell(Text(fecha,
                                style: TextStyle(
                                    fontSize: 14, color: Colors.black87))),
                            DataCell(Text('Cantidad ($codigo)',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.black87))),
                            DataCell(Text(valorAnterior,
                                style: TextStyle(
                                    fontSize: 14, color: Colors.black87))),
                            DataCell(Text(cantidadDespues,
                                style: TextStyle(
                                    fontSize: 14, color: Colors.black87))),
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cerrar',
              style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ),
      ],
    );
  }
}

class DetalleTrasladoWidget extends StatelessWidget {
  final List<dynamic> productos;

  const DetalleTrasladoWidget({required this.productos});

  @override
  Widget build(BuildContext context) {
    if (productos.isEmpty)
      return Text('N/A',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: productos
          .map((p) => Text(
                '${p['producto_nombre']} (Cant: ${p['cantidad']}, Motor: ${p['numero_motor'] ?? 'N/A'}, Chasis: ${p['numero_chasis'] ?? 'N/A'}, Desc: ${p['descripcion'] ?? 'N/A'})',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ))
          .toList(),
    );
  }
}
