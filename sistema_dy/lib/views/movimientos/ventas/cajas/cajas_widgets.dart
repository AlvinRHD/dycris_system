import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sistema_dy/views/movimientos/ventas/venta_api.dart';
import 'cajas_api.dart';

class AperturaCajaModal extends StatefulWidget {
  final int usuarioId;
  final Function(int) onAperturaConfirmada;

  const AperturaCajaModal({
    required this.usuarioId,
    required this.onAperturaConfirmada,
  });

  @override
  _AperturaCajaModalState createState() => _AperturaCajaModalState();
}

class _AperturaCajaModalState extends State<AperturaCajaModal> {
  final _montoController = TextEditingController();
  List<dynamic> _cajas = [];
  int? _cajaSeleccionada;

  @override
  void initState() {
    super.initState();
    _cargarCajas();
  }

  Future<void> _cargarCajas() async {
    try {
      final cajas = await CajasApi().getTodasCajas();
      setState(() {
        _cajas = cajas.where((caja) => caja['estado'] == 'Cerrada').toList();
        _cajas.sort(
            (a, b) => a['sucursal_nombre'].compareTo(b['sucursal_nombre']));
        if (_cajas.isNotEmpty) _cajaSeleccionada = _cajas[0]['id'] as int;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error al cargar cajas: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Apertura de Caja'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            if (_cajas.isEmpty)
              const Center(child: CircularProgressIndicator())
            else
              DropdownButtonFormField<int>(
                value: _cajaSeleccionada,
                items: _cajas.map((caja) {
                  return DropdownMenuItem<int>(
                    value: caja['id'] as int,
                    child: Text(
                        '${caja['sucursal_nombre']} - ${caja['numero_caja']}'),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _cajaSeleccionada = value),
                decoration:
                    const InputDecoration(labelText: 'Seleccionar Caja'),
              ),
            TextField(
              controller: _montoController,
              decoration: const InputDecoration(labelText: 'Monto de Apertura'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            Text(
                'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () async {
            final monto = double.tryParse(_montoController.text) ?? 0.0;
            if (_cajaSeleccionada != null && monto >= 0) {
              try {
                final result = await CajasApi()
                    .abrirCaja(_cajaSeleccionada!, widget.usuarioId, monto);
                widget.onAperturaConfirmada(result['id'] as int);
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al abrir caja: $e')));
              }
            }
          },
          child: const Text('Abrir Caja'),
        ),
      ],
    );
  }
}

class CierreCajaModal extends StatefulWidget {
  final int aperturaId;
  final VoidCallback onCierreConfirmado;

  const CierreCajaModal({
    required this.aperturaId,
    required this.onCierreConfirmado,
  });

  @override
  _CierreCajaModalState createState() => _CierreCajaModalState();
}

class _CierreCajaModalState extends State<CierreCajaModal> {
  final _efectivoController = TextEditingController();
  final _observacionesController = TextEditingController();
  double _totalVentas = 0.0;

  @override
  void initState() {
    super.initState();
    _calcularTotalVentas();
  }

  Future<void> _calcularTotalVentas() async {
    try {
      _totalVentas =
          await VentaApi().getTotalVentasPorApertura(widget.aperturaId);
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al calcular ventas: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cierre de Caja'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Ventas: \$${_totalVentas.toStringAsFixed(2)}'),
            TextField(
              controller: _efectivoController,
              decoration: const InputDecoration(labelText: 'Efectivo en Caja'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _observacionesController,
              decoration: const InputDecoration(labelText: 'Observaciones'),
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            Text(
              'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            final efectivo = double.tryParse(_efectivoController.text) ?? 0.0;
            try {
              await CajasApi().cerrarCaja(widget.aperturaId, _totalVentas,
                  efectivo, _observacionesController.text);
              widget.onCierreConfirmado();
              Navigator.pop(context);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error al cerrar caja: $e')),
              );
            }
          },
          child: const Text('Cerrar Caja'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _efectivoController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }
}
