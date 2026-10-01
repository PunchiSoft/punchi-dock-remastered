# Norma de layout para el KCM

Usar `contents/ui/config/components/ConfigLayoutMetrics.qml` como fuente unica para las metricas compartidas de las paginas de configuracion.

## Pagina

- Instanciar `ConfigLayoutMetrics` con `availableWidth: page.width`.
- Enlazar `implicitWidth` con `pageImplicitWidth`; no repetir multiplicadores de `gridUnit` por pagina.
- Dejar que `Kirigami.FormLayout.wideMode` se adapte automaticamente. No fijarlo en `true`.

## Controles

- Limitar filas, mensajes y textos descriptivos con `contentWidth`.
- Limitar `ComboBox`, `SpinBox` y selectores equivalentes con `selectorWidth`.
- Si un control usa `Layout.fillWidth`, debe tener tambien un maximo derivado de las metricas o vivir dentro de una fila ya limitada.
- Reservar anchos pequenos locales solo para etiquetas de valor como `px`, porcentaje o escala.

## Ayudas

- Usar `Text.WordWrap`, `Layout.fillWidth`, `Layout.maximumWidth: metrics.contentWidth`, `leftPadding: metrics.helperIndent` y `Kirigami.Theme.disabledTextColor`.
- No usar espacios o margenes en pixeles para alinear ayudas.

## Estado contextual

- Mostrar advertencias sobre el estado actual del dock al principio de la pagina que gobierna ese comportamiento.
- Consolidar modo, limitacion y consecuencia en un solo `Kirigami.InlineMessage`; evitar repartir el mismo estado entre etiquetas o categorias distintas.
- Declarar explicitamente `visible: true` en mensajes permanentes; `Kirigami.InlineMessage` puede iniciar oculto.
- Ubicar el control relacionado inmediatamente despues del aviso cuando este disponible.
- No colocar estados generales del dock al final de paginas de dominio como ventanas, apariencia o mouse.

## Validacion

- Revisar la pagina con su ancho inicial y despues ampliada manualmente.
- Confirmar que no haya texto cortado, controles estirados sin necesidad ni diferencias de margen entre paginas.
- Verificar el modo apilado de `FormLayout` y cadenas traducidas mas largas.
- Ejecutar `qmllint` sobre cada pagina modificada.
