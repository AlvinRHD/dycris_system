import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sistema_dy/views/sucursal/registrar_sucursal.dart';

class MostrarSucursales extends StatefulWidget {
  @override
  _MostrarSucursalesState createState() => _MostrarSucursalesState();
}

class _MostrarSucursalesState extends State<MostrarSucursales> {
  List<dynamic> sucursales = [];
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> sucursalesFiltradas = [];

   final List<String> departamentos = [
    'Ahuachapán',
    'Cabañas',
    'Chalatenango',
    'Cuscatlán',
    'La Libertad',
    'La Paz',
    'La Unión',
    'Morazán',
    'San Miguel',
    'San Salvador',
    'San Vicente',
    'Santa Ana',
    'Sonsonate',
    'Usulután'
  ];

  final Map<String, List<String>> ciudadesPorDepartamento = {
    'Ahuachapán': [
      'Ahuachapán',
      'Apaneca',
      'Atiquizaya',
      'Concepción de Ataco',
      'El Refugio',
      'Guaymango',
      'Jujutla',
      'San Francisco Menéndez',
      'San Lorenzo',
      'San Pedro Puxtla',
      'Tacuba',
      'Turín'
    ],
    'Cabañas': [
      'Sensuntepeque',
      'Cinquera',
      'Dolores',
      'Guacotecti',
      'Ilobasco',
      'Jutiapa',
      'San Isidro',
      'Tejutepeque',
      'Victoria'
    ],
    'Chalatenango': [
      'Chalatenango',
      'Agua Caliente',
      'Arcatao',
      'Azacualpa',
      'Cancasque',
      'Comalapa',
      'Concepción Quezaltepeque',
      'Dulce Nombre de María',
      'El Carrizal',
      'El Paraíso',
      'La Laguna',
      'La Palma',
      'La Reina',
      'Las Vueltas',
      'Nombre de Jesús',
      'Nueva Concepción',
      'Nueva Trinidad',
      'Ojos de Agua',
      'Potonico',
      'San Antonio de La Cruz',
      'San Antonio Los Ranchos',
      'San Fernando',
      'San Francisco Lempa',
      'San Francisco Morazán',
      'San Ignacio',
      'San Isidro Labrador',
      'San Luis del Carmen',
      'San Miguel de Mercedes',
      'San Rafael',
      'Santa Rita',
      'Tejutla'
    ],
    'Cuscatlán': [
      'Cojutepeque',
      'Candelaria',
      'El Carmen',
      'El Rosario',
      'Monte San Juan',
      'Oratorio de Concepción',
      'San Bartolomé Perulapía',
      'San Cristóbal',
      'San José Guayabal',
      'San Pedro Perulapán',
      'San Rafael Cedros',
      'San Ramón',
      'Santa Cruz Analquito',
      'Santa Cruz Michapa',
      'Suchitoto',
      'Tenancingo'
    ],
    'La Libertad': [
      'Santa Tecla',
      'Antiguo Cuscatlán',
      'Chiltiupán',
      'Ciudad Arce',
      'Colón',
      'Comasagua',
      'Huizúcar',
      'Jayaque',
      'Jicalapa',
      'La Libertad',
      'Nuevo Cuscatlán',
      'Quezaltepeque',
      'San José Villanueva',
      'San Juan Opico',
      'San Matías',
      'San Pablo Tacachico',
      'Talnique',
      'Tamanique',
      'Teotepeque',
      'Zaragoza'
    ],
    'La Paz': [
      'Zacatecoluca',
      'Cuyultitán',
      'El Rosario',
      'Jerusalén',
      'Mercedes La Ceiba',
      'Olocuilta',
      'Paraíso de Osorio',
      'San Antonio Masahuat',
      'San Emigdio',
      'San Francisco Chinameca',
      'San Juan Nonualco',
      'San Juan Talpa',
      'San Juan Tepezontes',
      'San Luis La Herradura',
      'San Luis Talpa',
      'San Miguel Tepezontes',
      'San Pedro Masahuat',
      'San Pedro Nonualco',
      'San Rafael Obrajuelo',
      'Santa María Ostuma',
      'Santiago Nonualco',
      'Tapalhuaca'
    ],
    'La Unión': [
      'La Unión',
      'Anamorós',
      'Bolívar',
      'Concepción de Oriente',
      'Conchagua',
      'El Carmen',
      'El Sauce',
      'Intipucá',
      'Lislique',
      'Meanguera del Golfo',
      'Nueva Esparta',
      'Pasaquina',
      'Polorós',
      'San Alejo',
      'San José',
      'Santa Rosa de Lima',
      'Yayantique',
      'Yucuaiquín'
    ],
    'Morazán': [
      'San Francisco Gotera',
      'Arambala',
      'Cacaopera',
      'Chilanga',
      'Corinto',
      'Delicias de Concepción',
      'El Divisadero',
      'El Rosario',
      'Gualococti',
      'Guatajiagua',
      'Joateca',
      'Jocoaitique',
      'Meanguera',
      'Osicala',
      'Perquín',
      'San Carlos',
      'San Fernando',
      'San Isidro',
      'San Simón',
      'Sensembra',
      'Sociedad',
      'Torola',
      'Yamabal',
      'Yoloaiquín'
    ],
    'San Miguel': [
      'San Miguel',
      'Carolina',
      'Chapeltique',
      'Chinameca',
      'Chirilagua',
      'Ciudad Barrios',
      'Comacarán',
      'El Tránsito',
      'Lolotique',
      'Moncagua',
      'Nueva Guadalupe',
      'Nuevo Edén de San Juan',
      'Quelepa',
      'San Antonio',
      'San Gerardo',
      'San Jorge',
      'San Luis de la Reina',
      'San Rafael Oriente',
      'Sesori',
      'Uluazapa'
    ],
    'San Salvador': [
      'San Salvador',
      'Aguilares',
      'Apopa',
      'Ayutuxtepeque',
      'Ciudad Delgado',
      'Cuscatancingo',
      'El Paisnal',
      'Guazapa',
      'Ilopango',
      'Mejicanos',
      'Nejapa',
      'Panchimalco',
      'Rosario de Mora',
      'San Marcos',
      'San Martín',
      'Santiago Texacuangos',
      'Santo Tomás',
      'Soyapango',
      'Tonacatepeque'
    ],
    'San Vicente': [
      'San Vicente',
      'Apastepeque',
      'Guadalupe',
      'San Cayetano Istepeque',
      'San Esteban Catarina',
      'San Ildefonso',
      'San Lorenzo',
      'San Sebastián',
      'Santa Clara',
      'Santo Domingo',
      'Tecoluca',
      'Tepetitán',
      'Verapaz'
    ],
    'Santa Ana': [
      'Santa Ana',
      'Candelaria de la Frontera',
      'Chalchuapa',
      'Coatepeque',
      'El Congo',
      'El Porvenir',
      'Masahuat',
      'Metapán',
      'San Antonio Pajonal',
      'San Sebastián Salitrillo',
      'Santa Rosa Guachipilín',
      'Santiago de la Frontera',
      'Texistepeque'
    ],
    'Sonsonate': [
      'Sonsonate',
      'Acajutla',
      'Armenia',
      'Caluco',
      'Cuisnahuat',
      'Izalco',
      'Juayúa',
      'Nahuizalco',
      'Nahulingo',
      'Salcoatitán',
      'San Antonio del Monte',
      'San Julián',
      'Santa Catarina Masahuat',
      'Santo Domingo de Guzmán'
    ],
    'Usulután': [
      'Usulután',
      'Alegría',
      'Berlín',
      'California',
      'Concepción Batres',
      'El Triunfo',
      'Ereguayquín',
      'Estanzuelas',
      'Jiquilisco',
      'Jucuapa',
      'Jucuarán',
      'Mercedes Umaña',
      'Nueva Granada',
      'Ozatlán',
      'Puerto El Triunfo',
      'San Agustín',
      'San Buenaventura',
      'San Dionisio',
      'San Francisco Javier',
      'Santa Elena',
      'Santa María',
      'Santiago de María',
      'Tecapán'
    ],
  };

