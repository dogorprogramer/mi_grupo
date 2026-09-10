# MiGrupo

## Descripción

**MiGrupo** es una aplicación Flutter que simula el panel de un grupo/comunidad. Consume la API
pública de prueba **DummyJSON** y demuestra un flujo completo de app móvil: autenticación con
token, listado paginado de productos, búsqueda y filtro por categoría, detalle, favoritos
persistentes, roles simulados con UI condicional y perfil de usuario.

## Objetivo de la prueba

Esta aplicación responde a una **prueba técnica de Flutter Mobile Developer**. Evalúa la capacidad
de estructurar un proyecto Flutter de tamaño mediano, manejar autenticación, estado, persistencia
local y errores, y tomar decisiones de arquitectura ante información no explícita.

> Nota: se usa una API pública ficticia (DummyJSON) y un dominio de ejemplo. No contiene endpoints
> ni lógica de negocio de ningún sistema real.

## Funcionalidades previstas

| Funcionalidad | Estado |
|---|---|
| Autenticación (login) | Completado |
| Persistencia de sesión (token) | Completado |
| Validación de sesión con `GET /auth/me` | Completado |
| Logout | Completado |
| Protección de rutas según sesión | Completado |
| Listado de productos (pagínado / scroll infinito) | Completado |
| Búsqueda de productos | Completado |
| Filtro por categoría | Completado |
| Pull-to-refresh | Completado |
| Estados de carga / error / vacío | Completado |
| Detalle de producto | Completado |
| Favoritos (toggle) | Completado |
| Favoritos offline/persistentes | Completado |
| Eliminación de favoritos | Completado |
| Rol simulado (admin / estándar) con UI condicional | Completado |
| Eliminación de producto (admin, simulada) | Completado |
| Perfil de usuario | Completado |

## Stack tecnológico

| Componente | Tecnología | Versión |
|---|---|---|
| Framework | Flutter (stable) + Dart null-safety | 3.47.0 / 3.13.0 |
| State management | Riverpod | 3.4.3 |
| HTTP | Dio | 5.11.1 |
| Navegación | GoRouter | 18.0.1 |
| Token seguro | flutter_secure_storage | 10.3.1 |
| Favoritos locales | shared_preferences | 2.5.5 |

## Arquitectura

Arquitectura **feature-first** con separación de capas por feature:

```
data → domain → presentation
```

