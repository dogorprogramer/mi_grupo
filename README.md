# MiGrupo

MiGrupo es una app Flutter que simula el panel de un grupo/comunidad: login, catálogo de
productos, detalle, favoritos, roles simulados y perfil. Todo se consume desde la API pública de
prueba **DummyJSON** (`https://dummyjson.com`), sin backend propio.

La construí como **prueba técnica de Flutter Mobile Developer**. El objetivo no era inventar un
dominio de negocio, sino resolver los problemas típicos de una app móvil real: autenticación y
sesión, listas con paginación, búsqueda y filtros, detalle, persistencia local, manejo de errores y
UI condicional según el rol.

> DummyJSON es una API ficticia de ejemplo. La prueba no contiene endpoints ni lógica de ningún
> sistema real.

---

## Funcionalidades implementadas

| Área | Qué hace |
|---|---|
| Autenticación | Login con `POST /auth/login`, token persistente y logout |
| Sesión | Restauración al arrancar y validación con `GET /auth/me` (401 → login) |
| Listado | `GET /products` con scroll infinito (`limit`/`skip`) |
| Búsqueda | `GET /products/search?q=` con debounce |
| Categorías | `GET /products/categories` + filtro remoto por categoría |
| Refresh | Pull-to-refresh respetando el filtro activo |
| Estados | Carga, error con reintento, vacío y "no hay más" |
| Detalle | `GET /products/:id` con galería de imágenes |
| Favoritos | Toggle desde listado y detalle, pantalla propia y persistencia local |
| Offline (favoritos) | Los favoritos guardados se ven sin conexión |
| Roles | id par = admin, id impar = usuario estándar |
| Admin | Botón "Eliminar producto" (`DELETE /products/:id`, simulado por DummyJSON) |
| Perfil | Datos del usuario autenticado (`/auth/me`) |
| Tema | Claro / Oscuro / Sistema, persistente |
| UX | Skeletons, widgets reutilizables y animaciones sutiles |

---

## Stack

| Componente | Tecnología | Versión |
|---|---|---|
| Framework | Flutter (stable) + Dart null-safety | 3.47.0 / 3.13.0 |
| Estado | Riverpod | 3.4.3 |
| HTTP | Dio | 5.11.1 |
| Navegación | GoRouter | 18.0.1 |
| Token seguro | flutter_secure_storage | 10.3.1 |
| Favoritos locales | shared_preferences | 2.5.5 |

---

## Arquitectura

Uso **feature-first** con separación de capas dentro de cada feature:

```
presentation  →  domain  ←  data
```

- **domain**: modelos y contratos puros. No depende de Flutter ni de Dio.
- **data**: implementación de repositorios, acceso HTTP (Dio), DTOs y persistencia local.
- **presentation**: pantallas, widgets y estado con Riverpod. No hace HTTP ni parsea JSON.

Además:

