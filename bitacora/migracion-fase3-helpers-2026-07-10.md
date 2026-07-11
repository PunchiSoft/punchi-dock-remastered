## 2026-07-10: Fase 3 Completada - Extracción de Helpers de ConfigItems.qml
- Se extrajeron funciones puras y lógica de estado derivado a `configItemsStateHelper.js`.
- Se movió la lógica repetitiva de carga y aplicación de formularios (poblar controles y reconstruir ítems) y la de normalización de modelos a `configItemsFormHelper.js`.
- Se añadió `configItemsWorkflowHelper.js` para absorber la coordinación restante de modos, diálogos, acciones, carga inicial y operaciones sobre ítems.
- `ConfigItems.qml` se redujo aún más y queda centrado en composición visual, aliases y delegación a helpers.
- La extracción de diálogos quedó unificada en nombres consistentes con el plan, incluyendo `TimedDialog.qml`.
- Validación con qmllint y ctest completada.
