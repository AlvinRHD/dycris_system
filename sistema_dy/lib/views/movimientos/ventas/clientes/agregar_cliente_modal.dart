import 'package:flutter/material.dart';
import 'clientes_controller.dart';

class AgregarClienteModal extends StatefulWidget {
  final Function() onClienteAgregado;

  const AgregarClienteModal({required this.onClienteAgregado});

  @override
  _AgregarClienteModalState createState() => _AgregarClienteModalState();
}

class _AgregarClienteModalState extends State<AgregarClienteModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _duiController = TextEditingController();
  final TextEditingController _nitController = TextEditingController();
  final TextEditingController _registroContribuyenteController =
      TextEditingController();
  final TextEditingController _representanteLegalController =
      TextEditingController();
  final TextEditingController _direccionRepresentanteController =
      TextEditingController();
  final TextEditingController _razonSocialController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  final TextEditingController _porcentajeRetencionController =
      TextEditingController();

  final ClientesController _clientesController = ClientesController();

  String _tipoCliente = 'Natural'; // Valor por defecto

  void _agregarCliente() async {
    if (_formKey.currentState!.validate()) {
      await _clientesController.agregarCliente(
        nombre: _nombreController.text,
        direccion: _direccionController.text,
        dui: _duiController.text,
        nit: _nitController.text,
        tipoCliente: _tipoCliente,
        registroContribuyente: _registroContribuyenteController.text,
        representanteLegal: _representanteLegalController.text,
        direccionRepresentante: _direccionRepresentanteController.text,
        razonSocial: _razonSocialController.text,
        email: _emailController.text,
        telefono: _telefonoController.text,
        fechaInicio: _fechaInicio != null
            ? "${_fechaInicio!.year}-${_fechaInicio!.month}-${_fechaInicio!.day}"
            : null,
        fechaFin: _fechaFin != null
            ? "${_fechaFin!.year}-${_fechaFin!.month}-${_fechaFin!.day}"
            : null,

        porcentajeRetencion: _tipoCliente == "Sujeto Excluido"
            ? 10.0
            : null, // Solo para Sujeto Excluido
        context: context,
      );

      widget.onClienteAgregado();
      Navigator.pop(context);
    }
  }

  Future<void> _seleccionarFecha(
      BuildContext context, bool esFechaInicio) async {
    DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (fechaSeleccionada != null) {
      setState(() {
        if (esFechaInicio) {
          _fechaInicio = fechaSeleccionada;
        } else {
          _fechaFin = fechaSeleccionada;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Agregar Cliente"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _tipoCliente,
                onChanged: (String? newValue) {
                  setState(() {
                    _tipoCliente = newValue!;
                  });
                },
                items: [
                  'Consumidor Final',
                  'Contribuyente Jurídico',
                  'Natural',
                  'ONG',
                  'Sujeto Excluido',
                ].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                decoration: InputDecoration(labelText: "Tipo de Cliente"),
              ),
              if (_tipoCliente == "Natural" ||
                  _tipoCliente == "Consumidor Final")
                TextFormField(
                  controller: _nombreController,
                  decoration: InputDecoration(labelText: "Nombre"),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "El nombre es obligatorio";
                    }
                    return null;
                  },
                ),
              if (_tipoCliente == "Consumidor Final")
                TextFormField(
                  controller: _registroContribuyenteController,
                  decoration: InputDecoration(
                      labelText: "Registro Contribuyente (NCR)"),
                ),
              if (_tipoCliente == "Contribuyente Jurídico")
                TextFormField(
                  controller: _representanteLegalController,
                  decoration: InputDecoration(labelText: "Representante Legal"),
                ),
              if (_tipoCliente == "Contribuyente Jurídico")
                TextFormField(
                  controller: _direccionRepresentanteController,
                  decoration: InputDecoration(
                      labelText: "Dirección del Representante Legal"),
                ),
              if (_tipoCliente == "ONG")
                TextFormField(
                  controller: _razonSocialController,
                  decoration: InputDecoration(labelText: "Razón Social"),
                ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: "Email"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "El email es obligatorio";
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _telefonoController,
                decoration: InputDecoration(labelText: "Teléfono"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "El teléfono es obligatorio";
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _direccionController,
                decoration: InputDecoration(labelText: "Dirección"),
              ),
              if (_tipoCliente == "Sujeto Excluido")
                TextFormField(
                  controller: _porcentajeRetencionController,
                  decoration:
                      InputDecoration(labelText: "Porcentaje de Retención"),
                  keyboardType: TextInputType.number,
                  initialValue: "10",
                  enabled: false,
                ),
              InkWell(
                onTap: () => _seleccionarFecha(context, true),
                child: InputDecorator(
                  decoration: InputDecoration(labelText: "Fecha de Inicio"),
                  child: Text(
                    _fechaInicio != null
                        ? "${_fechaInicio!.day}/${_fechaInicio!.month}/${_fechaInicio!.year}"
                        : "Seleccionar Fecha",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
              InkWell(
                onTap: () => _seleccionarFecha(context, false),
                child: InputDecorator(
                  decoration: InputDecoration(labelText: "Fecha de Fin"),
                  child: Text(
                    _fechaFin != null
                        ? "${_fechaFin!.day}/${_fechaFin!.month}/${_fechaFin!.year}"
                        : "Seleccionar Fecha",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _agregarCliente,
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
