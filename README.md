# dycris_system

# Sistema de Inventario - Flutter con Node.js y MySQL, Express

Este proyecto es un **Sistema de Inventario** desarrollado en **Flutter** para el frontend y **Node.js con MySQL, Express** para el backend. El sistema permite la gestión de categorías, productos, ventas, compras, traslados, salidas y ofertas. Incluye funcionalidades completas de **CRUD** (Crear, Leer, Actualizar y Eliminar).

## 📁 Estructura del Proyecto

```
📁lib
├── 📁routes
│   ├── app_routes.dart
├── 📁views
│   ├── 📁categoria
│   │   ├── lista_categoria.dart
│   │   ├── registrar_categoria.dart
│   ├── 📁inventario
│   │   ├── historial_ajustes_screen.dart
│   │   ├── inventario_completo.dart
│   │   ├── inventario_screen.dart
│   │   ├── registrar_productos.dart
│   ├── 📁movimientos
│   │   ├── compras_screen.dart
│   │   ├── 📁ofertas
│   │   ├── 📁traslados
│   │   ├── 📁ventas
│   │   ├── ventas_screen.dart
│   ├── 📁proveedores
│   │   ├── proveedores_screen.dart
│   │   ├── registrar_proveedores_screen.dart
│   ├── 📁sucursal
│   │   ├── mostrar_sucursales.dart
│   │   ├── registrar_sucursal.dart
│   ├── home_screen.dart
│   ├── login_screen.dart
│   ├── registro_screen.dart
└── main.dart
```

## 🚀 Funcionalidades

### 1️⃣ **Módulo de Categorías** (`views/categoria`)

- `lista_categoria.dart`: Muestra la lista de categorías en una tabla con opciones para editar y eliminar.
- `registrar_categoria.dart`: Formulario para agregar nuevas categorías.

### 2️⃣ **Módulo de Inventario** (`views/inventario`)

- `inventario_screen.dart`: Pantalla principal del inventario con listado de productos.
- `registrar_productos.dart`: Formulario para agregar productos nuevos.
- `historial_ajustes_screen.dart`: Historial de modificaciones en productos.

### 3️⃣ **Módulo de Movimientos** (`views/movimientos`)

- `compras_screen.dart`: Manejo de compras de productos.
- `ventas_screen.dart`: Gestión de ventas con búsqueda de clientes y descuentos automáticos.
- `salidas_screen.dart`: Registro de salidas de productos.
- `ofertas_screen.dart`: Administración de descuentos en productos.
- `traslados_screen.dart`: Gestión de traslados entre sucursales.

### 4️⃣ **Módulo de Proveedores** (`views/proveedores`)

- `proveedores_screen.dart`: Lista de proveedores registrados.
- `registrar_proveedores_screen.dart`: Formulario para añadir proveedores.

### 5️⃣ **Módulo de Sucursales** (`views/sucursal`)

- `mostrar_sucursales.dart`: Lista de sucursales registradas.
- `registrar_sucursal.dart`: Formulario para agregar nuevas sucursales.

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
✅ Optimización en la carga de datos con `Provider` o `Riverpod`.  
✅ Implementación de autenticación y roles de usuario.  
✅ Uso de variables de entorno en Flutter para la API.

---

📌 **Autor**: [Programadores de DYCRIS]

📅 **Última actualización**: 18/02/2025
