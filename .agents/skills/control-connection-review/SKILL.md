---
name: control-connection-review
description: Rastrear controles de Punchi Dock desde la interacción hasta su efecto observable para detectar controles desconectados, valores guardados sin efecto, consumidores inactivos y pérdida de reactividad. Usar al revisar estos fallos o modificar controles, señales, propiedades puente, configuración o componentes compartidos de su recorrido; acotar la revisión a las cadenas afectadas.
---

# Trazabilidad funcional de controles

## Contrato y alcance

Un control está conectado cuando su entrada alcanza el consumidor activo y produce el efecto esperado en las condiciones declaradas. Existir, guardar un valor o tener referencias textuales no demuestra ese contrato.

Complementar con `plasma-config-review` para KConfig/KCM y `testing` para evidencia de ejecución. Esta skill no autoriza correcciones, retiros, instalaciones ni pruebas que el usuario haya excluido. En modo solo lectura, entregar el registro en la respuesta sin escribir documentos ni ejecutar pruebas.

## Clasificar antes de intervenir

- **Control desconectado:** la entrada no alcanza el efecto por una ruptura comprobada; precisar el eslabón y las condiciones afectadas.
- **Conexión parcial:** funciona solo en algunas instancias, modos o momentos; por ejemplo al recrear el popup pero no al aplicar cambios con él abierto.
- **Valor calculado sin consumidor efectivo:** se calcula o propaga pero no llega al objeto que realiza la acción o dibuja la superficie activa.
- **Pérdida de reactividad:** la inicialización funciona, pero una copia, asignación imperativa, caché o dependencia omitida impide actualizaciones.
- **Excepción intencional:** almacenamiento interno, migración legacy, preferencia exclusiva del KCM o efecto condicionado explícitamente.
- **Función de utilidad discutible:** sí produce el efecto previsto; evaluar su conveniencia separadamente, sin llamarla código huérfano ni retirarla por una supuesta desconexión.
- **Sin evidencia suficiente:** búsqueda incompleta o ruta dinámica sin resolver. Ausencia de coincidencias no equivale a defecto confirmado.

## Rastrear la cadena completa

1. Definir entrada, resultado esperado, momento de aplicación, superficie o servicio afectado, modos habilitados y unidades. Ejemplo: aplicar una distancia mayor debe separar el popup de carpeta existente de su ancla, dentro de los límites de pantalla.
2. Inspeccionar el diff y el historial de revisión relacionado. Enumerar los controles afectados y los demás consumidores de cualquier helper compartido cambiado. No ampliar una revisión puntual a todo el proyecto sin necesidad.
3. Seguir hacia delante con `rg` y lecturas de contexto:

   `control → evento/alias → estado editable → persistencia (si aplica) → estado runtime → transformación/controlador → instancia activa → efecto`

   Registrar para cada flecha el binding, señal, llamada o escritura real y su archivo/símbolo. Continuar aunque la propiedad cambie de nombre. Para acciones transitorias, omitir persistencia y comprobar también el retorno de éxito/error cuando corresponda.
4. Seguir hacia atrás desde la propiedad visual o acción final. Confirmar que lee la misma cadena y no una constante, otra clave, un default o una copia antigua. Buscar todas las instancias y la ruta que las activa: Loader, factory, coordinador, delegado, reutilización y recreación.
5. Revisar los puntos donde puede perderse la conexión:
   - aliases `cfg_*` hasta la página superior registrada en `config.qml`;
   - claves, tipos, grupos, límites y defaults de `main.xml`;
   - preferencias por elemento dentro de JSON, que no son claves KConfig;
   - propiedades puente, señales sin receptor y parámetros ignorados o sobrescritos;
   - `Component.onCompleted`, `createObject`, asignaciones que sustituyen bindings, cachés sin invalidación y `Connections.target` incorrecto;
   - cambio de instancia, pérdida/restauración del ancla y modos alternativos;
   - conversiones de unidades y clamping que ocultan cambios legítimos;
   - operaciones como `mapToItem` que no declaran por sí solas todas las dependencias necesarias del binding.
6. Consultar el SDK local si la conclusión depende de una API KDE; distinguir contrato público de implementación del snapshot. No sustituir conexiones nativas sin una causa comprobada.

Las búsquedas y conteos generan candidatos. Excluir comentarios, documentación y pruebas del conteo de consumidores runtime. Un objeto `Connections` puede funcionar sin referencias a su nombre; una función puede acceder dinámicamente a una propiedad. Resolver esos casos antes de concluir.

