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
      appBar: AppBar(
        title: Text('Ofertas'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _mostrarModalAgregarOferta,
          ),
        ],
      ),
      body: ofertas.isEmpty
          ? Center(child: Text("No hay ofertas disponibles"))
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Código')),
                  DataColumn(label: Text('Producto')),
                  DataColumn(label: Text('Descuento (%)')),
                  DataColumn(label: Text('Precio Venta')),
                  DataColumn(label: Text('Fecha Inicio')),
                  DataColumn(label: Text('Fecha Fin')),
                  DataColumn(label: Text('Estado')),
                ],
                rows: ofertas.map((oferta) {
                  return DataRow(cells: [
                    DataCell(Text(oferta.id.toString())),
                    DataCell(Text(oferta.codigo)),
                    DataCell(Text(oferta.productoNombre)),
                    DataCell(Text(oferta.descuento.toStringAsFixed(2))),
                    DataCell(Text(oferta.precioVenta.toStringAsFixed(2))),
                    DataCell(Text(
                        DateFormat('yyyy-MM-dd').format(oferta.fechaInicio))),
                    DataCell(
                        Text(DateFormat('yyyy-MM-dd').format(oferta.fechaFin))),
                    DataCell(Text(oferta.estado)),
                  ]);
                }).toList(),
              ),
            ),
    );
  }
}
