import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

import 'agregar_traslado_modal.dart';
import 'traslados_controller.dart';
import 'traslados_model.dart';

class TrasladosScreen extends StatefulWidget {
  @override
  _TrasladosScreenState createState() => _TrasladosScreenState();
}

class _TrasladosScreenState extends State<TrasladosScreen> {
  final TrasladosController _trasladosController = TrasladosController();
  List<Traslado> traslados = [];
  TextEditingController searchController = TextEditingController();
  String? fechaSeleccionada;

  @override
  void initState() {
    super.initState();
    _cargarTraslados();
  }

  Future<void> _cargarTraslados() async {
    final listaTraslados = await _trasladosController.obtenerTraslados();
    setState(() {
      traslados = listaTraslados;
    });
  }

  void _filtrarPorFecha(String fecha) async {
    final listaTraslados =
        await _trasladosController.filtrarTrasladosPorFecha(fecha);
    setState(() {
      traslados = listaTraslados;
    });
  }

  void _mostrarModalAgregarTraslado() {
    showDialog(
      context: context,
      builder: (context) => AgregarTrasladoModal(
        onTrasladoAgregado: () {
          _cargarTraslados();
        },
      ),
    );
  }

  // Función para generar el PDF
  Future<void> _imprimirTraslado(Traslado traslado) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Detalle del Traslado',
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text(
                  'Código de Traslado: ${traslado.codigoTraslado ?? 'N/A'}'),
              pw.Text(
                  'Fecha: ${traslado.fechaTraslado != null ? DateFormat('yyyy-MM-dd').format(traslado.fechaTraslado) : 'N/A'}'),
              pw.Text('Cantidad: ${traslado.cantidad ?? 'N/A'}'),
              pw.Text('Estado: ${traslado.estado ?? 'N/A'}'),
              pw.SizedBox(height: 20),
              pw.Text('Sucursal Origen: ${traslado.origenId ?? 'N/A'}'),
              pw.Text('Sucursal Destino: ${traslado.destinoId ?? 'N/A'}'),
              pw.Text('Empleado: ${traslado.empleadoId ?? 'N/A'}'),
            ],
          );
        },
      ),
    );

    // Imprimir el PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Traslados'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _mostrarModalAgregarTraslado,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(10),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Buscar por fecha (YYYY-MM-DD)',
                prefixIcon: Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (value) {
                setState(() {
                  fechaSeleccionada = value;
                });
                _filtrarPorFecha(value);
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: traslados.length,
              itemBuilder: (context, index) {
                final traslado = traslados[index];
                return ListTile(
                  title: Text('Traslado: ${traslado.codigoTraslado ?? 'N/A'}'),
                  subtitle: Text(
                      'Fecha: ${traslado.fechaTraslado != null ? DateFormat('yyyy-MM-dd').format(traslado.fechaTraslado) : 'N/A'}'),
                  trailing: IconButton(
                    icon: Icon(Icons.print),
                    onPressed: () {
                      _imprimirTraslado(
                          traslado); // Llamar a la función de impresión
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
