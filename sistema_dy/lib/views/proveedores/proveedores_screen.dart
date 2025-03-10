import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'registrar_proveedores_screen.dart';
import 'package:flutter/services.dart';

class ProveedoresScreen extends StatefulWidget {
  const ProveedoresScreen({super.key});
  @override
  _ProveedoresScreenState createState() => _ProveedoresScreenState();
}

class _ProveedoresScreenState extends State<ProveedoresScreen> {
  List<Map<String, dynamic>> proveedores = [];
  String _tipoProveedor =
      'Natural'; // Variable para el tipo de proveedor seleccionado

  List<Map<String, dynamic>> get _proveedoresFiltrados {
    return proveedores.where((proveedor) {
      String query = _searchController.text.toLowerCase();
      bool coincideBusqueda = proveedor['nombre_comercial']
              .toString()
              .toLowerCase()
              .contains(query) ||
          proveedor['nombre_propietario']
              .toString()
              .toLowerCase()
              .contains(query) ||
          proveedor['correo'].toString().toLowerCase().contains(query);
      return proveedor['tipo_proveedor'] == _tipoProveedor && coincideBusqueda;
    }).toList();
  }

  Future<void> _fetchProveedores() async {
    final url = Uri.parse('http://localhost:3000/api/proveedores');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          proveedores = data.map((e) => e as Map<String, dynamic>).toList();
        });
      } else {
        throw Exception(
            'Error al cargar los proveedores: ${response.statusCode}');
      }
    } catch (error) {}
  }

  List<DataRow> _generarFilas() {
    return _proveedoresFiltrados.map((proveedor) {
      return DataRow(
        cells: _tipoProveedor == 'Natural'
            ? _celdasNaturales(proveedor)
            : _tipoProveedor == 'Jurídico'
                ? _celdasJuridicos(proveedor)
                : _celdasSujetoExcluido(proveedor),
      );
    }).toList();
  }

  bool _mostrarNaturales = true;
  final TextEditingController _searchController = TextEditingController();

  void _filterProveedores() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _fetchProveedores();
  }

  // Cambiar el Switch por RadioButton
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Proveedores Registrados',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Selector de tipo de proveedor (ahora con RadioButton)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Jurídicos"),
                Radio<String>(
                  value: 'Jurídico',
                  groupValue: _tipoProveedor,
                  onChanged: (value) {
                    setState(() {
                      _tipoProveedor = value!;
                    });
                  },
                ),
                const Text("Naturales"),
                Radio<String>(
                  value: 'Natural',
                  groupValue: _tipoProveedor,
                  onChanged: (value) {
                    setState(() {
                      _tipoProveedor = value!;
                    });
                  },
                ),
                const Text("Sujetos Excluidos"),
                Radio<String>(
                  value: 'Sujeto Excluido',
                  groupValue: _tipoProveedor,
                  onChanged: (value) {
                    setState(() {
                      _tipoProveedor = value!;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Barra de búsqueda
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Buscar proveedor...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        _filterProveedores();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _navegarARegistroProveedor,
                    icon: const Icon(Icons.add_business, size: 20),
                    label: const Text('Nuevo Proveedor'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A2D3E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Contenedor con la tabla de proveedores
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 40,
                      horizontalMargin: 24,
                      headingRowHeight: 56,
                      dataRowHeight: 56,
                      headingRowColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) => Colors.grey[50]!,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black12),
                      ),
                      columns: _tipoProveedor == 'Natural'
                          ? _columnasNaturales()
                          : _tipoProveedor == 'Jurídico'
                              ? _columnasJuridicos()
                              : _columnasSujetoExcluido(),
                      rows: _generarFilas(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<DataColumn> _columnasNaturales() {
    return const [
      DataColumn(
          label: Text('Tipo', style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Nombre comercial',
              style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Nombre propietario',
              style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('DUI', style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('NRC', style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Correo', style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label:
              Text('Teléfono', style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label:
              Text('Dirección', style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Correspondencia',
              style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Giro', style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Rubro', style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label:
              Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
    ];
  }

  List<DataColumn> _columnasJuridicos() {
    return const [
      DataColumn(
          label: Text('Tipo proveedor',
              style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Nombre comercial',
              style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Razón social',
              style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('NIT', style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('NRC', style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Correo', style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label:
              Text('Teléfono', style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label:
              Text('Dirección', style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Correspondencia',
              style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Giro', style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Rubro', style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Nombre representante legal',
              style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Apellidos representante legal',
              style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('DUI representante legal',
              style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('NIT representante legal',
              style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Teléfono representante legal',
              style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Correo representante legal',
              style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Dirección representante legal',
              style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label:
              Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
    ];
  }

  List<DataColumn> _columnasSujetoExcluido() {
    return const [
      DataColumn(
          label: Text('Tipo proveedor',
              style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Nombre comercial',
              style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Nombre propietario',
              style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('DUI', style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Correo', style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label:
              Text('Teléfono', style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label:
              Text('Dirección', style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Correspondencia',
              style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Giro', style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Rubro', style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label:
              Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
    ];
  }

  List<DataCell> _celdasNaturales(Map<String, dynamic> proveedor) {
    return [
      DataCell(Text(proveedor['tipo_proveedor'] ?? '')),
      DataCell(Text(proveedor['nombre_comercial'] ?? '')),
      DataCell(Text(proveedor['nombre_propietario'] ?? '')),
      DataCell(Text(proveedor['dui'] ?? '')),
      DataCell(Text(proveedor['nrc_natural'] ?? '')),
      DataCell(Text(proveedor['correo'] ?? '')),
      DataCell(Text(proveedor['telefono'] ?? '')),
      DataCell(Text(proveedor['direccion'] ?? '')),
      DataCell(Text(proveedor['correspondencia'] ?? '')),
      DataCell(Text(proveedor['giro'] ?? '')),
      DataCell(Text(proveedor['rubro'] ?? '')),
      _accionesProveedorNaturales(proveedor),
    ];
  }

  List<DataCell> _celdasJuridicos(Map<String, dynamic> proveedor) {
    return [
      DataCell(Text(proveedor['tipo_proveedor'] ?? '')),
      DataCell(Text(proveedor['nombre_comercial'] ?? '')),
      DataCell(Text(proveedor['razon_social'] ?? '')),
      DataCell(Text(proveedor['nit'] ?? '')),
      DataCell(Text(proveedor['nrc_juridico'] ?? '')),
      DataCell(Text(proveedor['correo'] ?? '')),
      DataCell(Text(proveedor['telefono'] ?? '')),
      DataCell(Text(proveedor['direccion'] ?? '')),
      DataCell(Text(proveedor['correspondencia'] ?? '')),
      DataCell(Text(proveedor['giro'] ?? '')),
      DataCell(Text(proveedor['rubro'] ?? '')),
      DataCell(Text(proveedor['nombres_representante'] ?? '')),
      DataCell(Text(proveedor['apellidos_representante'] ?? '')),
      DataCell(Text(proveedor['dui_representante'] ?? '')),
      DataCell(Text(proveedor['nit_representante'] ?? '')),
      DataCell(Text(proveedor['telefono_representante'] ?? '')),
      DataCell(Text(proveedor['correo_representante'] ?? '')),
      DataCell(Text(proveedor['direccion_representante'] ?? '')),
      _accionesProveedorJuridicos(proveedor),
    ];
  }

  List<DataCell> _celdasSujetoExcluido(Map<String, dynamic> proveedor) {
    return [
      DataCell(Text(proveedor['tipo_proveedor'] ?? '')),
      DataCell(Text(proveedor['nombre_comercial'] ?? '')),
      DataCell(Text(proveedor['nombre_propietario_excluido'] ?? '')),
      DataCell(Text(proveedor['dui_excluido'] ?? '')),
      DataCell(Text(proveedor['correo'] ?? '')),
      DataCell(Text(proveedor['telefono'] ?? '')),
      DataCell(Text(proveedor['direccion'] ?? '')),
      DataCell(Text(proveedor['correspondencia'] ?? '')),
      DataCell(Text(proveedor['giro'] ?? '')),
      DataCell(Text(proveedor['rubro'] ?? '')),
      _accionesProveedorSujetoExcluido(proveedor),
    ];
  }

  DataCell _accionesProveedorNaturales(Map<String, dynamic> proveedor) {
    return DataCell(
      Row(
        children: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () => _showEditProveedorNaturalDialog(proveedor),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _confirmDelete(proveedor['id']),
          ),
        ],
      ),
    );
  }

  // Botón de acciones para proveedores jurídicos
  DataCell _accionesProveedorJuridicos(Map<String, dynamic> proveedor) {
    return DataCell(
      Row(
        children: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () => _showEditProveedorJuridicoDialog(proveedor),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _confirmDelete(proveedor['id']),
          ),
        ],
      ),
    );
  }

  DataCell _accionesProveedorSujetoExcluido(Map<String, dynamic> proveedor) {
    return DataCell(
      Row(
        children: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () => _showEditProveedorExcluidoDialog(proveedor),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _confirmDelete(proveedor['id']),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Confirmar eliminación'),
          ],
        ),
        content: Text('¿Está seguro de eliminar el proveedor'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: _alertButtonStyle(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: _alertButtonStyle(),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _deleteProveedor(id);
    }
  }

  Future<void> _deleteProveedor(int id) async {
    final url = Uri.parse('http://localhost:3000/api/proveedores/$id');
    try {
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        await _showAlertDialog(
          'Éxito',
          'Proveedor eliminado exitosamente',
          Icons.check_circle,
          Colors.green,
        );
        _fetchProveedores();
      } else {
        await _showAlertDialog(
          'Error',
          'Error al eliminar el proveedor',
          Icons.error,
          Colors.red,
        );
      }
    } catch (e) {
      await _showAlertDialog(
        'Error',
        'Error al eliminar el proveedor: $e',
        Icons.error,
        Colors.red,
      );
    }
  }

  Future<void> _showAlertDialog(
      String title, String message, IconData icon, Color iconColor) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: _alertButtonStyle(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  ButtonStyle _alertButtonStyle() {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.pressed)) {
            return const Color.fromARGB(255, 18, 122, 234).withOpacity(0.15);
          }
          return Theme.of(context).dialogBackgroundColor;
        },
      ),
      foregroundColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          return const Color(0xFF2A2D3E);
        },
      ),
      elevation: WidgetStateProperty.all(0),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 18)),
      overlayColor: WidgetStateProperty.all(Colors.transparent),
    );
  }

  TextInputFormatter nrcFormatter = LengthLimitingTextInputFormatter(20);

  Future<void> _updateProveedorNatural(
    int id,
    String nombre_propietario,
    String dui,
    String nombre_comercial,
    String correo,
    String direccion,
    String telefono,
    String giro,
    String correspondencia,
    String rubro,
    String nrc,
  ) async {
    final url = Uri.parse('http://localhost:3000/api/proveedores/$id');
    final Map<String, dynamic> body = {
      'nombre_propietario': nombre_propietario,
      'dui': dui,
      'nombre_comercial': nombre_comercial,
      'correo': correo,
      'direccion': direccion,
      'telefono': telefono,
      'giro': giro,
      'correspondencia': correspondencia,
      'rubro': rubro,
      'nrc': nrc,
      'tipo_proveedor': "Natural",
    };

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        print('Respuesta del servidor: ${response.body}');
        await _showAlertDialog(
          'Éxito',
          'Proveedor actualizado exitosamente',
          Icons.check_circle,
          Colors.green,
        );
        // Después de actualizar, recarga la lista de proveedores
        _fetchProveedores();
      } else {
        print('Error en la actualización: ${response.body}');
        await _showAlertDialog(
          'Error',
          'Error al actualizar el proveedor 1 ',
          Icons.error,
          Colors.red,
        );
      }
    } catch (e) {
      await _showAlertDialog(
        'Error',
        'Error al actualizar el proveedor 2: $e',
        Icons.error,
        Colors.red,
      );
    }
  }

  Future<void> _showEditProveedorNaturalDialog(
      Map<String, dynamic> proveedorData) async {
    final TextEditingController propietarioController =
        TextEditingController(text: proveedorData['nombre_propietario'] ?? '');
    final TextEditingController duiController =
        TextEditingController(text: proveedorData['dui'] ?? '');
    final TextEditingController nombreController =
        TextEditingController(text: proveedorData['nombre_comercial'] ?? '');
    final TextEditingController correoController =
        TextEditingController(text: proveedorData['correo'] ?? '');
    final TextEditingController direccionController =
        TextEditingController(text: proveedorData['direccion'] ?? '');
    final TextEditingController telefonoController =
        TextEditingController(text: proveedorData['telefono'] ?? '');
    final TextEditingController giroController =
        TextEditingController(text: proveedorData['giro'] ?? '');
    final TextEditingController correspondenciaController =
        TextEditingController(text: proveedorData['correspondencia'] ?? '');
    final TextEditingController rubroController =
        TextEditingController(text: proveedorData['rubro'] ?? '');
    final TextEditingController nrcController =
        TextEditingController(text: proveedorData['nrc_natural'] ?? '');

    return showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return AlertDialog(
              title: const Text(
                'Editar Proveedor Natural',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField('Nombre Comercial',
                              Icons.business, nombreController),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField('Nombre Propietario',
                              Icons.person, propietarioController),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                              'DUI', Icons.credit_card, duiController,
                              keyboardType: TextInputType.number,
                              inputFormatters: duiInputFormatters()),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                              'NRC', Icons.numbers, nrcController,
                              inputFormatters: [nrcFormatter]),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                              'Correo', Icons.email, correoController,
                              keyboardType: TextInputType.emailAddress),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                              'Teléfono', Icons.phone, telefonoController),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField('Dirección', Icons.location_on,
                              direccionController),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField('Correspondencia', Icons.mail,
                              correspondenciaController),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                              'Giro', Icons.business, giroController),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                              'Rubro', Icons.category, rubroController),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    if (proveedorData['id'] == null) {
                      await _showAlertDialog(
                        'Error',
                        'No se pudo obtener el ID del proveedor',
                        Icons.error,
                        Colors.red,
                      );
                      return;
                    }

                    // Validación
                    if (nombreController.text.trim().isEmpty ||
                        propietarioController.text.trim().isEmpty ||
                        duiController.text.trim().isEmpty ||
                        direccionController.text.trim().isEmpty ||
                        telefonoController.text.trim().isEmpty ||
                        correoController.text.trim().isEmpty ||
                        giroController.text.trim().isEmpty ||
                        correspondenciaController.text.trim().isEmpty ||
                        rubroController.text.trim().isEmpty ||
                        nrcController.text.trim().isEmpty) {
                      await _showAlertDialog(
                        'Error',
                        'Todos los campos son obligatorios',
                        Icons.warning,
                        Colors.orange,
                      );
                      return;
                    }

                    // Validación de formato para DUI
                    if (!RegExp(r'^\d{8}-\d$')
                        .hasMatch(duiController.text.trim())) {
                      await _showAlertDialog(
                        'Error',
                        'El DUI debe tener el formato xxxxxxxx-x',
                        Icons.warning,
                        Colors.orange,
                      );
                      return;
                    }

                    // Validación de formato para correo electrónico
                    final RegExp emailRegex = RegExp(
                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                    );
                    if (!emailRegex.hasMatch(correoController.text.trim())) {
                      await _showAlertDialog(
                        'Error',
                        'Ingrese un correo electrónico válido',
                        Icons.warning,
                        Colors.orange,
                      );
                      return;
                    }
                    // Validación de longitud mínima para el teléfono
                    if (telefonoController.text.trim().length < 8) {
                      await _showAlertDialog(
                        'Error',
                        'El número de teléfono debe tener al menos 8 dígitos',
                        Icons.warning,
                        Colors.orange,
                      );
                      return;
                    }
                    await _updateProveedorNatural(
                      proveedorData['id'],
                      propietarioController.text.trim(),
                      duiController.text.trim(),
                      nombreController.text.trim(),
                      correoController.text.trim(),
                      direccionController.text.trim(),
                      telefonoController.text.trim(),
                      giroController.text.trim(),
                      correspondenciaController.text.trim(),
                      rubroController.text.trim(),
                      nrcController.text.trim(),
                    );

                    Navigator.of(context).pop();
                  },
                  style: _alertButtonStyle(),
                  child: const Text('Guardar cambios'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: _alertButtonStyle(),
                  child: const Text('Cancelar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateProveedorJuridico(
    int id,
    String razonSocial,
    String nit,
    String nombreComercial,
    String correo,
    String direccion,
    String telefono,
    String giro,
    String correspondencia,
    String rubro,
    String nrcJuridico,
    String nombresRepresentante,
    String apellidosRepresentante,
    String direccionRepresentante,
    String telefonoRepresentante,
    String duiRepresentante,
    String nitRepresentante,
    String correoRepresentante,
  ) async {
    final url = Uri.parse('http://localhost:3000/api/proveedores/$id');
    final Map<String, dynamic> body = {
      'razon_social': razonSocial,
      'nit': nit,
      'nombre_comercial': nombreComercial,
      'correo': correo,
      'direccion': direccion,
      'telefono': telefono,
      'giro': giro,
      'correspondencia': correspondencia,
      'rubro': rubro,
      'nrc_juridico': nrcJuridico,
      'nombres_representante': nombresRepresentante,
      'apellidos_representante': apellidosRepresentante,
      'direccion_representante': direccionRepresentante,
      'telefono_representante': telefonoRepresentante,
      'dui_representante': duiRepresentante,
      'nit_representante': nitRepresentante,
      'correo_representante': correoRepresentante,
      'tipo_proveedor': "Jurídico",
    };

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        print('Proveedor actualizado exitosamente: ${response.body}');
        await _showAlertDialog(
          'Éxito',
          'Proveedor jurídico actualizado exitosamente',
          Icons.check_circle,
          Colors.green,
        );
        _fetchProveedores();
      } else {
        print('Error en la actualización: ${response.body}');
        await _showAlertDialog(
          'Error',
          'Error al actualizar el proveedor jurídico',
          Icons.error,
          Colors.red,
        );
      }
    } catch (e) {
      await _showAlertDialog(
        'Error',
        'Error al actualizar el proveedor jurídico: $e',
        Icons.error,
        Colors.red,
      );
    }
  }

  Future<void> _showEditProveedorJuridicoDialog(
      Map<String, dynamic> proveedorData) async {
    final TextEditingController razonSocialController =
        TextEditingController(text: proveedorData['razon_social'] ?? '');
    final TextEditingController nitController =
        TextEditingController(text: proveedorData['nit'] ?? '');
    final TextEditingController nombreController =
        TextEditingController(text: proveedorData['nombre_comercial'] ?? '');
    final TextEditingController correoController =
        TextEditingController(text: proveedorData['correo'] ?? '');
    final TextEditingController direccionController =
        TextEditingController(text: proveedorData['direccion'] ?? '');
    final TextEditingController telefonoController =
        TextEditingController(text: proveedorData['telefono'] ?? '');
    final TextEditingController giroController =
        TextEditingController(text: proveedorData['giro'] ?? '');
    final TextEditingController correspondenciaController =
        TextEditingController(text: proveedorData['correspondencia'] ?? '');
    final TextEditingController rubroController =
        TextEditingController(text: proveedorData['rubro'] ?? '');
    final TextEditingController nrcJuridicoController =
        TextEditingController(text: proveedorData['nrc_juridico'] ?? '');
    final TextEditingController nombresRepresentanteController =
        TextEditingController(
            text: proveedorData['nombres_representante'] ?? '');
    final TextEditingController apellidosRepresentanteController =
        TextEditingController(
            text: proveedorData['apellidos_representante'] ?? '');
    final TextEditingController direccionRepresentanteController =
        TextEditingController(
            text: proveedorData['direccion_representante'] ?? '');
    final TextEditingController telefonoRepresentanteController =
        TextEditingController(
            text: proveedorData['telefono_representante'] ?? '');
    final TextEditingController duiRepresentanteController =
        TextEditingController(text: proveedorData['dui_representante'] ?? '');
    final TextEditingController nitRepresentanteController =
        TextEditingController(text: proveedorData['nit_representante'] ?? '');
    final TextEditingController correoRepresentanteController =
        TextEditingController(
            text: proveedorData['correo_representante'] ?? '');

    return showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return AlertDialog(
              title: const Text(
                'Editar Proveedor Jurídico',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    // Sección de información de la empresa
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            'Nombre Comercial',
                            Icons.business,
                            nombreController,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            'Razón Social',
                            Icons.business,
                            razonSocialController,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            'NIT',
                            Icons.credit_card,
                            nitController,
                            keyboardType: TextInputType.number,
                            inputFormatters: nitInputFormatters(),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            'NRC',
                            Icons.assignment,
                            nrcJuridicoController,
                            inputFormatters: [nrcFormatter],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            'Correo',
                            Icons.email,
                            correoController,
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            'Teléfono',
                            Icons.phone,
                            telefonoController,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            'Dirección',
                            Icons.location_on,
                            direccionController,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            'Correspondencia',
                            Icons.mail,
                            correspondenciaController,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            'Giro',
                            Icons.business_center,
                            giroController,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            'Rubro',
                            Icons.category,
                            rubroController,
                          ),
                        ),
                      ],
                    ),

                    // Separación para la información del representante legal
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        'Información del Representante Legal',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            'Nombre Representante',
                            Icons.person,
                            nombresRepresentanteController,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            'Apellidos Representante',
                            Icons.person,
                            apellidosRepresentanteController,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            'DUI Representante',
                            Icons.credit_card,
                            duiRepresentanteController,
                            keyboardType: TextInputType.number,
                            inputFormatters: duiInputFormatters(),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField('NIT Representante',
                              Icons.credit_card, nitRepresentanteController,
                              keyboardType: TextInputType.number,
                              inputFormatters: nitInputFormatters()),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            'Teléfono Representante',
                            Icons.phone,
                            telefonoRepresentanteController,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            'Correo Representante',
                            Icons.email,
                            correoRepresentanteController,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            'Dirección Representante',
                            Icons.location_on,
                            direccionRepresentanteController,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    // Validación de campos
                    if (razonSocialController.text.trim().isEmpty ||
                        nitController.text.trim().isEmpty ||
                        nombreController.text.trim().isEmpty ||
                        correoController.text.trim().isEmpty ||
                        direccionController.text.trim().isEmpty ||
                        telefonoController.text.trim().isEmpty ||
                        giroController.text.trim().isEmpty ||
                        correspondenciaController.text.trim().isEmpty ||
                        rubroController.text.trim().isEmpty ||
                        nrcJuridicoController.text.trim().isEmpty ||
                        nombresRepresentanteController.text.trim().isEmpty ||
                        apellidosRepresentanteController.text.trim().isEmpty ||
                        direccionRepresentanteController.text.trim().isEmpty ||
                        telefonoRepresentanteController.text.trim().isEmpty ||
                        duiRepresentanteController.text.trim().isEmpty ||
                        nitRepresentanteController.text.trim().isEmpty ||
                        correoRepresentanteController.text.trim().isEmpty) {
                      await _showAlertDialog(
                        'Error',
                        'Todos los campos son obligatorios',
                        Icons.warning,
                        Colors.orange,
                      );
                      return;
                    }

// Validación de formato para correo electrónico
                    final RegExp emailRegex = RegExp(
                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                    );

                    if ((correoController.text.trim().isNotEmpty &&
                            !emailRegex
                                .hasMatch(correoController.text.trim())) ||
                        (correoRepresentanteController.text.trim().isNotEmpty &&
                            !emailRegex.hasMatch(
                                correoRepresentanteController.text.trim()))) {
                      await _showAlertDialog(
                        'Error',
                        'Ingrese un correo electrónico válido',
                        Icons.warning,
                        Colors.orange,
                      );
                      return;
                    }

                    // Validación de formato para DUI
                    if (!RegExp(r'^\d{8}-\d$')
                        .hasMatch(duiRepresentanteController.text.trim())) {
                      await _showAlertDialog(
                        'Error',
                        'El DUI debe tener el formato xxxxxxxx-x',
                        Icons.warning,
                        Colors.orange,
                      );
                      return;
                    }

// Validación de longitud mínima para el teléfono
                    if ((telefonoController.text.trim().isNotEmpty &&
                            telefonoController.text.trim().length < 8) ||
                        (telefonoRepresentanteController.text
                                .trim()
                                .isNotEmpty &&
                            telefonoRepresentanteController.text.trim().length <
                                8)) {
                      await _showAlertDialog(
                        'Error',
                        'El número de teléfono debe tener al menos 8 dígitos',
                        Icons.warning,
                        Colors.orange,
                      );
                      return;
                    }

// Validación de formato para NIT (Empresa)
                    if (!RegExp(r'^\d{4}-\d{6}-\d{3}-\d$')
                        .hasMatch(nitController.text.trim())) {
                      await _showAlertDialog(
                        'Error',
                        'El NIT debe tener el formato xxxx-xxxxxx-xxx-x',
                        Icons.warning,
                        Colors.orange,
                      );
                      return;
                    }

// Validación de formato para NIT (Representante)
                    if (!RegExp(r'^\d{4}-\d{6}-\d{3}-\d$')
                        .hasMatch(nitRepresentanteController.text.trim())) {
                      await _showAlertDialog(
                        'Error',
                        'El NIT del representante debe tener el formato xxxx-xxxxxx-xxx-x',
                        Icons.warning,
                        Colors.orange,
                      );
                      return;
                    }

                    // Llamada para actualizar
                    await _updateProveedorJuridico(
                      proveedorData['id'],
                      razonSocialController.text.trim(),
                      nitController.text.trim(),
                      nombreController.text.trim(),
                      correoController.text.trim(),
                      direccionController.text.trim(),
                      telefonoController.text.trim(),
                      giroController.text.trim(),
                      correspondenciaController.text.trim(),
                      rubroController.text.trim(),
                      nrcJuridicoController.text.trim(),
                      nombresRepresentanteController.text.trim(),
                      apellidosRepresentanteController.text.trim(),
                      direccionRepresentanteController.text.trim(),
                      telefonoRepresentanteController.text.trim(),
                      duiRepresentanteController.text.trim(),
                      nitRepresentanteController.text.trim(),
                      correoRepresentanteController.text.trim(),
                    );

                    Navigator.of(context).pop();
                  },
                  style: _alertButtonStyle(),
                  child: const Text('Guardar cambios'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: _alertButtonStyle(),
                  child: const Text('Cancelar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateProveedorExcluido(
    int id,
    String nombre_propietario_excluido,
    String dui_excluido,
    String nombre_comercial,
    String correo,
    String direccion,
    String telefono,
    String giro,
    String correspondencia,
    String rubro,
  ) async {
    final url = Uri.parse('http://localhost:3000/api/proveedores/$id');
    final Map<String, dynamic> body = {
      'nombre_propietario': nombre_propietario_excluido,
      'dui': dui_excluido,
      'nombre_comercial': nombre_comercial,
      'correo': correo,
      'direccion': direccion,
      'telefono': telefono,
      'giro': giro,
      'correspondencia': correspondencia,
      'rubro': rubro,
      'tipo_proveedor': "Sujeto Excluido",
    };

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        print('Respuesta del servidor: ${response.body}');
        await _showAlertDialog(
          'Éxito',
          'Proveedor actualizado exitosamente',
          Icons.check_circle,
          Colors.green,
        );
        // Después de actualizar, recarga la lista de proveedores
        _fetchProveedores();
      } else {
        print('Error en la actualización: ${response.body}');
        await _showAlertDialog(
          'Error',
          'Error al actualizar el proveedor 1',
          Icons.error,
          Colors.red,
        );
      }
    } catch (e) {
      await _showAlertDialog(
        'Error',
        'Error al actualizar el proveedor 2: $e',
        Icons.error,
        Colors.red,
      );
    }
  }

  Future<void> _showEditProveedorExcluidoDialog(
      Map<String, dynamic> proveedorData) async {
    final TextEditingController propietarioController = TextEditingController(
        text: proveedorData['nombre_propietario_excluido'] ?? '');
    final TextEditingController duiController =
        TextEditingController(text: proveedorData['dui_excluido'] ?? '');
    final TextEditingController nombreController =
        TextEditingController(text: proveedorData['nombre_comercial'] ?? '');
    final TextEditingController correoController =
        TextEditingController(text: proveedorData['correo'] ?? '');
    final TextEditingController direccionController =
        TextEditingController(text: proveedorData['direccion'] ?? '');
    final TextEditingController telefonoController =
        TextEditingController(text: proveedorData['telefono'] ?? '');
    final TextEditingController giroController =
        TextEditingController(text: proveedorData['giro'] ?? '');
    final TextEditingController correspondenciaController =
        TextEditingController(text: proveedorData['correspondencia'] ?? '');
    final TextEditingController rubroController =
        TextEditingController(text: proveedorData['rubro'] ?? '');

    return showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return AlertDialog(
              title: const Text(
                'Editar Proveedor Sujeto Excluido',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: _buildTextField('Nombre Comercial',
                                Icons.business, nombreController)),
                        SizedBox(width: 16),
                        Expanded(
                            child: _buildTextField('Nombre Propietario',
                                Icons.person, propietarioController)),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                            child: _buildTextField(
                                'DUI', Icons.credit_card, duiController,
                                keyboardType: TextInputType.number,
                                inputFormatters: duiInputFormatters())),
                        SizedBox(width: 16),
                        Expanded(
                            child: _buildTextField(
                                'Correo', Icons.email, correoController,
                                keyboardType: TextInputType.emailAddress)),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                            child: _buildTextField(
                                'Teléfono', Icons.phone, telefonoController)),
                        SizedBox(width: 16),
                        Expanded(
                            child: _buildTextField('Dirección',
                                Icons.location_on, direccionController)),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                            child: _buildTextField('Correspondencia',
                                Icons.mail, correspondenciaController)),
                        SizedBox(width: 16),
                        Expanded(
                            child: _buildTextField(
                                'Giro', Icons.business, giroController)),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                            child: _buildTextField(
                                'Rubro', Icons.category, rubroController)),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    if (proveedorData['id'] == null) {
                      await _showAlertDialog(
                        'Error',
                        'No se pudo obtener el ID del proveedor',
                        Icons.error,
                        Colors.red,
                      );
                      return;
                    }

                    // Validación
                    if (nombreController.text.trim().isEmpty ||
                        propietarioController.text.trim().isEmpty ||
                        duiController.text.trim().isEmpty ||
                        direccionController.text.trim().isEmpty ||
                        telefonoController.text.trim().isEmpty ||
                        correoController.text.trim().isEmpty ||
                        giroController.text.trim().isEmpty ||
                        correspondenciaController.text.trim().isEmpty ||
                        rubroController.text.trim().isEmpty) {
                      await _showAlertDialog(
                        'Error',
                        'Todos los campos son obligatorios',
                        Icons.warning,
                        Colors.orange,
                      );
                      return;
                    }

                    // Validación de formato para DUI
                    if (!RegExp(r'^\d{8}-\d$')
                        .hasMatch(duiController.text.trim())) {
                      await _showAlertDialog(
                        'Error',
                        'El DUI debe tener el formato xxxxxxxx-x',
                        Icons.warning,
                        Colors.orange,
                      );
                      return;
                    }

                    // Validación de formato para correo electrónico
                    final RegExp emailRegex = RegExp(
                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                    );
                    if (!emailRegex.hasMatch(correoController.text.trim())) {
                      await _showAlertDialog(
                        'Error',
                        'Ingrese un correo electrónico válido',
                        Icons.warning,
                        Colors.orange,
                      );
                      return;
                    }

                    // Validación de longitud mínima para el teléfono
                    if (telefonoController.text.trim().length < 8) {
                      await _showAlertDialog(
                        'Error',
                        'El número de teléfono debe tener al menos 8 dígitos',
                        Icons.warning,
                        Colors.orange,
                      );
                      return;
                    }
                    await _updateProveedorExcluido(
                      proveedorData['id'],
                      propietarioController.text.trim(),
                      duiController.text.trim(),
                      nombreController.text.trim(),
                      correoController.text.trim(),
                      direccionController.text.trim(),
                      telefonoController.text.trim(),
                      giroController.text.trim(),
                      correspondenciaController.text.trim(),
                      rubroController.text.trim(),
                    );

                    Navigator.of(context).pop();
                  },
                  style: _alertButtonStyle(),
                  child: const Text('Guardar cambios'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: _alertButtonStyle(),
                  child: const Text('Cancelar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<TextInputFormatter> duiInputFormatters() {
    return [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(9), // Limita la longitud a 9 caracteres
      TextInputFormatter.withFunction((oldValue, newValue) {
        String newText = newValue.text;
        if (newText.length > 8) {
          // Si el texto tiene más de 8 caracteres, agregar un guion en la posición 8
          newText = newText.substring(0, 8) + '-' + newText.substring(8);
        }
        return TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        );
      }),
    ];
  }

  List<TextInputFormatter> nitInputFormatters() {
    return [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(14),
      TextInputFormatter.withFunction((oldValue, newValue) {
        String newText = newValue.text;
        if (newText.length > 4) {
          newText = newText.substring(0, 4) + '-' + newText.substring(4);
        }

        if (newText.length > 11) {
          newText = newText.substring(0, 11) + '-' + newText.substring(11);
        }

        if (newText.length > 15) {
          newText = newText.substring(0, 15) + '-' + newText.substring(15);
        }

        return TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        );
      }),
    ];
  }

  Widget _buildTextField(
    String label,
    IconData icon,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          prefixIcon: Icon(icon),
        ),
        keyboardType: keyboardType,
        inputFormatters: inputFormatters ??
            (label == 'Teléfono' || label == 'Teléfono Representante'
                ? [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(8),
                  ]
                : []),
        validator: (value) {
          if (value == null || value.isEmpty) {
            if (label == 'Correspondencia') {
              return null;
            }
            return 'Por favor ingrese $label';
          }
          if (label == 'DUI' ||
              label == 'DUI Representante' &&
                  !RegExp(r'^\d{8}-\d$').hasMatch(value)) {
            return 'El DUI debe tener el formato xxxxxxxx-x';
          }
          if (label == 'NIT' ||
              label == 'NIT Representante' &&
                  !RegExp(r'^\d{4}-\d{6}-\d{3}-\d$').hasMatch(value)) {
            return 'El NIT debe tener el formato xxxx-xxxxxx-xxx-x';
          }
          if (label == 'Teléfono' ||
              label == 'Teléfono Representante' &&
                  !RegExp(r'^\d{8}$').hasMatch(value ?? '')) {
            return 'El teléfono es invalido.';
          }
          if (label == 'Correo Electrónico') {
            final RegExp emailRegex = RegExp(
              r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
            );
            if (!emailRegex.hasMatch(value)) {
              return 'Ingrese un correo electrónico válido';
            }
          }
          return null;
        },
      ),
    );
  }

  void _navegarARegistroProveedor() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegistroProveedorScreen()),
    );

    if (resultado == true) {
      _fetchProveedores();
    }
  }
}
