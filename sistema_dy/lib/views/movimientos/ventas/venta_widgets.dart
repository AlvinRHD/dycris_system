import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'venta_api.dart';
import 'dart:developer' as developer;

class HistorialCambiosDialog extends StatelessWidget {
  final int ventaId;
  final String codigoVenta;

  const HistorialCambiosDialog(
      {required this.ventaId, required this.codigoVenta});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Historial de Cambios - Venta $codigoVenta'),
      content: FutureBuilder<List<dynamic>>(
        future: VentaApi().getHistorial(ventaId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Text('Error: ${snapshot.error}');
          if (!snapshot.hasData || snapshot.data!.isEmpty)
            return Text('No hay cambios registrados');

          final historial = snapshot.data!;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
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
          );
        },
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text('Cerrar'))
      ],
    );
  }
}

class DetalleVentaDialog extends StatelessWidget {
  final Map<String, dynamic> venta;

  const DetalleVentaDialog({required this.venta});

  @override
  Widget build(BuildContext context) {
    final total = double.tryParse(venta['total']?.toString() ?? '0.0') ?? 0.0;
    final descuento =
        double.tryParse(venta['descuento']?.toString() ?? '0.0') ?? 0.0;
    final fechaVenta = venta['fecha_venta'] != null
        ? DateFormat('dd/MM/yyyy HH:mm')
            .format(DateTime.parse(venta['fecha_venta']))
        : 'N/A';

    return AlertDialog(
      title: Text('Detalle de Venta - ${venta['codigo_venta']}'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Información General'),
              _buildDetailRow('Código:', venta['codigo_venta'] ?? 'N/A'),
              _buildDetailRow('Fecha:', fechaVenta),
              _buildDetailRow('Tipo de DTE:', venta['tipo_dte'] ?? 'N/A'),
              _buildDetailRow('Método de Pago:', venta['metodo_pago'] ?? 'N/A'),
              _buildDetailRow('Total:', '\$${total.toStringAsFixed(2)}'),
              _buildDetailRow('Descuento:', '${descuento.toStringAsFixed(2)}%'),
              _buildDetailRow('Descripción:',
                  venta['descripcion_compra'] ?? 'Sin descripción'),
              _buildDetailRow('Empleado:', venta['empleado_nombre'] ?? 'N/A'),
              SizedBox(height: 16),
              _buildSectionTitle('Cliente'),
              _buildDetailRow('Nombre:', venta['cliente_nombre'] ?? 'N/A'),
              _buildDetailRow(
                  'Dirección:', venta['direccion_cliente'] ?? 'Sin dirección'),
              _buildDetailRow('DUI:', venta['dui'] ?? 'Sin DUI'),
              _buildDetailRow('NIT:', venta['nit'] ?? 'Sin NIT'),
              SizedBox(height: 16),
              _buildSectionTitle('Productos'),
              ...(venta['productos'] as List<dynamic>).map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: ExpansionTile(
                      title: Text(
                          '${p['nombre']} (${p['cantidad']} x \$${p['precio']})'),
                      subtitle: Text(
                          'Subtotal: \$${(p['cantidad'] * p['precio']).toStringAsFixed(2)}'),
                      children: [
                        _buildDetailRow('Código:', p['codigo'] ?? 'N/A',
                            indent: 16),
                        _buildDetailRow('Descripción:',
                            p['descripcion'] ?? 'Sin descripción',
                            indent: 16),
                        _buildDetailRow(
                            'Número de Motor:', p['numero_motor'] ?? 'N/A',
                            indent: 16),
                        _buildDetailRow(
                            'Número de Chasis:', p['numero_chasis'] ?? 'N/A',
                            indent: 16),
                        _buildDetailRow('Categoría:', p['categoria'] ?? 'N/A',
                            indent: 16),
                        _buildDetailRow('Sucursal:', p['sucursal'] ?? 'N/A',
                            indent: 16),
                        _buildDetailRow('Proveedor:', p['proveedor'] ?? 'N/A',
                            indent: 16),
                        _buildDetailRow('Costo:',
                            '\$${p['costo']?.toStringAsFixed(2) ?? 'N/A'}',
                            indent: 16),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text('Cerrar'))
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildDetailRow(String label, String value, {double indent = 0}) {
    return Padding(
      padding: EdgeInsets.only(left: indent, bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class AutorizacionDescuentoModal extends StatelessWidget {
  final Function(Map<String, dynamic>) onAutorizado;

  const AutorizacionDescuentoModal({required this.onAutorizado});

  @override
  Widget build(BuildContext context) {
    final TextEditingController _codigoController = TextEditingController();

    return AlertDialog(
      title: const Text('Autorización de Descuento'),
      content: TextField(
        controller: _codigoController,
        decoration: const InputDecoration(labelText: 'Código del jefe'),
        obscureText: true,
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () async {
            try {
              final autorizado =
                  await VentaApi().autorizarDescuento(_codigoController.text);
              Navigator.pop(context,
                  {'autorizado': autorizado, 'codigo': _codigoController.text});
            } catch (e) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('Error: $e')));
            }
          },
          child: const Text('Autorizar'),
        ),
      ],
    );
  }
}

class ClientePasoModal extends StatelessWidget {
  final Function(Map<String, dynamic>) onClienteAgregado;

  const ClientePasoModal({required this.onClienteAgregado});

  @override
  Widget build(BuildContext context) {
    final TextEditingController _nombreController = TextEditingController();
    final String fechaActual = DateTime.now().toIso8601String().split('T')[0];

    return AlertDialog(
      title: const Text('Cliente de Paso'),
      content: TextField(
        controller: _nombreController,
        decoration: const InputDecoration(labelText: 'Nombre del Cliente'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            final nombre = _nombreController.text.trim();

            if (nombre.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ingrese un nombre')),
              );
              return;
            }

            try {
              developer.log('Llamando a addClientePaso...');
              final cliente = await VentaApi()
                  .addClientePaso(nombre, fecha_inicio: fechaActual);

              onClienteAgregado(cliente);
              Navigator.pop(context);
            } catch (e) {
              developer.log('Error en addClientePaso: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          },
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}
