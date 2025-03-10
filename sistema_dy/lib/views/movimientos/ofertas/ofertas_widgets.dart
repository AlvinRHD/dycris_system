import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'ofertas_api.dart';

class HistorialCambiosOfertasDialog extends StatelessWidget {
  final int ofertaId;
  final String codigoOferta;

  const HistorialCambiosOfertasDialog(
      {required this.ofertaId, required this.codigoOferta});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      backgroundColor: Colors.grey[50],
      title: Text(
        'Historial de Cambios - Oferta $codigoOferta',
        style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
      content: Container(
        width: double.maxFinite,
        child: FutureBuilder<List<dynamic>>(
          future: OfertasApi().getHistorial(ofertaId),
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
                    final datosAnteriores =
                        cambio['datos_anteriores'] as Map<String, dynamic>;
                    final datosNuevos =
                        cambio['datos_nuevos'] as Map<String, dynamic>;
                    final fecha = DateFormat('dd/MM/yyyy HH:mm')
                        .format(DateTime.parse(cambio['fecha_cambio']));
                    return datosNuevos.entries
                        .map((entry) {
                          final campo = entry.key;
                          final valorNuevo = entry.value?.toString() ?? 'N/A';
                          final valorAnterior =
                              datosAnteriores[campo]?.toString() ?? 'N/A';
                          if (valorNuevo != valorAnterior) {
                            return DataRow(cells: [
                              DataCell(Text(fecha,
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.black87))),
                              DataCell(Text(campo,
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.black87))),
                              DataCell(Text(valorAnterior,
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.black87))),
                              DataCell(Text(valorNuevo,
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.black87))),
                            ]);
                          }
                          return DataRow(cells: []);
                        })
                        .where((row) => row.cells.isNotEmpty)
                        .toList();
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
