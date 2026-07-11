---
name: kde-sdk-reference
description: Investigar APIs, tipos, ejemplos, pruebas y patrones oficiales en la copia local `kde-sdk/` para fundamentar decisiones sobre Plasma 6, KDE Frameworks y Kirigami. Usar cuando una tarea dependa de una API KDE, su disponibilidad o comportamiento; no usar para búsquedas genéricas sin relación con KDE.
---

# Consulta del SDK local de KDE

## Procedimiento

1. Delimitar el símbolo, componente o comportamiento que se necesita confirmar.
2. Elegir la ruta prioritaria indicada en `AGENTS.md` y buscar con `rg` por símbolo, import, propiedad, señal y ejemplo.
3. Revisar primero API pública, documentación y pruebas; usar implementaciones internas solo como evidencia secundaria.
4. Contrastar ejemplos con la versión mínima declarada. No convertir automáticamente el snapshot local reciente en requisito mínimo.
5. Registrar la ruta y el elemento que respaldan una decisión relevante.

## Reglas

- Distinguir API pública, privada, experimental y detalle de implementación.
- No copiar código upstream extenso ni modificar `kde-sdk/` salvo petición explícita.
- Si el SDK local no prueba disponibilidad histórica, declarar la incertidumbre o verificarla por una fuente oficial apropiada.
- Preferir el patrón oficial más pequeño compatible con la arquitectura del proyecto.

## Criterios de aceptación

- La conclusión cita una ruta o símbolo pertinente y explica qué demuestra.
- Las inferencias están separadas de hechos observados.
- No se eleva implícitamente la compatibilidad mínima del plasmoide.