- **core/**: infraestructura transversal (constantes, errores, red, storage, tema, widgets).
- **app/**: widget raíz, router y providers globales.

Aplico **Repository Pattern** de forma pragmática: el dominio define el contrato y la capa de datos
lo implementa. La UI nunca conoce Dio ni `shared_preferences`.

### Estructura de carpetas

```
lib/
├── app/
│   ├── app.dart                 # MaterialApp.router (tema + router)
│   ├── router/                  # GoRouter y redirects de sesión
│   └── providers/               # providers globales (router, dio, storage, tema)
├── core/
│   ├── constants/               # AppConstants (baseUrl, claves de storage)
│   ├── errors/                  # AppException / AppErrorType
│   ├── network/                 # DioClient, AuthInterceptor, error_mapper
│   ├── storage/                 # SecureStorageService, PreferencesService
│   ├── theme/                   # AppTheme, AppSpacing, AppRadius, AppColors
│   ├── widgets/                 # ShimmerBox, AppErrorView, AppEmptyView
│   └── utils/
└── features/
    ├── auth/        (data, domain, presentation)
    ├── products/    (data, domain, presentation)
    ├── favorites/   (data, domain, presentation)
    └── profile/     (presentation)
```

> `profile` solo tiene `presentation` porque reutiliza el `User` que ya carga `auth`; no dupliqué
> modelos ni repositorios.

### Cómo se conecta cada pieza

- **Riverpod** es el estado y también la inyección de dependencias: los providers arman el grafo
  (`dioProvider`, `authRepositoryProvider`, `productsStateProvider`, etc.). La UI lee estado con
  `ref.watch` y dispara acciones con `ref.read(...notifier)`.
- **Dio** centraliza las peticiones: `DioClient` define `baseUrl` y timeouts, y `AuthInterceptor`
  añade el header `Authorization: Bearer <token>` automáticamente. Ningún repositorio arma el token.
- **GoRouter** define rutas (`/splash`, `/login`, `/`, `/product/:id`, `/favorites`, `/profile`) y
  protege las privadas con un `redirect` que depende del estado de autenticación.
- **Persistencia**: el token va a `flutter_secure_storage` (Keychain/Keystore) y los favoritos a
  `shared_preferences` como JSON.

---

## Autenticación

1. El usuario entra usuario/contraseña en la pantalla de login (`POST /auth/login`).
2. Se guarda el `accessToken` en almacenamiento seguro.
3. El estado de auth pasa a `AuthAuthenticated` y GoRouter navega a la pantalla principal.

## Restauración de sesión

Al abrir la app:

1. Se lee el token guardado. Si no hay, el usuario es no autenticado.
2. Si hay token, se valida con `GET /auth/me`.
3. Si responde bien, se restaura el usuario (`AuthAuthenticated`).
4. Si responde **401**, se borra el token y se vuelve al login.

Mientras se resuelve la sesión se muestra el splash, y el router espera a conocer el estado antes de
redirigir (para no mandar al login por error). El **logout** borra el token y vuelve a
`AuthUnauthenticated`.

---

## Productos

- **Listado** (`GET /products`): grid de 2 columnas con imagen, título, precio y rating.
- **Paginación / scroll infinito**: `limit = 20` y `skip` incremental. `hasMore` se calcula con el
  `total` de la API. Se evitan solicitudes duplicadas (no se dispara `loadMore` si ya está cargando
  o si no hay más).
- **Búsqueda** (`GET /products/search?q=`): con **debounce de 400 ms** para no pedir en cada tecla.
- **Categorías** (`GET /products/categories`): chips horizontales; al elegir una se consulta
  `GET /products/category/{slug}` de forma remota (no filtro en local).
- **Búsqueda vs. categoría**: son mutuamente excluyentes; la última interacción prevalece. DummyJSON
  no ofrece un endpoint combinado, así que evité inventarlo.
- **Pull-to-refresh**: recarga desde `skip = 0` respetando el filtro activo y sin duplicar requests.
- **Estados**: carga inicial (skeletons), error inicial con reintento, vacío (con mensaje según el
  contexto) y error al cargar más con reintento.

Para evitar que una respuesta vieja pise una consulta nueva (por ejemplo escribir rápido
"phone" → "iphone"), cada recarga incrementa un contador de generación y descarta respuestas
obsoletas.

---

## Detalle de producto

- Se consulta `GET /products/:id` (no reutilizo el objeto de la lista como fuente definitiva).
- La ruta `/product/:id` solo recibe el `id`.
- Muestra imagen (con galería si hay varias), título, precio, rating, stock, categoría, marca y
  descripción.
- Maneja carga (skeleton), error con reintento y **404 → "Producto no encontrado."**.

---

## Favoritos

- **Una sola fuente de verdad**: `favoritesStateProvider`. Listado, detalle y pantalla de favoritos
  leen el mismo estado, así que siempre quedan sincronizados.
- Toggle con el corazón desde el listado y desde el detalle.
- Pantalla "Favoritos" (`/favorites`): lista los guardados, permite quitarlos y abrir el detalle.

## Persistencia y offline de favoritos

- Los favoritos se guardan en `shared_preferences` como JSON. Guardo **el producto completo**
  (título, precio, imagen, etc.), no solo el id, porque si no no podría mostrar la pantalla de
  favoritos sin conexión.
- Al arrancar, `FavoritesNotifier` hidrata desde el storage. El estado distingue `isHydrated` para
  no mostrar "No tienes favoritos" antes de terminar de leer.
- **Offline**: la lista de favoritos se lee del dispositivo, sin llamadas HTTP; se pueden ver y
  quitar sin conexión. El catálogo y la búsqueda sí requieren red (no implementé cache del catálogo).
- Si el JSON guardado está corrupto, se ignora de forma segura y se trata como lista vacía.

---

## Roles y eliminación

DummyJSON no tiene roles de negocio, así que la prueba los simula por el `id`:

- `id` **par** → **admin**.
- `id` **impar** → **usuario estándar**.

La regla vive en el dominio (`User.role`) y la UI consulta `user.role == UserRole.admin`; no hay
lógica de paridad repartida por los widgets.

- El **admin** ve el botón **"Eliminar producto"** en el detalle. Pide confirmación, muestra estado
  de carga (evita doble tap) y avisa con un mensaje al terminar.
- El **usuario estándar** no ve ese botón: no está oculto ni deshabilitado, simplemente **no se
  construye** en el árbol de widgets.

> **Importante**: `DELETE /products/:id` en DummyJSON responde con éxito pero **no persiste** la
> eliminación. El producto sigue existiendo al recargar. La app muestra la confirmación, pero no
> pretende que el backend haya cambiado.

Si el producto eliminado estaba en favoritos, se retira también de la lista local para no dejar
información inconsistente.

---

## Perfil

- Pantalla `/profile`, accesible desde el icono del AppBar principal.
- Muestra nombre, correo, usuario, rol y avatar (con fallback a iniciales si no hay imagen o falla).
- **No** hace una llamada extra a `/auth/me`: reutiliza el usuario que ya se cargó al restaurar la
  sesión (`currentUserProvider`).

---

## Tema: claro / oscuro / sistema

- Design system en `core/theme`: `AppTheme` (light/dark con `ColorScheme.fromSeed`), tokens de
  espaciado/radio (`AppSpacing`, `AppRadius`) y colores semánticos (`AppColors`).
- Modo **claro/oscuro/sistema** con `themeModeProvider`; la preferencia se guarda en
  `shared_preferences` y se lee al arrancar, así que no hay parpadeo de tema. El selector está en
  Perfil.

## Loading y animaciones

- **Skeletons** (`ShimmerBox`, hecho con Flutter nativo, sin paquetes) en el grid, las categorías,
  el detalle y los favoritos. El `CircularProgressIndicator` se reserva para acciones puntuales
  (login, "cargar más", eliminar).
- Animaciones sutiles: `Hero` en la imagen al pasar de la lista al detalle, transición de página
  (fade + slide, ~250 ms), corazón de favorito con `AnimatedSwitcher`, galería con
  `AnimatedSwitcher` y fade-in en los estados vacío/error. Todas con APIs nativas y duraciones
  cortas.

---

## Manejo de errores

Los errores de red se mapean de forma centralizada (`DioException` → `AppException`) con mensajes
para el usuario:

- **timeout** / **sin conexión** → mensajes de conexión.
- **400** en login → "Usuario o contraseña incorrectos."
- **401** → no autorizado (y en la restauración, vuelve al login).
- **404** en detalle → "Producto no encontrado."
- **500** → error del servidor.
- Otros → mensaje genérico.

La UI nunca muestra códigos HTTP, stack traces ni detalles internos.

---

## Cómo ejecutar

Requisitos: Flutter 3.47+ y Android SDK (target principal).

```bash
flutter pub get
flutter run
```

APK de debug:

```bash
flutter build apk --debug
# build/app/outputs/flutter-apk/app-debug.apk
```

### Tests

```bash
flutter test
```

Hay **79 tests** (unitarios y de widget) que cubren autenticación y restauración, listado y
paginación, concurrencia (evitar duplicados), búsqueda/categorías/refresh, detalle y 404, favoritos
(persistencia, hidratación, remove), roles (admin ve el botón / estándar no), perfil, tema y
mapeo de errores.

---

## Decisiones técnicas

- **Riverpod** en lugar de Bloc/Provider: es compile-safe, testeable, no depende de `BuildContext` y
  maneja bien los estados asíncronos (`AsyncValue`). También funciona como inyección de dependencias.
- **Dio**: sus interceptors permiten añadir el token en un solo lugar y centralizar timeouts/errores.
- **GoRouter**: navegación declarativa con `redirect` por sesión, que es justo lo que pide el flujo
  de auth.
- **flutter_secure_storage para el token** y **shared_preferences para los favoritos**: cada uno en
  el almacenamiento que le corresponde (seguro vs. clave-valor simple).
- **Repository Pattern** con el contrato en `domain` y la implementación en `data`, para que la UI no
  se acople a Dio ni al storage.
- **Rol derivado del `id`** en el dominio, para no repetir la regla par/impar en la UI.
- **flutter_secure_storage 10.3.1** (no 11.x): la 11.0.0 exige `compileSdk = 37`, incompatible con el
  AGP 9.1.0 / `compileSdk 36` del entorno. La 10.3.1 compila contra SDK 36 sin tocar la configuración
  nativa. Se puede subir cuando el entorno soporte SDK 37.

---

## Supuestos y ambigüedades

- La credencial que da la prueba, **`emilys` / `emilyspass`**, tiene `id = 1` (impar), así que es
  **usuario estándar** y no permite ver el botón de admin. Para demostrar el rol admin uso un
  usuario de DummyJSON con `id` par (ver credenciales).
- El PDF decía "scroll infinito o paginación"; implementé scroll infinito.
- No especificaba cómo persistir favoritos para offline; guardo el producto completo en JSON.
- La regla par/impar y el `DELETE` simulado son limitaciones de DummyJSON, no del dominio real.

## Limitaciones reales

- `DELETE /products/:id` no borra de verdad (simulación de DummyJSON).
- El **offline cubre solo favoritos**; el catálogo y la búsqueda necesitan conexión.
- `flutter_secure_storage` tiene soporte limitado en escritorio/web; la app apunta a Android/iOS.
- No pude probar en un dispositivo/emulador físico durante el desarrollo: la validación fue con
  `flutter analyze`, la suite de tests y `flutter build apk --debug`.

## Qué haría diferente con más tiempo

- Pruebas de integración end-to-end (login → listado → detalle → favorito → eliminar).
- Cache del catálogo para un modo offline más completo.
- Internacionalización (es/en) y más pulido visual.
- Manejo global de expiración de token (hoy el 401 se resuelve en la restauración de sesión).
- APK de release firmado o un video corto de demo.

## Bonus del PDF

| Bonus | Estado |
|---|---|
| Tests unitarios/widgets | **Implementado** (79 tests) |
| Inyección de dependencias | **Implementado** (Riverpod) |
| Modo claro/oscuro | **Implementado** (claro/oscuro/sistema, persistente) |
| Animaciones/skeleton | **Implementado** (skeletons nativos + animaciones sutiles) |
| Soporte offline del catálogo | **No implementado** (solo favoritos) |
| Internacionalización (es/en) | **No implementado** |

---

## Credenciales de prueba

**Indicada por la prueba**

| Usuario | Contraseña | Rol |
|---|---|---|
| `emilys` | `emilyspass` | Usuario estándar (id=1, impar) |

**Adicionales para probar el rol admin**

| Usuario | Contraseña | Rol |
|---|---|---|
| `michaelw` | `michaelwpass` | Admin (id=2, par) |
| `jamesd` | `jamesdpass` | Admin (id=4, par) |

---

## Estado final

Proyecto terminado y validado: `flutter analyze` sin issues, **79 tests** en verde y APK de debug
compilando. Todos los requisitos **obligatorios** del PDF están implementados; los bonus que no
entraron (i18n y cache del catálogo) quedan documentados arriba.
