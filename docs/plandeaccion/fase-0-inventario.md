# Fase 0: inventario y línea base

## Estado

Fase completada el 10 de julio de 2026.

Esta fase fue documental y de solo lectura sobre las instrucciones y skills. No se movió, fusionó ni eliminó ninguna skill.

## Objetivos comprobados

- [x] Inventariar `.agents/skills/`.
- [x] Inventariar `.agents/skills 2/`.
- [x] Comparar ambos árboles archivo por archivo.
- [x] Registrar nombres, descripciones, tamaños y nivel de contenido.
- [x] Proponer una clasificación inicial: conservar, mejorar, fusionar o retirar.
- [x] Identificar las versiones declaradas por el repositorio y las versiones presentes en el SDK local.

## Resumen cuantitativo

| Concepto | Resultado |
|---|---:|
| Skills en `.agents/skills/` | 38 |
| Skills en `.agents/skills 2/` | 37 |
| Skills compartidas | 37 |
| Skills compartidas con diferencias | 0 |
| Skills exclusivas del árbol canónico | 1 |
| Skills genéricas | 17 |
| Skills semigenéricas | 14 |
| Skills especializadas | 7 |

La única skill presente exclusivamente en `.agents/skills/` es `kde-plasma-6-dev`.

## Comparación de los dos árboles

La comparación recursiva produjo un único resultado:

```text
Only in .agents/skills: kde-plasma-6-dev
```

Esto significa que los 37 archivos `SKILL.md` compartidos son idénticos byte por byte. No existe contenido exclusivo dentro de `.agents/skills 2/` que deba rescatarse.

Conclusión para la Fase 2: `.agents/skills/` es el árbol completo y debe considerarse la fuente canónica. La retirada de `.agents/skills 2/` es técnicamente segura respecto del contenido actual, pero no se ejecuta en esta fase.

## Criterio usado para evaluar contenido

La clasificación de madurez no evalúa si el tema de una skill es importante. Evalúa cuánto conocimiento operativo contiene actualmente.

- **Genérica:** utiliza la plantilla de 21 líneas con alcance sin definir y reglas comunes de Plasma 6.
- **Semigenérica:** tiene una descripción temática, pero su procedimiento, checklist y criterios siguen siendo intercambiables con otras skills.
- **Especializada:** contiene reglas, comprobaciones o procedimientos propios de su dominio.

La clasificación de acción propuesta significa:

- **Conservar:** mantener como base y mejorar de forma incremental.
- **Mejorar:** el dominio es útil, pero el contenido debe reescribirse.
- **Fusionar:** integrar el conocimiento en otra skill principal.
- **Retirar:** eliminar el nombre una vez migradas las referencias necesarias.

## Inventario completo y propuesta inicial

