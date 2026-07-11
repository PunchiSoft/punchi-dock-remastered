# Fase 3: consolidación de skills

## Resultado

Se consolidaron los dominios solapados sin eliminar todavía carpetas. Los nombres genéricos permanecen como alias de compatibilidad y señalan de forma explícita la skill canónica.

| Alias conservado | Skill canónica |
|---|---|
| `qml` | `qml-ui-creation` |
| `javascript` | `js-plasma-backend` |
| `kde-plasma6` | `kde-plasma-6-dev` |
| `localization` | `ki18n-localization` |
| `packaging` | `plasmoid-packaging` |
| `sdk-reference` | `kde-sdk-reference` |

## Diseño de interfaces

Las cuatro skills visuales tienen responsabilidades distintas:

| Skill | Responsabilidad |
|---|---|
| `ui-design` | Definir jerarquía, estructura, estados y especificación antes de implementar. |
| `qml-ui-creation` | Convertir la especificación en componentes QML mantenibles. |
| `visual-review` | Auditar fidelidad visual, espaciado, escala, tema y estados. |
| `ux-review` | Auditar flujos, claridad, retroalimentación y recuperación de errores. |
| `accessibility` | Diseñar y auditar teclado, foco, semántica, percepción y movimiento. |

Flujo recomendado:

```text
ui-design → qml-ui-creation → visual-review
                              ↘ ux-review
                              ↘ accessibility
```

No es obligatorio activar toda la cadena. Se usa una skill principal y solo los complementos que requiera la tarea.

## Correcciones de contenido

- Se retiraron rutas inventadas como `Localization/` y `Packaging/`.
- Se eliminó la prescripción automática de DataEngines y de campos de metadata sin verificar.
- Se aclaró que `.pragma library` no debe emplearse automáticamente para compartir estado.
- Se incorporaron entradas, procedimientos, reglas, validación y criterios de aceptación específicos.
- Se reforzó la consulta dirigida del SDK local y la distinción entre inspección estática y prueba runtime.

## Decisión de transición

Los alias no deben activarse en tareas nuevas. Podrán retirarse en una fase posterior, después de buscar y actualizar todas las referencias y comprobar que el catálogo continúa cargando correctamente.
