import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'ofertas_api.dart';

class EditarOfertaScreen extends StatefulWidget {
  final Map<String, dynamic> oferta;

  const EditarOfertaScreen({required this.oferta});

  @override
  _EditarOfertaScreenState createState() => _EditarOfertaScreenState();
}

class _EditarOfertaScreenState extends State<EditarOfertaScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descuentoController;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  double? _precioConDescuento;

  @override
  void initState() {
    super.initState();
    _descuentoController = TextEditingController(
        text: widget.oferta['descuento']?.toString() ?? '');
    _fechaInicio = widget.oferta['fecha_inicio'] != null
        ? DateTime.parse(widget.oferta['fecha_inicio'])
        : null;
    _fechaFin = widget.oferta['fecha_fin'] != null
        ? DateTime.parse(widget.oferta['fecha_fin'])
        : null;
    _calcularPrecioConDescuento();
    _descuentoController.addListener(_calcularPrecioConDescuento);
  }

  void _calcularPrecioConDescuento() {
    final precioVenta =
        double.tryParse(widget.oferta['precio_venta'].toString()) ?? 0.0;
    final descuento = double.tryParse(_descuentoController.text) ?? 0.0;
    setState(() {
      _precioConDescuento = precioVenta * (1 - descuento / 100);
    });
  }

  void _guardarCambios() async {
    if (_formKey.currentState!.validate() &&
        _fechaInicio != null &&
        _fechaFin != null) {
      final datosActualizados = {
        'inventario_id': widget.oferta['inventario_id'],
        'descuento': double.parse(_descuentoController.text),
        'fecha_inicio': DateFormat('yyyy-MM-dd HH:mm:ss').format(_fechaInicio!),
        'fecha_fin': DateFormat('yyyy-MM-dd HH:mm:ss').format(_fechaFin!),
      };
      try {
        await OfertasApi().updateOferta(widget.oferta['id'], datosActualizados);
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al actualizar oferta: $e')));
      }
    }
  }

  Future<void> _seleccionarFechaInicio() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(_fechaInicio ?? DateTime.now()));
      if (time != null) {
        setState(() {
          _fechaInicio =
              DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  Future<void> _seleccionarFechaFin() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _fechaFin ?? (_fechaInicio ?? DateTime.now()),
      firstDate: _fechaInicio ?? DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(_fechaFin ?? DateTime.now()));
      if (time != null) {
        setState(() {
          _fechaFin =
              DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Editar Oferta (${widget.oferta['producto_nombre']})"),
        actions: [
          IconButton(icon: Icon(Icons.save), onPressed: _guardarCambios),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Código: ${widget.oferta['codigo_oferta'] ?? 'N/A'}"),
              SizedBox(height: 15),
              Text("Producto: ${widget.oferta['producto_nombre'] ?? 'N/A'}"),
              SizedBox(height: 15),
              Text(
                  "Precio Original: ${widget.oferta['precio_venta'] != null ? '\$${double.tryParse(widget.oferta['precio_venta'].toString())?.toStringAsFixed(2)}' : 'N/A'}"),
              SizedBox(height: 15),
              TextFormField(
                controller: _descuentoController,
                decoration: InputDecoration(
                    labelText: 'Descuento (%)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty || double.tryParse(value) == null
                        ? "Ingrese un número válido"
                        : null,
              ),
              SizedBox(height: 15),
              if (_precioConDescuento != null)
                Text(
                    "Precio con Descuento: \$${_precioConDescuento!.toStringAsFixed(2)}"),
              SizedBox(height: 15),
              ListTile(
                title: Text(
                    'Fecha Inicio: ${_fechaInicio != null ? DateFormat('dd/MM/yyyy HH:mm').format(_fechaInicio!) : "No seleccionada"}'),
                trailing: Icon(Icons.calendar_today),
                onTap: _seleccionarFechaInicio,
              ),
              SizedBox(height: 15),
              ListTile(
                title: Text(
                    'Fecha Fin: ${_fechaFin != null ? DateFormat('dd/MM/yyyy HH:mm').format(_fechaFin!) : "No seleccionada"}'),
                trailing: Icon(Icons.calendar_today),
                onTap: _seleccionarFechaFin,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