  @override
  void initState() {
    super.initState(); 
    fetchSucursales();
    _searchController.addListener(_filterSucursales);
  }

  Future<void> fetchSucursales() async {
    try {
      final response =
          await http.get(Uri.parse('http://localhost:3000/api/sucursal'));

      if (response.statusCode == 200) {
        setState(() {
          sucursales = json.decode(response.body);
          sucursalesFiltradas = sucursales;
        });
      } else {
        throw Exception('Error al cargar sucursales');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void _filterSucursales() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      sucursalesFiltradas = sucursales.where((sucursal) {
        return (sucursal['nombre'] as String).toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> deleteSucursal(int id) async {
    final response =
        await http.delete(Uri.parse('http://localhost:3000/api/sucursal/$id'));

    if (response.statusCode == 200) {
      setState(() {
        sucursales.removeWhere((sucursal) => sucursal['id'] == id);
        sucursalesFiltradas = sucursales;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sucursal eliminada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (response.statusCode == 404) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sucursal no encontrada'),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar la sucursal'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void editSucursal(Map<String, dynamic> sucursal) {
  TextEditingController codigoController =
      TextEditingController(text: sucursal['codigo'] ?? '');
  TextEditingController nombreController =
      TextEditingController(text: sucursal['nombre'] ?? '');
  TextEditingController direccionController =
      TextEditingController(text: sucursal['direccion'] ?? '');
  TextEditingController telefonoController =
      TextEditingController(text: sucursal['telefono'] ?? '');
  TextEditingController gmailController =
      TextEditingController(text: sucursal['gmail'] ?? '');
  TextEditingController paisController =
      TextEditingController(text: sucursal['pais'] ?? '');

  String estadoSeleccionado = sucursal['estado'] ?? 'Inactivo';
  String departamentoSeleccionado = sucursal['departamento'] ?? '';
  String ciudadSeleccionada = sucursal['ciudad'] ?? '';

  // Lista de ciudades según el departamento seleccionado
  List<String> ciudadesDisponibles = ciudadesPorDepartamento[departamentoSeleccionado] ?? [];

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text(
          'Editar Sucursal',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField('Código', Icons.code, codigoController),
              _buildTextField('Nombre', Icons.business, nombreController),
              // Dropdown para seleccionar el departamento
              DropdownButtonFormField<String>(
                value: departamentoSeleccionado,
                decoration: InputDecoration(
                  labelText: 'Departamento',
                  icon: Icon(Icons.map),
                ),
                items: departamentos.map((String departamento) {
                  return DropdownMenuItem<String>(
                    value: departamento,
                    child: Text(departamento),
                  );
                }).toList(),
                onChanged: (String? nuevoDepartamento) {
                  setState(() {
                    departamentoSeleccionado = nuevoDepartamento!;
                    // Actualizar la lista de ciudades según el departamento seleccionado
                    ciudadesDisponibles = ciudadesPorDepartamento[departamentoSeleccionado] ?? [];
                    // Reiniciar la ciudad seleccionada si el departamento cambia
                    ciudadSeleccionada = '';
                  });
                },
              ),
              // Dropdown para seleccionar la ciudad
              DropdownButtonFormField<String>(
                value: ciudadSeleccionada.isNotEmpty ? ciudadSeleccionada : null,
                decoration: InputDecoration(
                  labelText: 'Ciudad',
                  icon: Icon(Icons.location_city),
                ),
                items: ciudadesDisponibles.map((String ciudad) {
                  return DropdownMenuItem<String>(
                    value: ciudad,
                    child: Text(ciudad),
                  );
                }).toList(),
                onChanged: (String? nuevaCiudad) {
                  setState(() {
                    ciudadSeleccionada = nuevaCiudad!;
                  });
                },
              ),
              _buildTextField('Dirección', Icons.business, direccionController),
              _buildTextField('Teléfono', Icons.business, telefonoController),
              _buildTextField('Correo Electrónico', Icons.business, gmailController),
              _buildTextField('País', Icons.public, paisController),
              _buildDropdown('Estado', Icons.toggle_on, estadoSeleccionado,
                  ["Activo", "Inactivo"], (value) {
                setState(() {
                  estadoSeleccionado = value!;
                });
              }),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              updateSucursal(
                sucursal['id'],
                codigoController.text,
                nombreController.text,
                ciudadSeleccionada,
                direccionController.text,
                departamentoSeleccionado,
                telefonoController.text,
                gmailController.text,
                paisController.text,
                estadoSeleccionado,
              );
              Navigator.pop(context);
            },
            child: const Text('Guardar cambios'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      );
    },
  );
}

  Future<void> updateSucursal(int id, String codigo, String nombre,
      String ciudad, String direccion,String departamento, String telefono, String gmail,String pais, String estado) async {
    final response = await http.put(
      Uri.parse('http://localhost:3000/api/sucursal/$id'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "codigo": codigo,
        "nombre": nombre,
        "ciudad": ciudad,
        "direccion": direccion,
        "departamento": departamento,
        "telefono": telefono,
        "gmail": gmail,
        "pais": pais,
        "estado": estado,
      }),
    );

    if (response.statusCode == 200) {
      fetchSucursales();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sucursal actualizada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar la sucursal'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lista de Sucursales',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
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
                        hintText: 'Buscar sucursal...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RegistrarSucursal(
                              actualizarLista: fetchSucursales),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_to_photos, size: 20),
                    label: const Text('Agregar nuevo'),
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
            // Contenedor con la tabla de sucursales
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
                    child: SingleChildScrollView(
                      child: DataTable(
                        columnSpacing: 40,
                        horizontalMargin: 24,
                        headingRowHeight: 56,
                        dataRowHeight: 80,
                        headingRowColor:
                            MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) => Colors.grey[50]!,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black12),
                        ),
                        columns: const [
                          DataColumn(
                              label: Text('Código',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Nombre',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Ciudad',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Dirección',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Departamento',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Telefono',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Correo Electronico',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('País',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Estado',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Acciones',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: sucursalesFiltradas.map((sucursal) {
                          return DataRow(cells: [
                            DataCell(Text(sucursal['codigo'] ?? 'Sin código')),
                            DataCell(Text(sucursal['nombre'] ?? 'Sin nombre')),
                            DataCell(Text(sucursal['ciudad'] ?? 'Sin ciudad')),
                            DataCell(Text(sucursal['direccion'] ?? 'Sin dirección')),
                            DataCell(Text(sucursal['departamento'] ??
                                'Sin departamento')),
                            DataCell(Text(sucursal['telefono'] ?? 'Sin teléfono')),
                            DataCell(Text(sucursal['gmail'] ?? 'Sin gmail')),
                            DataCell(Text(sucursal['pais'] ?? 'Sin país')),
                            DataCell(
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: sucursal['estado'] == 'Activo'
                                      ? Colors.green
                                      : Colors.red,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  sucursal['estado'] ?? 'Sin estado',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            DataCell(Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => editSucursal(sucursal),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Row(
                                          children: [
                                            Icon(Icons.warning,
                                                color: Colors.orange),
                                            SizedBox(width: 8),
                                            Text('Confirmar eliminación'),
                                          ],
                                        ),
                                        content: Text(
                                            '¿Estás seguro de que deseas eliminar esta sucursal?'),
                                        actions: [
                                          TextButton(
                                            child: Text('Cancelar'),
                                            onPressed: () =>
                                                Navigator.pop(context),
                                          ),
                                          TextButton(
                                            child: Text('Eliminar',
                                                style: TextStyle(
                                                    color: Colors.red)),
                                            onPressed: () {
                                              deleteSucursal(sucursal['id']);
                                              Navigator.pop(context);
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            )),
                          ]);
                        }).toList(),
                      ),
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

  Widget _buildTextField(
      String label, IconData icon, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        ),
        textInputAction: TextInputAction.next,
      ),
    );
  }

  Widget _buildDropdown(String label, IconData icon, String value,
      List<String> items, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        ),
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
