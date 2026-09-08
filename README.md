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
| Listado de productos (pagínado / scroll infinito) | Planificado |
| Búsqueda de productos | Planificado |
| Filtro por categoría | Planificado |
| Pull-to-refresh | Planificado |
| Estados de carga / error / vacío | Planificado |
| Detalle de producto | Planificado |
| Favoritos (toggle) | Planificado |
| Favoritos offline | Planificado |
| Eliminación de favoritos | Planificado |
| Rol simulado (admin / estándar) con UI condicional | Planificado |
| Eliminación de producto (admin, simulada) | Planificado |
| Perfil de usuario | Planificado |

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

> La estructura física se creó en la **FASE 1**. La carpeta `features/auth` se implementó en la
> **FASE 2** (autenticación y sesión). Las carpetas `products`, `favorites` y `profile` están
> preparadas (vacías) para las siguientes fases.

## Autenticación

- **Login** (`POST /auth/login`): la pantalla de login envía usuario y contraseña, guarda el token
  de forma segura y restaura el usuario autenticado.
- **Sesión persistente**: el token se almacena en `flutter_secure_storage`. Al abrir la app se
  valida contra `GET /auth/me`; si es inválido (401) el token se elimina y se vuelve al login.
- **Logout**: elimina el token y devuelve al login.
- **Rutas protegidas**: con GoRouter, un usuario no autenticado no puede acceder a la pantalla
  principal; el router redirige según el estado de autenticación.

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

**FASE 2 — Autenticación y sesión.** Completada.

- [x] FASE 0 — Análisis y documentación inicial
- [x] FASE 1 — Bootstrap y arquitectura base
- [x] FASE 2 — Autenticación y sesión (login, token seguro, `/auth/me`, logout, rutas protegidas)
- [ ] FASE 3 — Listado de productos y paginación
- [ ] FASE 4 — Búsqueda, categorías, refresh y estados de UI
- [ ] FASE 5 — Detalle de producto y favoritos
- [ ] FASE 6 — Persistencia/offline de favoritos
- [ ] FASE 7 — Roles y eliminación de productos
- [ ] FASE 8 — Perfil e integración completa
- [ ] FASE 9 — Errores, lifecycle, calidad y revisión
- [ ] FASE 10 — Tests
- [ ] FASE 11 — Documentación final

> Funcionalidades de productos, favoritos, perfil y roles siguen marcadas como **Planificado**.
