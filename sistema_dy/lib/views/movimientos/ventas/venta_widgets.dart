import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'venta_api.dart';

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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
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
            onPressed: () => Navigator.pop(context), child: Text('Cerrar')),
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
        width: MediaQuery.of(context).size.width * 0.8, // Ancho adaptable
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información General
              _buildSectionTitle('Información General'),
              _buildDetailRow('Código:', venta['codigo_venta'] ?? 'N/A'),
              _buildDetailRow('Fecha:', fechaVenta),
              _buildDetailRow(
                  'Tipo de Factura:', venta['tipo_factura'] ?? 'N/A'),
              _buildDetailRow('Método de Pago:', venta['metodo_pago'] ?? 'N/A'),
              _buildDetailRow('Total:', '\$${total.toStringAsFixed(2)}'),
              _buildDetailRow('Descuento:', '${descuento.toStringAsFixed(2)}%'),
              _buildDetailRow('Descripción:',
                  venta['descripcion_compra'] ?? 'Sin descripción'),
              _buildDetailRow('Empleado:', venta['empleado_nombre'] ?? 'N/A'),
              SizedBox(height: 16),

              // Detalles del Cliente
              _buildSectionTitle('Cliente'),
              _buildDetailRow('Nombre:', venta['cliente_nombre'] ?? 'N/A'),
              _buildDetailRow(
                  'Dirección:', venta['direccion_cliente'] ?? 'Sin dirección'),
              _buildDetailRow('DUI:', venta['dui'] ?? 'Sin DUI'),
              _buildDetailRow('NIT:', venta['nit'] ?? 'Sin NIT'),
              SizedBox(height: 16),

              // Detalles de Productos
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

              // Documentos Asociados
              _buildSectionTitle('Documentos Asociados'),
              _buildDetailRow('Factura:', venta['factura'] ?? 'No disponible'),
              _buildDetailRow('Comprobante Crédito Fiscal:',
                  venta['comprobante_credito_fiscal'] ?? 'No disponible'),
              _buildDetailRow('Factura Exportación:',
                  venta['factura_exportacion'] ?? 'No disponible'),
              _buildDetailRow(
                  'Nota Crédito:', venta['nota_credito'] ?? 'No disponible'),
              _buildDetailRow(
                  'Nota Débito:', venta['nota_debito'] ?? 'No disponible'),
              _buildDetailRow(
                  'Nota Remisión:', venta['nota_remision'] ?? 'No disponible'),
              _buildDetailRow('Comprobante Liquidación:',
                  venta['comprobante_liquidacion'] ?? 'No disponible'),
              _buildDetailRow('Comprobante Retención:',
                  venta['comprobante_retencion'] ?? 'No disponible'),
              _buildDetailRow('Documento Contable:',
                  venta['documento_contable_liquidacion'] ?? 'No disponible'),
              _buildDetailRow('Comprobante Donación:',
                  venta['comprobante_donacion'] ?? 'No disponible'),
              _buildDetailRow('Factura Sujeto Excluido:',
                  venta['factura_sujeto_excluido'] ?? 'No disponible'),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cerrar'),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
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
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              final autorizado =
                  await VentaApi().autorizarDescuento(_codigoController.text);
              Navigator.pop(context,
                  {'autorizado': autorizado, 'codigo': _codigoController.text});
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          },
          child: const Text('Autorizar'),
        ),
      ],
    );
  }
}