| Skill | Bytes | Líneas | Madurez | Acción propuesta | Destino o motivo |
|---|---:|---:|---|---|---|
| `accessibility` | 625 | 21 | Genérica | Mejorar | Dominio transversal con comprobaciones propias de teclado, foco, contraste y lectores de pantalla. |
| `animations` | 1472 | 30 | Semigenérica | Mejorar | Debe definir rendimiento, duraciones, reducción de movimiento y patrones QML. |
| `architecture` | 622 | 21 | Genérica | Mejorar | Debe convertir la arquitectura global en criterios verificables. |
| `code-review` | 619 | 21 | Genérica | Mejorar | Debe establecer severidades, formato de hallazgos y evidencia. |
| `controllers` | 1525 | 30 | Semigenérica | Mejorar | Dominio coherente con la arquitectura del proyecto. |
| `debugging` | 613 | 21 | Genérica | Mejorar | Debe definir logs, reproducción, aislamiento y verificación. |
| `documentation` | 625 | 21 | Genérica | Mejorar | Debe definir tipos de documentos, ubicación y mantenimiento. |
| `fedora` | 1472 | 30 | Semigenérica | Mejorar | Debe cubrir paquetes, versiones, Wayland y comandos verificables. |
| `git` | 1439 | 30 | Semigenérica | Conservar | Flujo general de ramas y commits; necesita reglas concretas del repositorio. |
| `git-maintenance` | 631 | 21 | Genérica | Fusionar | Integrar en `git`, salvo que se defina un procedimiento exclusivo de mantenimiento. |
| `icons` | 1447 | 30 | Semigenérica | Mejorar | Debe incluir especificaciones Breeze y validación SVG. |
| `javascript` | 616 | 21 | Genérica | Fusionar | Integrar en `js-plasma-backend`. |
| `js-plasma-backend` | 2358 | 33 | Especializada | Conservar | Base operativa para lógica JavaScript y APIs de Plasma. |
| `kde-plasma-6-dev` | 4698 | 282 | Especializada | Conservar | Guía principal del dominio; requiere revisar longitud y afirmaciones. |
| `kde-plasma6` | 619 | 21 | Genérica | Fusionar | Integrar en `kde-plasma-6-dev`. |
| `kde-sdk-reference` | 637 | 21 | Genérica | Mejorar | Debe convertirse en el enrutador del SDK local. |
| `kde-upstream-sync` | 637 | 21 | Genérica | Mejorar | Mantener solo si se documenta actualización segura de los repositorios SDK. |
| `ki18n-localization` | 2100 | 30 | Especializada | Conservar | Contiene reglas concretas de `i18n`, contexto, pluralización y extracción. |
| `kirigami` | 610 | 21 | Genérica | Mejorar | Debe aportar APIs, patrones y rutas de referencia propias. |
| `localization` | 1518 | 30 | Semigenérica | Fusionar | Integrar en `ki18n-localization`. |
| `logging` | 1473 | 30 | Semigenérica | Mejorar | Debe definir fuentes de logs, niveles y protección de datos. |
| `models` | 1472 | 30 | Semigenérica | Mejorar | Debe precisar modelos QML, roles y relación con proxies/estado. |
| `packaging` | 613 | 21 | Genérica | Fusionar | Integrar en `plasmoid-packaging`. |
| `performance` | 619 | 21 | Genérica | Mejorar | Debe definir métricas y diagnóstico de bindings, delegates y animaciones. |
| `plasmoid-packaging` | 2311 | 31 | Especializada | Conservar | Base concreta para metadata y empaquetado. |
| `python-tooling` | 2243 | 33 | Especializada | Conservar | Tiene alcance, ubicación, CLI y criterios verificables. |
| `qml` | 595 | 21 | Genérica | Fusionar | Integrar en `qml-ui-creation`; conservar lógica no visual en skills de backend/modelos. |
| `qml-ui-creation` | 2590 | 34 | Especializada | Conservar | Base concreta para UI QML de Plasma 6. |
| `refactoring` | 1511 | 30 | Semigenérica | Mejorar | Debe exigir caracterización previa y ausencia de cambios funcionales. |
| `release` | 1463 | 30 | Semigenérica | Mejorar | Debe definir versión, changelog, paquete y tags. |
| `sdk-reference` | 1491 | 30 | Semigenérica | Fusionar | Integrar en `kde-sdk-reference`. |
| `security` | 1486 | 30 | Semigenérica | Mejorar | Debe cubrir procesos, rutas, datos no confiables y fronteras Wayland. |
| `services` | 1454 | 30 | Semigenérica | Mejorar | Debe precisar asincronía, errores y prohibición de estado visual. |
| `taskmanager-api` | 631 | 21 | Genérica | Mejorar | Skill nuclear que necesita referencias concretas a `libtaskmanager`. |
| `testing` | 607 | 21 | Genérica | Mejorar | Debe definir matriz de pruebas y evidencia antes de finalizar. |
| `ui-design` | 613 | 21 | Genérica | Fusionar | Integrar reglas de creación en `qml-ui-creation`; las auditorías quedan en review skills. |
| `ux-review` | 1475 | 30 | Semigenérica | Mejorar | Conservar como revisión de flujos e interacción. |
| `visual-review` | 1493 | 30 | Semigenérica | Mejorar | Conservar como revisión de geometría, tema y consistencia visual. |

## Resumen de acciones propuestas

| Acción | Cantidad | Skills |
|---|---:|---|
| Conservar | 7 | `git`, `js-plasma-backend`, `kde-plasma-6-dev`, `ki18n-localization`, `plasmoid-packaging`, `python-tooling`, `qml-ui-creation` |
| Mejorar | 23 | `accessibility`, `animations`, `architecture`, `code-review`, `controllers`, `debugging`, `documentation`, `fedora`, `icons`, `kde-sdk-reference`, `kde-upstream-sync`, `kirigami`, `logging`, `models`, `performance`, `refactoring`, `release`, `security`, `services`, `taskmanager-api`, `testing`, `ux-review`, `visual-review` |
| Fusionar | 8 | `git-maintenance`, `javascript`, `kde-plasma6`, `localization`, `packaging`, `qml`, `sdk-reference`, `ui-design` |
| Retirar directamente | 0 | Ninguna antes de migrar contenido y referencias. |

Esta clasificación es una propuesta de trabajo, no una autorización para eliminar archivos.

## Solapamientos confirmados

