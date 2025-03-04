import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'cajas/cajas_api.dart';
import 'cajas/cajas_widgets.dart';
import 'venta_api.dart';
import 'venta_widgets.dart';
import 'auth_helper.dart';
import '../../navigation_bar.dart';
import 'dart:developer' as developer;
import 'dart:async';

class AgregarVentaScreen extends StatefulWidget {
  const AgregarVentaScreen({super.key});

  @override
  _AgregarVentaScreenState createState() => _AgregarVentaScreenState();
}

class _AgregarVentaScreenState extends State<AgregarVentaScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _clienteController = TextEditingController();
  final TextEditingController _notasController = TextEditingController();
  final TextEditingController _descuentoController = TextEditingController();
  final TextEditingController _subtotalController = TextEditingController();
  final TextEditingController _ivaController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();
  final TextEditingController _busquedaProductoController =
      TextEditingController();

  // Controladores para DTE (sin cambios)
  final TextEditingController _facturaController = TextEditingController();
  final TextEditingController _comprobanteCreditoFiscalController =
      TextEditingController();
  final TextEditingController _facturaExportacionController =
      TextEditingController();
  final TextEditingController _notaCreditoController = TextEditingController();
  final TextEditingController _notaDebitoController = TextEditingController();
  final TextEditingController _notaRemisionController = TextEditingController();
  final TextEditingController _comprobanteLiquidacionController =
      TextEditingController();
  final TextEditingController _comprobanteRetencionController =
      TextEditingController();
  final TextEditingController _documentoContableLiquidacionController =
      TextEditingController();
  final TextEditingController _comprobanteDonacionController =
      TextEditingController();
  final TextEditingController _facturaSujetoExcluidoController =
      TextEditingController();

  List<dynamic> _clientes = [];
  List<dynamic> _productos = [];
  Map<String, dynamic>? _clienteSeleccionado;
  Map<String, dynamic>? _loggedInUser;
  String? _tipoFactura;
  String? _metodoPago;
  List<Map<String, dynamic>> _carrito = [];
  int? _aperturaId;
  FocusNode _clienteFocusNode = FocusNode();
  DateTime? _fechaApertura;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _initialize();
    _clienteController.addListener(_buscarClientes);
    _descuentoController.addListener(_calcularTotal);
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {}); // Actualiza el tiempo activo cada segundo
    });
  }

  Future<void> _initialize() async {
    await _loadUserAndCheckApertura();
    await _cargarProductos();
    await _cargarFechaApertura();
  }

  Future<void> _cargarFechaApertura() async {
    if (_aperturaId != null) {
      try {
        _fechaApertura = await CajasApi().getFechaApertura(_aperturaId!);
        setState(() {});
      } catch (e) {
        developer.log('Error al cargar fecha de apertura: $e');
      }
    }
  }

  Future<void> _loadUserAndCheckApertura() async {
    _loggedInUser = await AuthHelper.getLoggedInUser();
    if (_loggedInUser == null || _loggedInUser!['id'] == null) {
      developer.log(
          'Usuario no logueado o sin ID válido en usuarios: $_loggedInUser');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor, inicie sesión con un usuario válido')),
      );
      return;
    }
    try {
      final aperturas = await CajasApi().getAperturasActivas();
      developer.log('Aperturas activas: $aperturas');
      if (aperturas.isEmpty) {
        _mostrarModalApertura();
      } else {
        setState(() => _aperturaId = aperturas[0]['id'] as int);
      }
    } catch (e) {
      developer.log('Error al verificar aperturas: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al verificar aperturas: $e')),
      );
      _mostrarModalApertura();
    }
  }

  void _mostrarModalApertura() {
    if (_loggedInUser == null || _loggedInUser!['id'] == null) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AperturaCajaModal(
        usuarioId: _loggedInUser!['id'] as int,
        onAperturaConfirmada: (int aperturaId) {
          setState(() => _aperturaId = aperturaId);
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _cargarProductos() async {
    try {
      final productos = await VentaApi().searchProductos();
      developer.log('Productos cargados al inicio: $productos');
      setState(() => _productos = productos);
    } catch (e) {
      developer.log('Error al cargar productos: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar productos: $e')),
      );
    }
  }

  void _buscarClientes() async {
    if (_clienteSeleccionado != null) return;
    final query = _clienteController.text.trim();
    if (query.isEmpty) {
      setState(() => _clientes = []);
      return;
    }
    try {
      final clientes = await VentaApi().searchClientes(query);
      setState(() => _clientes = clientes);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al buscar clientes: $e')),
      );
    }
  }

  void _seleccionarCliente(Map<String, dynamic> cliente) {
    setState(() {
      _clienteSeleccionado = cliente;
      _clienteController.text = cliente['nombre'];
      _clientes = [];
    });
    FocusScope.of(context).unfocus();
  }

  void _agregarAlCarrito(Map<String, dynamic> producto) {
    setState(() {
      final index = _carrito
          .indexWhere((p) => p['codigo_producto'] == producto['codigo']);
      if (index != -1) {
        if (_carrito[index]['cantidad'] + 1 > producto['stock_existencia']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Stock insuficiente para ${producto['nombre']}')),
          );
          return;
        }
        _carrito[index]['cantidad']++;
        _carrito[index]['subtotal'] =
            _carrito[index]['cantidad'] * _carrito[index]['precio_unitario'];
      } else {
        if (producto['stock_existencia'] < 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Stock insuficiente para ${producto['nombre']}')),
          );
          return;
        }
        _carrito.add({
          'codigo_producto': producto['codigo'],
          'nombre': producto['nombre'],
          'cantidad': 1,
          'precio_unitario': double.parse(producto['precio_venta'].toString()),
          'subtotal': double.parse(producto['precio_venta'].toString()),
        });
      }
      _calcularTotal();
    });
  }

  void _modificarCantidad(int index, int cambio) {
    setState(() {
      final producto = _carrito[index];
      final nuevoCantidad = producto['cantidad'] + cambio;
      final productoInfo = _productos
          .firstWhere((p) => p['codigo'] == producto['codigo_producto']);
      if (nuevoCantidad <= 0) {
        _carrito.removeAt(index);
      } else if (nuevoCantidad > productoInfo['stock_existencia']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Stock insuficiente: ${productoInfo['stock_existencia']} disponibles')),
        );
        return;
      } else {
        producto['cantidad'] = nuevoCantidad;
        producto['subtotal'] = nuevoCantidad * producto['precio_unitario'];
      }
      _calcularTotal();
    });
  }

  void _calcularTotal() {
    double subtotal = _carrito.fold(0.0, (sum, p) => sum + p['subtotal']);
    double descuento = double.tryParse(_descuentoController.text) ?? 0.0;
    if (descuento < 0 || descuento > 100) descuento = 0.0;
    double subtotalConDescuento = subtotal * (1 - descuento / 100);
    double iva = subtotalConDescuento * 0.13;
    double total = subtotalConDescuento + iva;

    setState(() {
      _subtotalController.text = subtotal.toStringAsFixed(2);
      _ivaController.text = iva.toStringAsFixed(2);
      _totalController.text = total.toStringAsFixed(2);
    });
  }

  void _procesarVenta() async {
    if (_formKey.currentState!.validate() &&
        _carrito.isNotEmpty &&
        _aperturaId != null) {
      double descuento = double.tryParse(_descuentoController.text) ?? 0.0;
      String? codigoAutorizacion;

      if (descuento > 0 &&
          _loggedInUser!['tipo_cuenta'] != 'Admin' &&
          _loggedInUser!['tipo_cuenta'] != 'Root') {
        final result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) => AutorizacionDescuentoModal(
            onAutorizado: (result) {},
          ),
        );
        if (result == null || !result['autorizado']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Autorización de descuento fallida')),
          );
          return;
        }
        codigoAutorizacion = result['codigo'];
      }

      final venta = {
        'cliente_id': _clienteSeleccionado!['idCliente'],
        'empleado_id': _loggedInUser!['empleado_id'] as int,
        'tipo_factura': _tipoFactura ?? 'Consumidor Final',
        'metodo_pago': _metodoPago ?? 'Efectivo',
        'total': double.parse(_totalController.text),
        'descuento': descuento,
        'descripcion_compra': _notasController.text,
        'productos': _carrito,
        'apertura_id': _aperturaId,
        if (_facturaController.text.isNotEmpty)
          'factura': _facturaController.text,
        if (_comprobanteCreditoFiscalController.text.isNotEmpty)
          'comprobante_credito_fiscal':
              _comprobanteCreditoFiscalController.text,
        if (_facturaExportacionController.text.isNotEmpty)
          'factura_exportacion': _facturaExportacionController.text,
        if (_notaCreditoController.text.isNotEmpty)
          'nota_credito': _notaCreditoController.text,
        if (_notaDebitoController.text.isNotEmpty)
          'nota_debito': _notaDebitoController.text,
        if (_notaRemisionController.text.isNotEmpty)
          'nota_remision': _notaRemisionController.text,
        if (_comprobanteLiquidacionController.text.isNotEmpty)
          'comprobante_liquidacion': _comprobanteLiquidacionController.text,
        if (_comprobanteRetencionController.text.isNotEmpty)
          'comprobante_retencion': _comprobanteRetencionController.text,
        if (_documentoContableLiquidacionController.text.isNotEmpty)
          'documento_contable_liquidacion':
              _documentoContableLiquidacionController.text,
        if (_comprobanteDonacionController.text.isNotEmpty)
          'comprobante_donacion': _comprobanteDonacionController.text,
        if (_facturaSujetoExcluidoController.text.isNotEmpty)
          'factura_sujeto_excluido': _facturaSujetoExcluidoController.text,
        if (codigoAutorizacion != null)
          'codigo_autorizacion': codigoAutorizacion,
      };

      try {
        await VentaApi().addVenta(venta);
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Venta procesada correctamente')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al procesar venta: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Seleccione un cliente, añada productos y asegure una apertura activa')),
      );
    }
  }

  Future<bool> _onWillPop() async {
    if (_aperturaId != null) {
      final confirmarCierre = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('¿Cerrar Caja?'),
          content: const Text(
              'Hay una caja abierta. ¿Desea cerrarla ahora o dejarla abierta?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Dejar Abierta'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _mostrarModalCierreCaja();
                Navigator.pop(context, true);
              },
              child: const Text('Cerrar Caja'),
            ),
          ],
        ),
      );
      return confirmarCierre ?? false;
    }
    return true;
  }

  Future<void> _mostrarModalCierreCaja() async {
    if (_aperturaId != null) {
      showDialog(
        context: context,
        builder: (context) => CierreCajaModal(
          aperturaId: _aperturaId!,
          onCierreConfirmado: () {
            setState(() => _aperturaId = null);
            Navigator.pop(context);
          },
        ),
      );
    }
  }

  String _calcularTiempoActivo() {
    if (_fechaApertura == null) return 'N/A';
    final diferencia = DateTime.now().difference(_fechaApertura!);
    final horas = diferencia.inHours;
    final minutos = diferencia.inMinutes % 60;
    final segundos = diferencia.inSeconds % 60;
    return '$horas:${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Punto de Venta'),
        actions: [
          if (_aperturaId != null)
            ElevatedButton.icon(
              icon: const Icon(Icons.lock, color: Colors.black),
              label: const Text('Cierre de Caja',
                  style: TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow),
              onPressed: _mostrarModalCierreCaja,
            ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
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
                            const Text('Cliente',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: TextFormField(
                                controller: _clienteController,
                                focusNode: _clienteFocusNode,
                                decoration: const InputDecoration(
                                  labelText: 'Buscar Cliente',
                                  prefixIcon: Icon(Icons.person),
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) => _buscarClientes(),
                                validator: (value) =>
                                    _clienteSeleccionado == null
                                        ? 'Seleccione un cliente'
                                        : null,
                              ),
                            ),
                            if (_clientes.isNotEmpty)
                              SizedBox(
                                height: 100,
                                child: ListView.builder(
                                  itemCount: _clientes.length,
                                  itemBuilder: (context, index) => ListTile(
                                    title: Text(_clientes[index]['nombre']),
                                    onTap: () =>
                                        _seleccionarCliente(_clientes[index]),
                                  ),
                                ),
                              ),
                            if (_clienteSeleccionado != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Cliente: ${_clienteSeleccionado!['nombre']}',
                                  style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: DropdownButtonFormField<String>(
                                value: _tipoFactura,
                                decoration: const InputDecoration(
                                  labelText: 'Tipo de Factura',
                                  border: OutlineInputBorder(),
                                ),
                                items: [
                                  'Consumidor Final',
                                  'Crédito Fiscal',
                                  'Ticket'
                                ]
                                    .map((tipo) => DropdownMenuItem(
                                        value: tipo, child: Text(tipo)))
                                    .toList(),
                                onChanged: (value) =>
                                    setState(() => _tipoFactura = value),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: DropdownButtonFormField<String>(
                                value: _metodoPago,
                                decoration: const InputDecoration(
                                  labelText: 'Método de Pago',
                                  border: OutlineInputBorder(),
                                ),
                                items: [
                                  'Efectivo',
                                  'Tarjeta de Crédito',
                                  'Transferencia Bancaria'
                                ]
                                    .map((metodo) => DropdownMenuItem(
                                        value: metodo, child: Text(metodo)))
                                    .toList(),
                                onChanged: (value) =>
                                    setState(() => _metodoPago = value),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: TextFormField(
                                controller: _notasController,
                                decoration: const InputDecoration(
                                  labelText: 'Notas (Opcional)',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: TextFormField(
                                controller: _descuentoController,
                                decoration: const InputDecoration(
                                  labelText: 'Descuento (%) (Opcional)',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return null;
                                  final descuento = double.tryParse(value);
                                  if (descuento == null ||
                                      descuento < 0 ||
                                      descuento > 100) {
                                    return 'Descuento debe estar entre 0 y 100';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_aperturaId != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hora Actual: ${DateFormat('HH:mm:ss').format(DateTime.now())}',
                            style: const TextStyle(
                                fontSize: 20,
                                color: Colors.green,
                                fontWeight: FontWeight.bold),
                          ),
                          if (_fechaApertura != null)
                            Text(
                              'Tiempo Activo: ${_calcularTiempoActivo()}',
                              style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8.0),
                    height: 250,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Carrito',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _carrito.length,
                            itemBuilder: (context, index) {
                              final item = _carrito[index];
                              return Card(
                                elevation: 0,
                                child: ListTile(
                                  dense: true,
                                  title: Text(item['nombre']),
                                  subtitle: Text(
                                      'Cant: ${item['cantidad']} x \$${item['precio_unitario']} = \$${item['subtotal'].toStringAsFixed(2)}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () =>
                                            _modificarCantidad(index, -1),
                                        style: ElevatedButton.styleFrom(
                                          minimumSize: const Size(24, 24),
                                          padding: const EdgeInsets.all(4),
                                        ),
                                        child: const Text('-',
                                            style: TextStyle(fontSize: 12)),
                                      ),
                                      const SizedBox(width: 4),
                                      ElevatedButton(
                                        onPressed: () =>
                                            _modificarCantidad(index, 1),
                                        style: ElevatedButton.styleFrom(
                                          minimumSize: const Size(24, 24),
                                          padding: const EdgeInsets.all(4),
                                        ),
                                        child: const Text('+',
                                            style: TextStyle(fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: TextFormField(
                      controller: _subtotalController,
                      decoration: const InputDecoration(
                          labelText: 'Subtotal', border: OutlineInputBorder()),
                      readOnly: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: TextFormField(
                      controller: _ivaController,
                      decoration: const InputDecoration(
                          labelText: 'IVA (13%)', border: OutlineInputBorder()),
                      readOnly: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: TextFormField(
                      controller: _totalController,
                      decoration: const InputDecoration(
                          labelText: 'Total', border: OutlineInputBorder()),
                      readOnly: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _procesarVenta,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                      child: const Text('Procesar Venta',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: TextField(
                      controller: _busquedaProductoController,
                      decoration: const InputDecoration(
                        labelText: 'Buscar Producto',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) async {
                        final productos =
                            await VentaApi().searchProductos(nombre: value);
                        setState(() => _productos = productos);
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8.0),
                    height: 300,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Productos',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Expanded(
                          child: _productos.isEmpty &&
                                  _busquedaProductoController.text.isEmpty
                              ? const Center(
                                  child: Text('Cargando productos...'))
                              : _productos.isEmpty
                                  ? const Center(
                                      child:
                                          Text('No hay productos disponibles'))
                                  : ListView.builder(
                                      itemCount: _productos.length,
                                      itemBuilder: (context, index) {
                                        final producto = _productos[index];
                                        return Card(
                                          elevation: 0,
                                          child: ListTile(
                                            dense: true,
                                            title: Text(producto['nombre']),
                                            subtitle: Text(
                                                'Precio: \$${producto['precio_venta']} | Stock: ${producto['stock_existencia']}'),
                                            onTap: () =>
                                                _agregarAlCarrito(producto),
                                          ),
                                        );
                                      },
                                    ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8.0),
                    height: 200,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Documentos Tributarios (Opcional)',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _facturaController,
                            decoration: const InputDecoration(
                                labelText: 'Factura',
                                border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: _comprobanteCreditoFiscalController,
                            decoration: const InputDecoration(
                                labelText: 'Crédito Fiscal',
                                border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: _facturaExportacionController,
                            decoration: const InputDecoration(
                                labelText: 'Factura Exportación',
                                border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: _notaCreditoController,
                            decoration: const InputDecoration(
                                labelText: 'Nota Crédito',
                                border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: _notaDebitoController,
                            decoration: const InputDecoration(
                                labelText: 'Nota Débito',
                                border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: _notaRemisionController,
                            decoration: const InputDecoration(
                                labelText: 'Nota Remisión',
                                border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: _comprobanteLiquidacionController,
                            decoration: const InputDecoration(
                                labelText: 'Comprobante Liquidación',
                                border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: _comprobanteRetencionController,
                            decoration: const InputDecoration(
                                labelText: 'Comprobante Retención',
                                border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: _documentoContableLiquidacionController,
                            decoration: const InputDecoration(
                                labelText: 'Doc. Contable Liquidación',
                                border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: _comprobanteDonacionController,
                            decoration: const InputDecoration(
                                labelText: 'Comprobante Donación',
                                border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: _facturaSujetoExcluidoController,
                            decoration: const InputDecoration(
                                labelText: 'Factura Sujeto Excluido',
                                border: OutlineInputBorder()),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _clienteFocusNode.dispose();
    _clienteController.dispose();
    _notasController.dispose();
    _descuentoController.dispose();
    _subtotalController.dispose();
    _ivaController.dispose();
    _totalController.dispose();
    _busquedaProductoController.dispose();
    _facturaController.dispose();
    _comprobanteCreditoFiscalController.dispose();
    _facturaExportacionController.dispose();
    _notaCreditoController.dispose();
    _notaDebitoController.dispose();
    _notaRemisionController.dispose();
    _comprobanteLiquidacionController.dispose();
    _comprobanteRetencionController.dispose();
    _documentoContableLiquidacionController.dispose();
    _comprobanteDonacionController.dispose();
    _facturaSujetoExcluidoController.dispose();
    super.dispose();
  }
}