- **Domain**: lógica pura y modelos, sin dependencia de Flutter ni de Dio.
- **Data**: servicios HTTP, repositorios, modelos de red, persistencia local.
- **Presentation**: widgets, pantallas y estado (Riverpod). No hace HTTP directo ni parsea JSON crudo.
- **core/**: constantes, errores, network, storage y utilidades transversales.
- **app/**: widget raíz, router y providers globales.

Se aplica **Repository Pattern** y **SOLID** de forma pragmática, sin sobrearquitectura.

## Estructura del proyecto

```
lib/
├── app/
│   ├── app.dart
│   ├── router/
│   └── providers/
├── core/
│   ├── constants/
│   ├── errors/
│   ├── network/
│   ├── storage/
│   └── utils/
└── features/
    ├── auth/      (data, domain, presentation)
    ├── products/  (data, domain, presentation)
    ├── favorites/ (data, domain, presentation)
    └── profile/   (data, domain, presentation)
```

> Todas las features están implementadas: `auth`, `products`, `favorites` y `profile`.
> `profile` reutiliza el usuario de `auth` (no necesita data/domain propios).

## Autenticación

- **Login** (`POST /auth/login`): la pantalla de login envía usuario y contraseña, guarda el token
  de forma segura y restaura el usuario autenticado.
- **Sesión persistente**: el token se almacena en `flutter_secure_storage`. Al abrir la app se
  valida contra `GET /auth/me`; si es inválido (401) el token se elimina y se vuelve al login.
- **Logout**: elimina el token y devuelve al login.
- **Rutas protegidas**: con GoRouter, un usuario no autenticado no puede acceder a la pantalla
  principal; el router redirige según el estado de autenticación.

## Productos

- **Listado** (`GET /products`): la pantalla principal (tras autenticarse) muestra los productos
  en una cuadrícula de 2 columnas (imagen, título, precio, rating).
- **Paginación / infinite scroll**: se usa `limit` y `skip`. Al acercarse al final de la lista se
  carga la página siguiente de forma incremental.
- **Estados de UI**: carga inicial, error inicial (con reintentar), lista vacía, carga de página
  adicional, error al cargar más (con reintentar) y "no hay más productos".
- **Modelos tipados**: `Product`, `ProductsPage`, `Category` y `ProductQuery` (dominio) con DTOs
  en la capa de datos.

### Búsqueda, categorías y refresh

- **Búsqueda** (`GET /products/search?q=`): campo de búsqueda en la parte superior. Usa **debounce
  de 400 ms** para no disparar una request por cada tecla y para evitar condiciones de carrera
  (se descartan respuestas obsoletas con un contador de generación).
- **Categorías** (`GET /products/categories`): se consumen de la API (objetos `{slug, name, url}`)
  y se muestran como chips horizontales. Al seleccionar una, se consulta
  `GET /products/category/{slug}` de forma remota (paginaça).
- **Regla búsqueda/categoría**: son mutuamente excluyentes — la última interacción prevalece.
  Iniciar una búsqueda deselecciona la categoría; elegir una categoría limpia la búsqueda.
- **Pull-to-refresh**: recarga desde `skip = 0` respetando la búsqueda/categoría activa.
  Si la primera página ya está cargando, el refresh se ignora (evita duplicados).
- Cada cambio de contexto (búsqueda/categoría/refresh) reinicia la paginación desde `skip = 0`
  y recalcula `hasMore`.

## Detalle de producto

- **Endpoint** `GET /products/:id`: al tocar un producto en el listado se navega a
  `/product/:id`, que consulta el detalle por su identificador (no reutiliza el objeto de la lista).
- **Ruta** `/product/:id` en GoRouter; se pasa únicamente el `id`.
- **Estados**: carga, cargado, error (con reintentar) y producto no encontrado (404 →
  "Producto no encontrado.").
- **Contenido**: imagen principal, título, precio, rating, stock, categoría, marca, descripción
  e imágenes adicionales.

## Favoritos

- **Fuente de verdad única**: `favoritesStateProvider` (`Notifier<FavoritesState>`); el estado
  (productos + `isHydrated`) se comparte entre listado, detalle y pantalla de favoritos, por lo que
  siempre quedan sincronizados.
- **Toggle** desde el listado (icono de corazón sobre cada tarjeta) y desde el detalle.
- **Pantalla “Favoritos”** (`/favorites`): lista los productos favoritos, permite quitarlos y
  navegar a su detalle; estado vacío cuando no hay favoritos.
- Abstracción de dominio (`FavoritesRepository`) con implementación persistente
  (`SharedPreferencesFavoritesRepository`); `InMemoryFavoritesRepository` se mantiene como test double.

### Persistencia y offline de favoritos (FASE 6)

- **Persistencia local**: los favoritos se guardan en `shared_preferences` bajo la clave
  `AppConstants.favoritesKey`. Se persiste una representación JSON del producto favorito, no solo
  su id, para poder **mostrarlos sin conexión**.
- **Representación almacenada**: cada favorito se serializa con `ProductDto.toJson()`
  (id, título, descripción, categoría, precio, rating, stock, marca, thumbnail, imágenes).
- **Hidratación inicial**: al arrancar, `FavoritesNotifier` carga los favoritos persistidos.
  El estado distingue `isHydrated` para que la pantalla de favoritos no muestre falsamente
  "No tienes favoritos" antes de terminar de cargar (muestra un spinner mientras hidrata).
- **Offline**: la lista de favoritos se lee de `shared_preferences` (sin llamadas HTTP); se pueden
  ver, quitar y (si la info local está disponible) marcar/desmarcar sin conexión.
- **UI desacoplada**: la UI y `FavoritesNotifier` no conocen `shared_preferences`; solo usan la
  abstracción `FavoritesRepository` (la implementación vive en `data`).
- **Errores**: si la persistencia falla o el dato guardado está corrupto, se tratan de forma
  segura (se ignoran y se muestran estados comprensibles; no se propaga el stack trace).

## Roles simulados y eliminación (FASE 7)

- **Regla de rol**: si el `id` del usuario autenticado (de `GET /auth/me`) es **par** → rol
  `admin`; si es **impar** → rol `usuario estándar`. La regla está centralizada en el dominio
  (`User.role`) y la UI consulta `user.role == UserRole.admin` (no hay lógica `id % 2` dispersa).
- **UI condicional**: en el detalle, el botón **"Eliminar producto"** solo se construye si el
  usuario es `admin`. Para el usuario estándar el widget **no existe** en el árbol (ni oculto ni
  deshabilitado).
- **Eliminación**: `DELETE /products/:id` a través de `ProductsRepository.deleteProduct` →
  `ProductsApi.deleteProduct`. Con confirmación previa ("¿Eliminar este producto?"), estado de
  carga (evita doble tap), y mensaje de éxito.
- **DummyJSON simula**: la API responde éxito en el DELETE pero **no persiste** el cambio; el
  producto sigue existiendo al recargar. Documentado como limitación de DummyJSON.
- **Favoritos coherentes**: si el producto eliminado estaba en favoritos, se retira localmente.
- **Supuesto de la prueba**: la regla par/impar es una simulación (el backend no tiene roles de
  negocio); se implementa el manejo de UI condicional que evalúa el PDF.

## Perfil (FASE 8)

- **Pantalla** `/profile` (accesible desde el icono de perfil del AppBar principal).
- **Fuente de datos**: reutiliza el usuario autenticado que ya se obtiene de `GET /auth/me` durante
  la restauración de sesión (`AuthAuthenticated.user` → `currentUserProvider`). **No** se hace una
  llamada adicional a `/auth/me` al abrir el perfil (se evitan requests duplicados).
- **Muestra**: nombre (`firstName + lastName`), correo, avatar (si existe), usuario y rol.
- **Avatar**: si `User.image` existe se usa como imagen; si falla o no existe, hay fallback a las
  iniciales (no rompe la pantalla).
- **Sesión**: si no hay usuario autenticado, muestra un estado seguro ("No hay sesión activa.") y
  las rutas protegidas siguen redirigiendo al login.
- **Sin capa data/domain propia**: al reutilizar `User`/Auth, no se duplican modelos ni repositorios.

## Diseño y tema

- **Design system** en `core/theme/`: `AppTheme` (light/dark), `AppSpacing`/`AppRadius` (tokens) y
  `AppColors` (colores semánticos: rating y favorito).
- **Modo claro/oscuro/sistema** con `themeModeProvider`; la preferencia se persiste en
  `shared_preferences` (clave `AppConstants.themeModeKey`) y se lee al arrancar, por lo que no hay
  parpadeo de tema. El selector está en la pantalla de **Perfil**.
- **Widgets reutilizables** en `core/widgets/`: `ShimmerBox` (skeleton nativo, sin dependencias),
  `AppErrorView` y `AppEmptyView`.
- **Loading con skeletons** en el grid de productos, categorías, detalle y favoritos. Se mantiene
  `CircularProgressIndicator` solo para acciones puntuales (login, cargar más, eliminar).
- **Transición lista → detalle** con `Hero` sobre la imagen del producto.

## Ejecución

Requisitos: Flutter 3.47+ y Android SDK (para el target principal).

```bash
flutter pub get
flutter run
```

Para generar un APK de debug:

```bash
flutter build apk --debug
```

El APK se genera en `build/app/outputs/flutter-apk/app-debug.apk`.

## Decisiones técnicas iniciales

- **Riverpod**: state management compile-safe y testable, sin dependencia de `BuildContext`,
  ideal para estados asíncronos.
- **Dio**: interceptors para el token y el manejo centralizado de errores, con timeouts configurables.
- **GoRouter**: navegación declarativa con redirección basada en autenticación.
- **flutter_secure_storage (10.3.1)**: el token se guarda de forma segura (Keychain/Keystore).
  Se usa la versión 10.x (en lugar de la 11.x) porque la 11.0.0 exige `compileSdk = 37`,
  incompatible con el AGP 9.1.0 / compileSdk 36 actuales. La 10.3.1 compila contra SDK 36 sin
  modificar la configuración nativa de Android. Se puede actualizar a 11.x cuando el entorno
  soporte SDK 37.
- **shared_preferences**: los favoritos se guardan como JSON de clave-valor.
- **Rol simulado**: se deriva del `id` del usuario (`GET /auth/me`); id par = admin, id impar = estándar.
- **Favoritos offline**: se guarda un snapshot completo del producto, no solo el id, para poder
  mostrarlos sin conexión.

## Supuestos

- **emilys / emilyspass** (credencial indicada por la prueba) tiene `id=1` (impar) → rol **estándar**.
- Para demostrar el rol **admin** se usa un usuario de DummyJSON con `id` par (ver credenciales).
- **DELETE /products/:id** es simulado: DummyJSON responde éxito pero no persiste la eliminación.
  La app muestra confirmación sin reflejar el cambio en el backend.
- Los favoritos se persisten localmente con la información suficiente del producto para verse offline.
- La app está orientada principalmente a **Android/iOS** (prueba de Mobile Developer).

## Limitaciones conocidas

- `DELETE /products/:id` no elimina realmente el producto (limitación de DummyJSON).
- La API no maneja roles de negocio reales; el rol se simula por paridad de `id`.
- `flutter_secure_storage` tiene soporte limitado en plataformas de escritorio/web.
- La búsqueda y el filtro por categoría pueden comportarse distinto al listado general; se valida en cada fase.
- El offline cubre **solo favoritos**; el catálogo/búsqueda siguen requiriendo conexión.

## Qué haría distinto con más tiempo

- **Testing**: pruebas de integración end-to-end (login → listado → detalle → favorito → eliminar) y
  pruebas de golden/widget más completas.
- **Offline del catálogo**: cachear el último listado/búsqueda consultado (la prueba solo exige
  offline de favoritos).
- **Internacionalización (es/en)**.
- **Animaciones más elaboradas** y transiciones personalizadas adicionales.
- **Refrescar el perfil** explícitamente desde `/auth/me` bajo demanda y manejo de expiración de
  token de forma global (hoy el 401 se maneja en la restauración de sesión).
- **APK de release firmado / video demo** como entregables opcionales.

## Credenciales de prueba

### Indicadas por la prueba
| Usuario | Contraseña | Rol |
|---|---|---|
| `emilys` | `emilyspass` | Estándar (id=1, impar) |

### Adicionales (para demostrar el rol ADMIN)
| Usuario | Contraseña | Rol |
|---|---|---|
| `michaelw` | `michaelwpass` | Admin (id=2, par) |
| `jamesd` | `jamesdpass` | Admin (id=4, par) |

## Estado del proyecto

**FASE 10 — Revisión final y preparación de entrega.** Completada.

- [x] FASE 0 — Análisis y documentación inicial
- [x] FASE 1 — Bootstrap y arquitectura base
- [x] FASE 2 — Autenticación y sesión (login, token seguro, `/auth/me`, logout, rutas protegidas)
- [x] FASE 3 — Listado de productos y paginación (infinite scroll, estados de UI)
- [x] FASE 4 — Búsqueda, categorías y refresh (debounce, filtro por categoría, pull-to-refresh)
- [x] FASE 5 — Detalle de producto y favoritos
- [x] FASE 6 — Persistencia/offline de favoritos (shared_preferences)
- [x] FASE 7 — Roles, admin y eliminación de productos (simulada)
- [x] FASE 8 — Perfil del usuario (reutiliza `/auth/me`)
- [x] FASE 9 — Errores, lifecycle, calidad y revisión
- [x] FASE 10 — Revisión final y preparación de entrega

> Todos los requisitos **obligatorios** del PDF están implementados. `flutter analyze` limpio,
> **77 tests** pasando y APK de debug compilando.

## Bonus del PDF

El PDF marca estos puntos como **opcionales**. Estado real:

| Bonus del PDF | Estado |
|---|---|
| Pruebas unitarias/widgets de al menos un flujo | **Implementado** (77 tests: auth, products, favorites, roles, profile, tema) |
| Inyección de dependencias (Riverpod) | **Implementado** (Riverpod como DI/estado) |
| Modo claro/oscuro | **Implementado** (light/dark/system, persistente) |
| Animaciones sutiles (shimmer/skeleton) | **Implementado** (skeletons con shimmer nativo) |
| Soporte offline básico (cache del listado) | No implementado (offline solo de favoritos) |
| Internacionalización básica (es/en) | No implementado |
