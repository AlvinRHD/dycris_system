import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'clientes_api.dart';

class HistorialCambiosClientesDialog extends StatelessWidget {
  final int clienteId;
  final String clienteNombre;

  const HistorialCambiosClientesDialog(
      {required this.clienteId, required this.clienteNombre});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Historial de Cambios - Cliente $clienteNombre'),
      content: FutureBuilder<List<dynamic>>(
        future: ClientesApi().getHistorial(clienteId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Text('No hay cambios registrados');
          }

          final historial = snapshot.data!;
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
                            DataCell(Text(fecha)),
                            DataCell(Text(campo)),
                            DataCell(Text(valorAnterior)),
                            DataCell(Text(valorNuevo)),
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
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text('Cerrar')),
      ],
    );
  }
}
