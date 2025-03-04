import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../navigation_bar.dart';
import 'cajas_api.dart';

class AperturasCierresScreen extends StatefulWidget {
  @override
  _AperturasCierresScreenState createState() => _AperturasCierresScreenState();
}

class _AperturasCierresScreenState extends State<AperturasCierresScreen> {
  List<dynamic> _aperturasCierres = [];

  @override
  void initState() {
    super.initState();
    _cargarAperturasCierres();
  }

  Future<void> _cargarAperturasCierres() async {
    try {
      final data = await CajasApi().getAperturasCierres();
      setState(() => _aperturasCierres = data);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar aperturas y cierres: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final aperturasActivas = _aperturasCierres
        .where((item) => item['fecha_cierre'] == null)
        .toList();
    final cierresCompletados = _aperturasCierres
        .where((item) => item['fecha_cierre'] != null)
        .toList();

    return CustomNavigationBar(
      child: Scaffold(
        appBar: AppBar(title: const Text('Aperturas y Cierres')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _aperturasCierres.isEmpty
              ? const Center(child: Text('No hay registros'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Aperturas Activas
                      const Text(
                        'Aperturas Activas',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      if (aperturasActivas.isEmpty)
                        const Text('No hay aperturas activas',
                            style: TextStyle(color: Colors.grey))
                      else
                        ...aperturasActivas
                            .map((item) => _buildAperturaCard(item)),

                      const SizedBox(height: 20),

                      // Cierres Completados
                      const Text(
                        'Cierres Completados',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      if (cierresCompletados.isEmpty)
                        const Text('No hay cierres completados',
                            style: TextStyle(color: Colors.grey))
                      else
                        ...cierresCompletados
                            .map((item) => _buildCierreCard(item)),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildAperturaCard(dynamic item) {
    final fechaApertura = DateTime.parse(item['fecha_apertura']);
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${item['numero_caja']} - ${item['sucursal_nombre']}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Estado: ${item['estado']}',
                style: const TextStyle(color: Colors.green)),
            Text(
                'Apertura: ${DateFormat('dd/MM/yyyy HH:mm').format(fechaApertura)}'),
            Text('Monto Apertura: \$${item['monto_apertura'] ?? '0.0'}'),
          ],
        ),
      ),
    );
  }

  Widget _buildCierreCard(dynamic item) {
    final fechaApertura = DateTime.parse(item['fecha_apertura']);
    final fechaCierre = DateTime.parse(item['fecha_cierre']);
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${item['numero_caja']} - ${item['sucursal_nombre']}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Estado: ${item['estado']}',
                style: const TextStyle(color: Colors.red)),
            Text(
                'Apertura: ${DateFormat('dd/MM/yyyy HH:mm').format(fechaApertura)}'),
            Text(
                'Cierre: ${DateFormat('dd/MM/yyyy HH:mm').format(fechaCierre)}'),
            Text('Monto Apertura: \$${item['monto_apertura'] ?? '0.0'}'),
            Text('Total Ventas: \$${item['total_ventas'] ?? 'N/A'}'),
            Text('Efectivo en Caja: \$${item['efectivo_en_caja'] ?? 'N/A'}'),
            if (item['observaciones'] != null &&
                item['observaciones'].isNotEmpty)
              Text('Observaciones: ${item['observaciones']}',
                  style: const TextStyle(fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }
}
