import 'package:flutter/material.dart';

import '../views/inventario/add_product_screen.dart';
import '../views/inventario/inventory_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => const InventoryScreen(),
  '/add_product': (context) => const ProductFormApp(),
};
