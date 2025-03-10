import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class TrasladoPDF {
  static Future<pw.Document> generateTrasladoPDF(
      Map<String, dynamic> traslado) async {
    final pdf = pw.Document();
    final font = pw.Font.helvetica();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                "Dycris System - Orden de Traslado",
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  font: font,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                "Código de Traslado: ${traslado['codigo_traslado'] ?? 'N/A'}",
                style: pw.TextStyle(fontSize: 16, font: font),
              ),
              pw.Text(
                "Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(traslado['fecha_traslado']))}",
                style: pw.TextStyle(fontSize: 16, font: font),
              ),
              pw.Text(
                "Estado: ${traslado['estado'] ?? 'Pendiente'}",
                style: pw.TextStyle(fontSize: 16, font: font),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                "Origen: ${traslado['sucursal_origen'] ?? traslado['codigo_sucursal_origen'] ?? 'N/A'}",
                style: pw.TextStyle(fontSize: 16, font: font),
              ),
              pw.Text(
                "Destino: ${traslado['sucursal_destino'] ?? traslado['codigo_sucursal_destino'] ?? 'N/A'}",
                style: pw.TextStyle(fontSize: 16, font: font),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                "Empleado: ${traslado['empleado'] ?? 'N/A'}",
                style: pw.TextStyle(fontSize: 16, font: font),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                "Productos:",
                style: pw.TextStyle(
                    fontSize: 18, fontWeight: pw.FontWeight.bold, font: font),
              ),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('Nombre',
                            style: pw.TextStyle(
                                fontSize: 14,
                                font: font,
                                fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('Cantidad',
                            style: pw.TextStyle(
                                fontSize: 14,
                                font: font,
                                fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('Motor',
                            style: pw.TextStyle(
                                fontSize: 14,
                                font: font,
                                fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('Chasis',
                            style: pw.TextStyle(
                                fontSize: 14,
                                font: font,
                                fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('OK',
                            style: pw.TextStyle(
                                fontSize: 14,
                                font: font,
                                fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...((traslado['productos'] as List?) ?? []).map((producto) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(5),
                          child: pw.Text(producto['producto_nombre'] ?? 'N/A',
                              style: pw.TextStyle(fontSize: 12, font: font)),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(5),
                          child: pw.Text(producto['cantidad'].toString(),
                              style: pw.TextStyle(fontSize: 12, font: font)),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(5),
                          child: pw.Text(producto['numero_motor'] ?? 'N/A',
                              style: pw.TextStyle(fontSize: 12, font: font)),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(5),
                          child: pw.Text(producto['numero_chasis'] ?? 'N/A',
                              style: pw.TextStyle(fontSize: 12, font: font)),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(5),
                          child: pw.Text('',
                              style: pw.TextStyle(fontSize: 12, font: font)),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }
}
