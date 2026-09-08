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
| Autenticación (login) | Planificado |
| Persistencia de sesión (token) | Planificado |
| Validación de sesión con `GET /auth/me` | Planificado |
| Logout | Planificado |
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

| Componente | Tecnología |
|---|---|
| Framework | Flutter 3.x (stable) + Dart null-safety |
| State management | Riverpod |
| HTTP | Dio |
| Navegación | GoRouter |
| Token seguro | flutter_secure_storage |
| Favoritos locales | shared_preferences |

> Las versiones exactas de cada paquete se fijan en la FASE 1 según el SDK instalado (Flutter 3.47.0 / Dart 3.13.0).

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

## Estructura del proyecto prevista

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

> La creación física de esta estructura corresponde a la **FASE 1**. En la FASE 0 solo se documenta.

## Decisiones técnicas iniciales

- **Riverpod**: state management compile-safe y testable, sin dependencia de `BuildContext`,
  ideal para estados asíncronos.
- **Dio**: interceptors para el token y el manejo centralizado de errores, con timeouts configurables.
- **GoRouter**: navegación declarativa con redirección basada en autenticación.
- **flutter_secure_storage**: el token se guarda de forma segura (Keychain/Keystore).
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

**FASE 0 — Análisis, contexto y documentación inicial.** En curso.

- [x] Análisis de la prueba y la API
- [x] Contrato técnico interno (PROJECT_CONTEXT.md)
- [ ] Bootstrap y arquitectura base (FASE 1)
- [ ] Funcionalidades (FASES 2–8)
- [ ] Calidad y revisión (FASE 9)
- [ ] Tests (FASE 10)
- [ ] Documentación final (FASE 11)

> Todas las funcionalidades están marcadas como **Planificado**. Aún no se ha implementado código.
