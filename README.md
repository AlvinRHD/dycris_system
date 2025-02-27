# dycris_system

# Sistema de Inventario - Flutter con Node.js y MySQL, Express

Este proyecto es un **Sistema de Inventario** desarrollado en **Flutter** para el frontend y **Node.js con MySQL, Express** para el backend. El sistema permite la gestión de categorías, productos, ventas, compras, traslados, salidas y ofertas. Incluye funcionalidades completas de **CRUD** (Crear, Leer, Actualizar y Eliminar).

## 📁 Estructura del Proyecto

```
└── 📁lib
    └── 📁views
        └── 📁categoria
            └── lista_categoria.dart
            └── registrar_categoria.dart
        └── home_screen.dart
        └── 📁inventario
            └── historial_ajustes_screen.dart
            └── inventario_completo.dart
            └── inventario_screen.dart
            └── product_model.dart
            └── registrar_productos.dart
        └── 📁modulo_empleados
            └── editar_empleado_modal.dart
            └── empleados_screen.dart
            └── nuevo_empleado_modal.dart
        └── 📁modulo_usuarios
            └── agregar_usuario_modal.dart
            └── login_screen.dart
            └── user_screen.dart
        └── 📁movimientos
            └── compras_screen.dart
            └── movimientos_screen.dart
            └── 📁ofertas
                └── agregar_oferta_screen.dart
                └── editar_oferta_screen.dart
                └── ofertas_api.dart
                └── ofertas_screen.dart
                └── ofertas_widgets.dart
            └── salidas_screen.dart
            └── 📁traslados
                └── agregar_traslado_screen.dart
                └── editar_traslado_screen.dart
                └── traslados_api.dart
                └── traslados_screen.dart
                └── traslados_widgets.dart
            └── 📁ventas
                └── agregar_venta_screen.dart
                └── auth_helper.dart
                └── 📁clientes
                    └── agregar_cliente_screen.dart
                    └── cliente_widgets.dart
                    └── clientes_api.dart
                    └── clientes_screen.dart
                    └── editar_cliente_screen.dart
                └── editar_venta_screen.dart
                └── venta_api.dart
                └── venta_widgets.dart
                └── ventas_screen.dart
        └── 📁proveedores
            └── proveedores_screen.dart
            └── registrar_proveedores_screen.dart
        └── splash_screen.dart
        └── 📁sucursal
            └── mostrar_sucursales.dart
            └── registrar_sucursal.dart
    └── main.dart
```

## 🚀 Funcionalidades

### 1️⃣ **Módulo de Categorías** (`views/categoria`)

### 2️⃣ **Módulo de Inventario** (`views/inventario`)

### 3️⃣ **Módulo de Movimientos** (`views/movimientos`)

### 4️⃣ **Módulo de Proveedores** (`views/proveedores`)

### 5️⃣ **Módulo de Sucursales** (`views/sucursal`)

## 📌 Características Principales del CRUD

Cada módulo tiene la misma estructura para operaciones **CRUD**:

1. **Listar elementos** en una tabla usando `FutureBuilder`.
2. **Crear nuevos elementos** con un formulario y `TextField`.
3. **Actualizar elementos** con un `AlertDialog` de edición.
4. **Eliminar elementos** con confirmación antes de proceder.
5. **Manejo de estados** con `setState` para actualizar la UI en tiempo real.
6. **Conexión con la API** usando `http` para enviar solicitudes al backend.

## 🛠 Instalación y Configuración

### **Backend (Node.js con MySQL)**

1. Instalar dependencias:
   ```sh
   npm install
   ```
2. Configurar la base de datos en `.env`.
3. Iniciar el servidor:
   ```sh
   npm start
   ```

### **Frontend (Flutter)**

1. Instalar dependencias:
   ```sh
   flutter pub get
   ```
2. Correr la aplicación en un emulador o dispositivo físico:
   ```sh
   flutter run
   ```

## 🔗 Conexión con la API

Las solicitudes HTTP se realizan a `http://localhost:3000/api/`.
Ejemplo de solicitud GET en `lista_categoria.dart`:

```dart
Future<List<dynamic>> fetchCategorias() async {
  final url = Uri.parse("http://localhost:3000/api/categoria");
  final response = await http.get(url);

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception("Error al cargar las categorías");
  }
}
```

## 📌 Mejoras Futuras

✅ Mejor manejo de errores y validaciones.  
✅ Implementación de autenticación y roles de usuario.  
✅ Uso de variables de entorno en Flutter para la API.

---

📌 **Autor**: [Programadores de DYCRIS]

📅 **Última actualización**: 18/02/2025
