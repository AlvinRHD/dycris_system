import 'package:flutter/material.dart';
import '../../../navigation_bar.dart';
import 'cajas_api.dart';

class AgregarCajaScreen extends StatefulWidget {
  const AgregarCajaScreen({super.key});

  @override
  _AgregarCajaScreenState createState() => _AgregarCajaScreenState();
}

class _AgregarCajaScreenState extends State<AgregarCajaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numeroCajaController = TextEditingController();
  String? _sucursalCodigo;
  List<dynamic> _sucursales = [];
  List<dynamic> _cajas = [];

  @override
  void initState() {
    super.initState();
    _cargarSucursales();
    _cargarCajas();
  }

  Future<void> _cargarSucursales() async {
    try {
      final sucursales = await CajasApi().getSucursales();
      setState(() {
        _sucursales = sucursales;
        if (_sucursales.isNotEmpty)
          _sucursalCodigo = _sucursales[0]['codigo'] as String;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar sucursales: $e')));
    }
  }

  Future<void> _cargarCajas() async {
    try {
      final cajas = await CajasApi().getTodasCajas();
      setState(() => _cajas = cajas);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error al cargar cajas: $e')));
    }
  }

  void _agregarCaja() async {
    if (_formKey.currentState!.validate() && _sucursalCodigo != null) {
      try {
        await CajasApi()
            .addCaja(_numeroCajaController.text, _sucursalCodigo!, 'Cerrada');
        _cargarCajas();
        _numeroCajaController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Caja agregada correctamente')));
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error al agregar caja: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomNavigationBar(
      child: Scaffold(
        appBar: AppBar(title: const Text('Agregar Caja')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Nueva Caja',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.25,
                        child: TextFormField(
                          controller: _numeroCajaController,
                          decoration: const InputDecoration(
                            labelText: 'Número de Caja',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'Ingrese un número' : null,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_sucursales.isEmpty)
                        const Center(child: CircularProgressIndicator())
                      else
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.50,
                          child: DropdownButtonFormField<String>(
                            value: _sucursalCodigo,
                            decoration: const InputDecoration(
                              labelText: 'Sucursal',
                              border: OutlineInputBorder(),
                            ),
                            items: _sucursales.map((sucursal) {
                              return DropdownMenuItem<String>(
                                value: sucursal['codigo'] as String,
                                child: Text(
                                    '${sucursal['nombre']} (${sucursal['codigo']})'),
                              );
                            }).toList(),
                            onChanged: (value) =>
                                setState(() => _sucursalCodigo = value),
                            validator: (value) => value == null
                                ? 'Seleccione una sucursal'
                                : null,
                          ),
                        ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.25,
                        child: ElevatedButton(
                          onPressed: _agregarCaja,
                          child: const Text('Agregar Caja'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Cajas Registradas',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Número de Caja')),
                        DataColumn(label: Text('Código Sucursal')),
                        DataColumn(label: Text('Nombre Sucursal')),
                        DataColumn(label: Text('Estado')),
                      ],
                      rows: _cajas.map((caja) {
                        final esCerrada = caja['estado'] == 'Cerrada';
                        return DataRow(cells: [
                          DataCell(Text(caja['numero_caja'] ?? 'N/A')),
                          DataCell(Text(caja['sucursal_codigo'] ?? 'N/A')),
                          DataCell(Text(caja['sucursal_nombre'] ?? 'N/A')),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0, vertical: 4.0),
                              decoration: BoxDecoration(
                                color: esCerrada
                                    ? Colors.red.shade100
                                    : Colors.green.shade100,
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Text(
                                caja['estado'] ?? 'N/A',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _numeroCajaController.dispose();
    super.dispose();
  }
}
