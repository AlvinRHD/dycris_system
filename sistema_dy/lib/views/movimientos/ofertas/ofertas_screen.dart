import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'agregar_oferta_modal.dart';
import 'ofertas_controller.dart';
import 'ofertas_model.dart';

class OfertasScreen extends StatefulWidget {
  @override
  _OfertasScreenState createState() => _OfertasScreenState();
}

class _OfertasScreenState extends State<OfertasScreen> {
  final OfertasController _ofertasController = OfertasController();
  List<Oferta> ofertas = [];

  @override
  void initState() {
    super.initState();
    _cargarOfertas();
  }

  Future<void> _cargarOfertas() async {
    try {
      final listaOfertas = await _ofertasController.obtenerOfertas();
      setState(() {
        ofertas = listaOfertas;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar las ofertas: $e')),
      );
    }
  }

  void _mostrarModalAgregarOferta() {
    showDialog(
      context: context,
      builder: (context) => AgregarOfertaModal(
        onOfertaAgregada: () {
          _cargarOfertas();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Ofertas',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: _mostrarModalAgregarOferta,
              icon: Icon(Icons.add, color: Colors.white),
              label:
                  Text("Nueva Oferta", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 6),
            ],
          ),
          child: ofertas.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      "No hay ofertas disponibles",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Ofertas',
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        ),
                      ),
                      DataTable(
                        columnSpacing: 12,
                        headingRowColor: MaterialStateColor.resolveWith(
                            (states) => Colors.grey[200]!),
                        columns: const [
                          DataColumn(
                              label: Text('ID',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Código',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Producto',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Descuento (%)',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Precio Venta',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Fecha Inicio',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Fecha Fin',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Estado',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: ofertas.map((oferta) {
                          return DataRow(cells: [
                            DataCell(Text(oferta.id.toString())),
                            DataCell(Text(oferta.codigo)),
                            DataCell(Text(oferta.productoNombre)),
                            DataCell(Text(
                                "${oferta.descuento.toStringAsFixed(2)}%")),
                            DataCell(Text(
                                "\$${oferta.precioVenta.toStringAsFixed(2)}")),
                            DataCell(Text(DateFormat('yyyy-MM-dd')
                                .format(oferta.fechaInicio))),
                            DataCell(Text(DateFormat('yyyy-MM-dd')
                                .format(oferta.fechaFin))),
                            DataCell(
                              Container(
                                padding: EdgeInsets.symmetric(
                                    vertical: 4, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: oferta.estado == "Activo"
                                      ? Colors.green[100]
                                      : Colors.red[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  oferta.estado,
                                  style: TextStyle(
                                    color: oferta.estado == "Activo"
                                        ? Colors.green[700]
                                        : Colors.red[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ]);
                        }).toList(),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
