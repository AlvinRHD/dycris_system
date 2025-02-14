import 'package:flutter/material.dart';
import 'clientes_controller.dart';
import 'clientes_model.dart';

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
    final clientes = await _clientesController.obtenerClientes();
    setState(() {
      _clientes = clientes;
    });
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

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Editar Cliente'),
          content: Column(
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
            ],
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
      appBar: AppBar(title: Text('Lista de Clientes')),
      body: _clientes.isEmpty
          ? Center(child: Text('No hay clientes disponibles'))
          : ListView.builder(
              itemCount: _clientes.length,
              itemBuilder: (context, index) {
                final cliente = _clientes[index];
                return ListTile(
                  title: Text(cliente.nombre),
                  subtitle: Text(cliente.direccion ?? 'Sin dirección'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editarCliente(cliente),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _eliminarCliente(cliente.idCliente),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
