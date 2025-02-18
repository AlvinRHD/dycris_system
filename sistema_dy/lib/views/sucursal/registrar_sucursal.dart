import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegistrarSucursal extends StatefulWidget {
  final Function actualizarLista;

  RegistrarSucursal({required this.actualizarLista});

  @override
  _RegistrarSucursalState createState() => _RegistrarSucursalState();
}

class _RegistrarSucursalState extends State<RegistrarSucursal> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController codigoController = TextEditingController();
  TextEditingController nombreController = TextEditingController();

  String selectedPais = 'El Salvador';
  String? selectedDepartamento;
  String? selectedCiudad;
  String selectedEstado = 'Activo'; // Estado por defecto

  final List<String> estados = ['Activo', 'Inactivo'];

  final List<String> departamentos = [
    'Ahuachapán', 'Cabañas', 'Chalatenango', 'Cuscatlán', 'La Libertad', 'La Paz', 'La Unión',
    'Morazán', 'San Miguel', 'San Salvador', 'San Vicente', 'Santa Ana', 'Sonsonate', 'Usulután'
  ];

  final Map<String, List<String>> ciudadesPorDepartamento = {
    'Ahuachapán': [
      'Ahuachapán', 'Apaneca', 'Atiquizaya', 'Concepción de Ataco', 'El Refugio',
      'Guaymango', 'Jujutla', 'San Francisco Menéndez', 'San Lorenzo', 'San Pedro Puxtla',
      'Tacuba', 'Turín'
    ],
    'Cabañas': [
      'Sensuntepeque', 'Cinquera', 'Dolores', 'Guacotecti', 'Ilobasco',
      'Jutiapa', 'San Isidro', 'Tejutepeque', 'Victoria'
    ],
    'Chalatenango': [
      'Chalatenango', 'Agua Caliente', 'Arcatao', 'Azacualpa', 'Cancasque',
      'Comalapa', 'Concepción Quezaltepeque', 'Dulce Nombre de María', 'El Carrizal',
      'El Paraíso', 'La Laguna', 'La Palma', 'La Reina', 'Las Vueltas', 'Nombre de Jesús',
      'Nueva Concepción', 'Nueva Trinidad', 'Ojos de Agua', 'Potonico', 'San Antonio de La Cruz',
      'San Antonio Los Ranchos', 'San Fernando', 'San Francisco Lempa', 'San Francisco Morazán',
      'San Ignacio', 'San Isidro Labrador', 'San Luis del Carmen', 'San Miguel de Mercedes',
      'San Rafael', 'Santa Rita', 'Tejutla'
    ],
    'Cuscatlán': [
      'Cojutepeque', 'Candelaria', 'El Carmen', 'El Rosario', 'Monte San Juan',
      'Oratorio de Concepción', 'San Bartolomé Perulapía', 'San Cristóbal', 'San José Guayabal',
      'San Pedro Perulapán', 'San Rafael Cedros', 'San Ramón', 'Santa Cruz Analquito',
      'Santa Cruz Michapa', 'Suchitoto', 'Tenancingo'
    ],
    'La Libertad': [
      'Santa Tecla', 'Antiguo Cuscatlán', 'Chiltiupán', 'Ciudad Arce', 'Colón',
      'Comasagua', 'Huizúcar', 'Jayaque', 'Jicalapa', 'La Libertad', 'Nuevo Cuscatlán',
      'Quezaltepeque', 'San José Villanueva', 'San Juan Opico', 'San Matías', 'San Pablo Tacachico',
      'Talnique', 'Tamanique', 'Teotepeque', 'Zaragoza'
    ],
    'La Paz': [
      'Zacatecoluca', 'Cuyultitán', 'El Rosario', 'Jerusalén', 'Mercedes La Ceiba',
      'Olocuilta', 'Paraíso de Osorio', 'San Antonio Masahuat', 'San Emigdio', 'San Francisco Chinameca',
      'San Juan Nonualco', 'San Juan Talpa', 'San Juan Tepezontes', 'San Luis La Herradura',
      'San Luis Talpa', 'San Miguel Tepezontes', 'San Pedro Masahuat', 'San Pedro Nonualco',
      'San Rafael Obrajuelo', 'Santa María Ostuma', 'Santiago Nonualco', 'Tapalhuaca'
    ],
    'La Unión': [
      'La Unión', 'Anamorós', 'Bolívar', 'Concepción de Oriente', 'Conchagua',
      'El Carmen', 'El Sauce', 'Intipucá', 'Lislique', 'Meanguera del Golfo', 'Nueva Esparta',
      'Pasaquina', 'Polorós', 'San Alejo', 'San José', 'Santa Rosa de Lima', 'Yayantique',
      'Yucuaiquín'
    ],
    'Morazán': [
      'San Francisco Gotera', 'Arambala', 'Cacaopera', 'Chilanga', 'Corinto',
      'Delicias de Concepción', 'El Divisadero', 'El Rosario', 'Gualococti', 'Guatajiagua',
      'Joateca', 'Jocoaitique', 'Meanguera', 'Osicala', 'Perquín', 'San Carlos',
      'San Fernando', 'San Isidro', 'San Simón', 'Sensembra', 'Sociedad', 'Torola',
      'Yamabal', 'Yoloaiquín'
    ],
    'San Miguel': [
      'San Miguel', 'Carolina', 'Chapeltique', 'Chinameca', 'Chirilagua',
      'Ciudad Barrios', 'Comacarán', 'El Tránsito', 'Lolotique', 'Moncagua', 'Nueva Guadalupe',
      'Nuevo Edén de San Juan', 'Quelepa', 'San Antonio', 'San Gerardo', 'San Jorge',
      'San Luis de la Reina', 'San Rafael Oriente', 'Sesori', 'Uluazapa'
    ],
    'San Salvador': [
      'San Salvador', 'Aguilares', 'Apopa', 'Ayutuxtepeque', 'Ciudad Delgado',
      'Cuscatancingo', 'El Paisnal', 'Guazapa', 'Ilopango', 'Mejicanos', 'Nejapa',
      'Panchimalco', 'Rosario de Mora', 'San Marcos', 'San Martín', 'Santiago Texacuangos',
      'Santo Tomás', 'Soyapango', 'Tonacatepeque'
    ],
    'San Vicente': [
      'San Vicente', 'Apastepeque', 'Guadalupe', 'San Cayetano Istepeque',
      'San Esteban Catarina', 'San Ildefonso', 'San Lorenzo', 'San Sebastián', 'Santa Clara',
      'Santo Domingo', 'Tecoluca', 'Tepetitán', 'Verapaz'
    ],
    'Santa Ana': [
      'Santa Ana', 'Candelaria de la Frontera', 'Chalchuapa', 'Coatepeque',
      'El Congo', 'El Porvenir', 'Masahuat', 'Metapán', 'San Antonio Pajonal',
      'San Sebastián Salitrillo', 'Santa Rosa Guachipilín', 'Santiago de la Frontera',
      'Texistepeque'
    ],
    'Sonsonate': [
      'Sonsonate', 'Acajutla', 'Armenia', 'Caluco', 'Cuisnahuat', 'Izalco',
      'Juayúa', 'Nahuizalco', 'Nahulingo', 'Salcoatitán', 'San Antonio del Monte',
      'San Julián', 'Santa Catarina Masahuat', 'Santo Domingo de Guzmán'
    ],
    'Usulután': [
      'Usulután', 'Alegría', 'Berlín', 'California', 'Concepción Batres',
      'El Triunfo', 'Ereguayquín', 'Estanzuelas', 'Jiquilisco', 'Jucuapa',
      'Jucuarán', 'Mercedes Umaña', 'Nueva Granada', 'Ozatlán', 'Puerto El Triunfo',
      'San Agustín', 'San Buenaventura', 'San Dionisio', 'San Francisco Javier',
      'Santa Elena', 'Santa María', 'Santiago de María', 'Tecapán'
    ],
  };

  Future<void> registrarSucursal() async {
    if (_formKey.currentState!.validate()) {
      final url = Uri.parse('http://localhost:3000/api/sucursal');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'codigo': codigoController.text,
          'nombre': nombreController.text,
          'pais': selectedPais,
          'departamento': selectedDepartamento,
          'ciudad': selectedCiudad,
          'estado': selectedEstado,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sucursal registrada exitosamente')),
        );
        widget.actualizarLista();
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al registrar sucursal')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registrar Sucursal', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTextField(codigoController, 'Código'),
                  _buildTextField(nombreController, 'Nombre'),
                  _buildDropdown('País', [selectedPais], selectedPais, (value) {}),
                  _buildDropdown('Departamento', departamentos, selectedDepartamento, (value) {
                    setState(() {
                      selectedDepartamento = value;
                      selectedCiudad = null;
                    });
                  }),
                  _buildDropdown('Ciudad', selectedDepartamento != null ? ciudadesPorDepartamento[selectedDepartamento!]! : [], selectedCiudad, (value) {
                    setState(() {
                      selectedCiudad = value;
                    });
                  }),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Estado",
                      border: OutlineInputBorder(),
                    ),
                    value: selectedEstado,
                    items: estados.map((estado) => DropdownMenuItem(
                          value: estado,
                          child: Text(estado),
                        )).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedEstado = value!; // Asigna el valor seleccionado a selectedEstado
                      });
                    },
                    validator: (value) => value == null ? "Seleccione un estado" : null,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      textStyle: TextStyle(fontSize: 18),
                      backgroundColor: Colors.blueAccent,
                    ),
                    onPressed: registrarSucursal,
                    child: Text('Registrar', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          filled: true,
          fillColor: Colors.grey[200],
        ),
        validator: (value) => value!.isEmpty ? 'Ingrese $label' : null,
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? selectedItem, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: selectedItem,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          filled: true,
          fillColor: Colors.grey[200],
        ),
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        onChanged: onChanged,
        validator: (value) => value == null ? 'Seleccione $label' : null,
      ),
    );
  }
}