## Evidencia proporcional al riesgo

Separar explícitamente:

1. **Cadena estática trazada:** cada flecha tiene evidencia en fuente.
2. **Comportamiento ejecutado:** una prueba cambia la entrada pública y observa el resultado, sin escribir directamente la propiedad final.
3. **Integración verificada:** control/KCM, applet y Plasma completan el flujo en el entorno declarado. Aplicar, Cancelar y persistencia no quedan demostrados por una prueba aislada del helper.

Elegir pruebas existentes o nuevas según la causa y el alcance autorizado. Para sliders, usar valores distintos que no queden saturados por límites; observar el popup activo y, cuando sea relevante, reabrirlo y cambiar de modo. Comprobar que un control vecino con una preferencia independiente no cambie. Para KCM, cubrir Aplicar/Cancelar/defaults/reapertura según la modificación. En helpers compartidos, seleccionar consumidores de cada ruta de comportamiento distinta.

Una prueba de la fórmula de distancia no demuestra que el popup la consuma. Una prueba que cambia directamente `gap` protege el helper, pero no la ruta slider → KConfig → popup. Los contratos textuales protegen enlaces concretos; no prueban posición, foco, renderizado ni actualización en caliente.

Al implementar una regresión, comprobar que la prueba distinguiría la ruptura original de la corrección. Si conviene desconectar un enlace deliberadamente, hacerlo en una copia aislada, nunca sobre cambios del usuario ni en Plasma personal. No crear pruebas redundantes para satisfacer un conteo ni afirmar que un lint limpio garantiza conexiones funcionales.

## Registro y prevención entre sesiones

Registrar las cadenas revisadas en el documento activo de `docs/revisiones/` o `docs/nuevas-modificaciones/`, respetando plantillas, respaldos y permisos. Usar un ID estable por control basado en su clave o acción; una línea es un localizador auxiliar, no su identidad. No reescribir documentos históricos.

| ID / control | Entrada y aplicación | Cadena: archivo/símbolo por enlace | Consumidor activo y efecto | Modos/unidades/límites | Evidencia y prueba | Estado / pendiente |
|---|---|---|---|---|---|---|
| clave o acción | evento, Aplicar o inmediato | secuencia completa | instancia y resultado esperado | condiciones | estática/runtime/Plasma, fecha | conectado estáticamente, verificado, parcial, desconectado, excepción o pendiente |

Para cada excepción, registrar motivo, alcance y cuándo reconsiderarla. No usar exclusiones globales para ocultar candidatos nuevos.

Antes de modificar una cadena, capturar su estado y consumidores compartidos. Después, comparar enlaces y comportamiento: una conexión nueva no compensa la pérdida de otra. Revisar las entradas cuyos símbolos o consumidores cambiaron; marcar la evidencia anterior como pendiente de revalidación cuando el contrato haya cambiado.

Al retirar un control, usar `safe-removal-review` para clave, UI, puentes, consumidores exclusivos, traducciones y pruebas. Conservar consumidores compartidos y resolver explícitamente la configuración antigua. No dejar componentes inertes como sustituto de una retirada completa.

## Casos de referencia del proyecto

- **Distancias de carpetas y menús:** se guardaban y calculaban pero el popup activo no consumía la distancia. Rastrear ConfigFolderPopups/ConfigMenus, ConfigAspect, DockConfigurationState, DockGeometryState, main.qml y el coordinador/ancla efectivos. Consultar el estado actual; estos nombres orientan la búsqueda, no fijan la arquitectura futura.
- **Cursores de Preferencias:** globalMouseCursor sí activaba cambios de cursor en el KCM. Su retiro fue una simplificación autorizada, no prueba de desconexión. Revisar los registros del 2026-09-09 antes de interpretar referencias históricas como estado vigente.
- **Cobertura por capas:** popup_spacing_metrics_test.qml comprueba métricas; native_popup_spacing_test.qml comprueba el helper y la posición del diálogo; popup_menu_surface_contract_test.py protege enlaces de fuente. Ninguna capa aislada acredita todo el ciclo del control en el KCM.

## Entrega y límites

Indicar alcance realmente revisado, rupturas confirmadas con enlace exacto, excepciones justificadas, pruebas ejecutadas y pendientes. No afirmar «todos los controles funcionan» a partir de un inventario de claves o de una suite verde.

Esta skill guía una revisión cuando se invoca o selecciona; no es un monitor permanente ni un gate automático de CI. Si se solicita automatización adicional, definirla como tarea concreta con sus límites.
