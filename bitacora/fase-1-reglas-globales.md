# Bitácora: Fase 1 de reglas globales

Fecha: 10 de julio de 2026

## Trabajo realizado

- Se creó `AGENTS.md` en la raíz como fuente canónica.
- Se reemplazó la duplicación de `.agents/AGENTS.md` por instrucciones locales y un enlace al archivo raíz.
- Se definió una matriz de compatibilidad que distingue mínimo declarado, entorno objetivo y SDK upstream.
- Se precisaron arquitectura, modularidad, seguridad, empaquetado, bitácora y validación.
- Se incorporaron rutas prioritarias para consultas en `kde-sdk/`.

## Decisiones

- Plasma 6.0 permanece como mínimo declarado hasta que una prueba o necesidad concreta justifique cambiarlo.
- Fedora 44+ y Wayland son el entorno principal.
- Qt 6 y KF6 no tienen todavía una versión menor fijada.
- El SDK local es una referencia upstream y no define por sí solo la compatibilidad mínima.
- `.agents/skills/` es la fuente canónica; `.agents/skills 2/` no debe editarse.

## Evidencia

La explicación completa se encuentra en `docs/plandeaccion/fase-1-reglas-globales.md`.

## Siguiente fase

Fase 2: retirar la duplicación física después de comprobar referencias y exclusiones.

