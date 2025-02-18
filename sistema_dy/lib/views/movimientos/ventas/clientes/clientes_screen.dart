import 'package:flutter/material.dart';
import 'clientes_controller.dart';
import 'clientes_model.dart';
import 'agregar_cliente_modal.dart'; // Importa el modal para agregar clientes

class ClientesScreen extends StatefulWidget {
  @override
  _ClientesScreenState createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final ClientesController _clientesController = ClientesController();
  List<Cliente> _clientes = [];

  @override
  void initState() {
    super.initState();
    _cargarClientes();
  }

  Future<void> _cargarClientes() async {
    try {
      final clientes = await _clientesController.obtenerClientes();
      setState(() {
        _clientes = clientes
            .map((cliente) => Cliente(
                  idCliente: cliente.idCliente,
                  nombre: cliente.nombre,
                  direccion: cliente.direccion,
                  dui: cliente.dui,
                  nit: cliente.nit,
                  tipoCliente: cliente.tipoCliente,
                  registroContribuyente: cliente.registroContribuyente,
                  representanteLegal: cliente.representanteLegal,
                  direccionRepresentante: cliente.direccionRepresentante,
                  razonSocial: cliente.razonSocial,
                  email: cliente.email,
                  telefono: cliente.telefono,
                  fechaInicio: cliente.fechaInicio,
                  fechaFin: cliente.fechaFin,
                  porcentajeRetencion: cliente.porcentajeRetencion,
                ))
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar clientes: $e')),
      );
    }
  }

  void _mostrarModalAgregarCliente() {
    showDialog(
      context: context,
      builder: (context) => AgregarClienteModal(
        onClienteAgregado: () {
          _cargarClientes();
        },
      ),
    );
  }

  void _editarCliente(Cliente cliente) {
    TextEditingController nombreController =
        TextEditingController(text: cliente.nombre);
    TextEditingController direccionController =
        TextEditingController(text: cliente.direccion ?? '');
    TextEditingController duiController =
        TextEditingController(text: cliente.dui ?? '');
    TextEditingController nitController =
        TextEditingController(text: cliente.nit ?? '');
    TextEditingController tipoClienteController =
        TextEditingController(text: cliente.tipoCliente);
    TextEditingController registroContribuyenteController =
        TextEditingController(text: cliente.registroContribuyente ?? '');
    TextEditingController representanteLegalController =
        TextEditingController(text: cliente.representanteLegal ?? '');
    TextEditingController direccionRepresentanteController =
        TextEditingController(text: cliente.direccionRepresentante ?? '');
    TextEditingController razonSocialController =
        TextEditingController(text: cliente.razonSocial ?? '');
    TextEditingController emailController =
        TextEditingController(text: cliente.email);
    TextEditingController telefonoController =
        TextEditingController(text: cliente.telefono);
    TextEditingController fechaInicioController =
        TextEditingController(text: cliente.fechaInicio ?? '');
    TextEditingController fechaFinController =
        TextEditingController(text: cliente.fechaFin ?? '');
    TextEditingController porcentajeRetencionController = TextEditingController(
        text: cliente.porcentajeRetencion?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Editar Cliente'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nombreController,
                    decoration: InputDecoration(labelText: 'Nombre')),
                TextField(
                    controller: direccionController,
                    decoration: InputDecoration(labelText: 'Dirección')),
                TextField(
                    controller: duiController,
                    decoration: InputDecoration(labelText: 'DUI')),
                TextField(
                    controller: nitController,
                    decoration: InputDecoration(labelText: 'NIT')),
                TextField(
                    controller: tipoClienteController,
                    decoration: InputDecoration(labelText: 'Tipo Cliente')),
                TextField(
                    controller: registroContribuyenteController,
                    decoration:
                        InputDecoration(labelText: 'Registro Contribuyente')),
                TextField(
                    controller: representanteLegalController,
                    decoration:
                        InputDecoration(labelText: 'Representante Legal')),
                TextField(
                    controller: direccionRepresentanteController,
                    decoration:
                        InputDecoration(labelText: 'Dirección Representante')),
                TextField(
                    controller: razonSocialController,
                    decoration: InputDecoration(labelText: 'Razón Social')),
                TextField(
                    controller: emailController,
                    decoration: InputDecoration(labelText: 'Email')),
                TextField(
                    controller: telefonoController,
                    decoration: InputDecoration(labelText: 'Teléfono')),
                TextField(
                    controller: fechaInicioController,
                    decoration: InputDecoration(labelText: 'Fecha Inicio')),
                TextField(
                    controller: fechaFinController,
                    decoration: InputDecoration(labelText: 'Fecha Fin')),
                TextField(
                    controller: porcentajeRetencionController,
                    decoration:
                        InputDecoration(labelText: 'Porcentaje Retención')),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Cliente clienteActualizado = Cliente(
                  idCliente: cliente.idCliente,
                  nombre: nombreController.text,
                  direccion: direccionController.text,
                  dui: duiController.text,
                  nit: nitController.text,
                  tipoCliente: tipoClienteController.text,
                  registroContribuyente: registroContribuyenteController.text,
                  representanteLegal: representanteLegalController.text,
                  direccionRepresentante: direccionRepresentanteController.text,
                  razonSocial: razonSocialController.text,
                  email: emailController.text,
                  telefono: telefonoController.text,
                  fechaInicio: fechaInicioController.text,
                  fechaFin: fechaFinController.text,
                  porcentajeRetencion:
                      double.tryParse(porcentajeRetencionController.text),
                );
                await _clientesController.actualizarCliente(
                    clienteActualizado, context);
                Navigator.pop(context);
                _cargarClientes();
              },
              child: Text('Guardar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  void _eliminarCliente(int idCliente) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Eliminar Cliente'),
          content: Text('¿Estás seguro de que quieres eliminar este cliente?'),
          actions: [
            TextButton(
              onPressed: () async {
                await _clientesController.eliminarCliente(idCliente, context);
                Navigator.pop(context);
                _cargarClientes();
              },
              child: Text('Eliminar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Fondo gris claro
      appBar: AppBar(
        backgroundColor: Colors.white, // AppBar blanco
        elevation: 0, // Sin elevación
        title: Text(
          'Clientes', // Título 'Clientes'
          style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold), // Título en negro y negrita
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: _mostrarModalAgregarCliente,
              icon: Icon(Icons.add, color: Colors.white),
              label:
                  Text("Nuevo Cliente", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Botón azul
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // Bordes redondeados
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
            color: Colors.white, // Contenedor blanco para la tabla
            borderRadius: BorderRadius.circular(12), // Bordes redondeados
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 6), // Sombra sutil
            ],
          ),
          child: _clientes.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'No hay clientes disponibles', // Mensaje si no hay clientes
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
                          'Lista de Clientes', // Subtítulo para la tabla
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
                              label: Text('Nombre',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Teléfono',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Email',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Tipo Cliente',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Razón Social',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Acciones',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: _clientes.map((cliente) {
                          return DataRow(cells: [
                            DataCell(Text(cliente.idCliente.toString())),
                            DataCell(Text(cliente.nombre)),
                            DataCell(Text(cliente.telefono)),
                            DataCell(Text(cliente.email)),
                            DataCell(Text(cliente.tipoCliente)),
                            DataCell(Text(cliente.razonSocial ?? 'N/A')),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                      icon:
                                          Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _editarCliente(cliente)),
                                  IconButton(
                                      icon:
                                          Icon(Icons.delete, color: Colors.red),
                                      onPressed: () =>
                                          _eliminarCliente(cliente.idCliente)),
                                ],
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