| Skill secundaria | Skill principal propuesta | Razón |
|---|---|---|
| `git-maintenance` | `git` | La secundaria no contiene actualmente un flujo propio. |
| `javascript` | `js-plasma-backend` | La primera es genérica; la segunda contiene reglas reales para Plasma. |
| `kde-plasma6` | `kde-plasma-6-dev` | Mismo dominio y la segunda es sustancialmente más completa. |
| `localization` | `ki18n-localization` | Mismo dominio; la segunda cubre APIs y pluralización. |
| `packaging` | `plasmoid-packaging` | La segunda cubre manifiesto y formato de paquete. |
| `qml` | `qml-ui-creation` | La primera no añade reglas; la segunda define el trabajo visual. |
| `sdk-reference` | `kde-sdk-reference` | El proyecto prioriza el SDK local; debe existir un solo enrutador. |
| `ui-design` | `qml-ui-creation` | La skill actual es genérica y no justifica un procedimiento separado de creación. |

`accessibility`, `ux-review` y `visual-review` no se fusionan en esta propuesta. Representan dimensiones distintas, aunque sus contenidos actuales todavía no expresen esa diferencia.

## Versiones declaradas por el proyecto

| Componente | Declaración encontrada | Fuente | Estado |
|---|---|---|---|
| Versión del plasmoide | `0.1.0` | `metadata.json` | Explícita |
| API mínima de Plasma | `6.0` | `X-Plasma-API-Minimum-Version` en `metadata.json` | Explícita |
| Familia de Plasma | Plasma 6 | README, metadata e instrucciones | Explícita |
| Fedora | 44 o posterior | README y `.agents/AGENTS.md` | Explícita |
| Qt | Qt 6 | `.agents/AGENTS.md` y dependencias del README | Solo versión mayor |
| KDE Frameworks | KF6 | skills y nombres de paquetes del README | Solo versión mayor |

No se encontró una versión menor mínima o máxima para Qt 6 ni KDE Frameworks 6.

## Estado del SDK local

El SDK local no es una sola versión empaquetada: contiene nueve repositorios Git independientes y snapshots de desarrollo distintos.

| Repositorio | Revisión descriptiva | Commit |
|---|---|---|
| `frameworks/kconfig` | `v6.28.0-rc1-6-g38a3453f` | `38a3453f` |
| `frameworks/kcoreaddons` | `v6.28.0-rc1-3-g5520f285` | `5520f285` |
| `frameworks/ki18n` | `v6.28.0-rc1-1-g3a8584b` | `3a8584bc` |
| `frameworks/kiconthemes` | `v6.28.0-rc1-1-g2f4fd35` | `2f4fd355` |
| `frameworks/kirigami` | `v6.28.0-rc1-6-g5b1ec5e8` | `5b1ec5e8` |
| `frameworks/kpackage` | `v6.28.0-rc1-1-ga0a5d22` | `a0a5d224` |
| `frameworks/kservice` | `v6.28.0-rc1-1-g434dfc1e` | `434dfc1e` |
| `frameworks/plasma-framework` | `v6.6.90-96-gbb8325ae3` | `bb8325ae` |
| `plasma-workspace` | `v6.6.90-277-g001f2376b6` | `001f2376` |

Consecuencia: el SDK local sirve como referencia upstream reciente, pero sus revisiones no deben interpretarse automáticamente como la versión mínima soportada por el plasmoide.

## Inconsistencias y riesgos detectados

1. `metadata.json` permite Plasma 6.0, mientras que el SDK local representa ramas de desarrollo considerablemente posteriores.
2. Fedora 44+ está declarado, pero no se fija la versión de Plasma/Qt/KF proporcionada por ese entorno.
3. La bitácora menciona `Plasma5Support.DataSource`; esta dependencia de compatibilidad también aparece en el código actual y debe considerarse al definir soporte futuro.
4. Las skills especializadas pueden contener afirmaciones que corresponden a una versión reciente, no necesariamente a Plasma 6.0.
5. No hay una matriz formal que distinga versión mínima, versión objetivo y versión de referencia upstream.

## Decisiones que quedan pendientes

La Fase 0 proporciona evidencia, pero no decide unilateralmente:

1. Si Plasma 6.0 continuará siendo el mínimo real.
2. Qué versiones menores de Qt y KF6 se soportarán.
3. Si Fedora 44+ es requisito exclusivo o entorno principal de pruebas.
4. Si el SDK local debe fijarse a tags estables o continuar siguiendo snapshots upstream.
5. Si se aprueba el mapa de ocho fusiones propuesto.

Estas decisiones deben resolverse al redactar el `AGENTS.md` canónico durante la Fase 1.

## Criterio de cierre

La Fase 0 se considera completa porque:

- existe un inventario de las 38 skills;
- los dos árboles fueron comparados completamente;
- se demostró que `skills 2` no contiene contenido exclusivo;
- cada skill tiene una clasificación inicial;
- las declaraciones de versión fueron separadas del estado del SDK local;
- las decisiones no respaldadas por el repositorio quedaron marcadas como pendientes.

