import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'ofertas_controller.dart';

class AgregarOfertaModal extends StatefulWidget {
  final Function() onOfertaAgregada;

  const AgregarOfertaModal({required this.onOfertaAgregada});

  @override
  _AgregarOfertaModalState createState() => _AgregarOfertaModalState();
}

class _AgregarOfertaModalState extends State<AgregarOfertaModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _inventarioIdController = TextEditingController();
  final TextEditingController _descuentoController = TextEditingController();
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  final OfertasController _ofertasController = OfertasController();

  void _agregarOferta() async {
    if (_formKey.currentState!.validate() &&
        _fechaInicio != null &&
        _fechaFin != null) {
      final inventarioId = int.parse(_inventarioIdController.text);
      final descuento = double.parse(_descuentoController.text);

      await _ofertasController.agregarOferta(
        inventarioId: inventarioId,
        descuento: descuento,
        fechaInicio: _fechaInicio!,
        fechaFin: _fechaFin!,
        context: context,
      );

      widget.onOfertaAgregada();
      Navigator.pop(context);
    }
  }

  Future<void> _seleccionarFechaInicio(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _fechaInicio) {
      setState(() {
        _fechaInicio = picked;
      });
    }
  }

  Future<void> _seleccionarFechaFin(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? DateTime.now(),
      firstDate: _fechaInicio ?? DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _fechaFin) {
      setState(() {
        _fechaFin = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Agregar Oferta"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _inventarioIdController,
                decoration: InputDecoration(labelText: "ID de Inventario"),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "El ID de inventario es obligatorio";
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descuentoController,
                decoration: InputDecoration(labelText: "Descuento (%)"),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "El descuento es obligatorio";
                  }
                  return null;
                },
              ),
              ListTile(
                title: Text(
                    'Fecha de Inicio: ${_fechaInicio != null ? DateFormat('yyyy-MM-dd').format(_fechaInicio!) : "No seleccionada"}'),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _seleccionarFechaInicio(context),
              ),
              ListTile(
                title: Text(
                    'Fecha de Fin: ${_fechaFin != null ? DateFormat('yyyy-MM-dd').format(_fechaFin!) : "No seleccionada"}'),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _seleccionarFechaFin(context),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _agregarOferta,
          child: Text("Guardar"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancelar"),
        ),
      ],
    );
  }
}
