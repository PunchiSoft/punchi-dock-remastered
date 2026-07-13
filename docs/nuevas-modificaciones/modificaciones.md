# Modificaciones del plasmoide

Fecha: 2026-07-12

Estado: abierta.

## Contexto

Este documento abre un flujo paralelo al de revisiones para registrar solicitudes de nuevas capacidades o mejoras del dock sin mezclarlas con bugs o validaciones correctivas.

La primera modificacion de esta sesion nace despues de confirmar funcional el menu contextual por clic derecho para apps con acciones configuradas.

## Objetivo de la modificacion

Introducir una forma segura de sugerir acciones contextuales por defecto para apps conocidas sin sobrescribir configuraciones existentes del usuario.

## Observaciones

La propuesta busca extender una capacidad ya existente del dock. No parte desde un fallo, sino desde una mejora funcional del flujo de configuracion.

## Primera modificacion

- añadir autocompletado inicial no destructivo de acciones contextuales al crear o detectar una app conocida;
- ejemplo esperado: una app como Firefox puede sugerir acciones como `firefox --new-window` sin obligar al usuario a escribirlas desde cero;
- la sugerencia debe respetar menus ya configurados y no debe reactivar menus deshabilitados manualmente.

## Alcance confirmado

- la modificacion se limita a la capa de configuracion del dock y al modelo de datos de acciones sugeridas;
- la primera fase cubre solo apps conocidas con presets seguros y faciles de mantener;
- la funcionalidad debe actuar como sugerencia inicial, no como reemplazo de menus existentes;
- esta fase no ampliara aun un editor avanzado de presets ni una base dinamica de comandos externos.

## Riesgos y dependencias

- una misma app puede llegar por ejecutable nativo, `gtk-launch`, Flatpak u otras variantes, por lo que conviene resolver la identidad por `appId`, `storageId` o comando inferido;
- algunas aplicaciones admiten flags estables y otras no, asi que los presets iniciales deben mantenerse acotados y conservadores;
- la sugerencia no debe destruir el trabajo manual del usuario ni reactivar menus deshabilitados expresamente.

## Plan de implementacion

1. identificar donde se crean y sincronizan los items de tipo `app` dentro del KCM;
2. introducir un catalogo pequeno de acciones sugeridas para apps conocidas;
3. aplicar la precarga solo cuando el item aun no tenga acciones y no exista una desactivacion manual;
4. validar que la configuracion siga siendo editable y que el runtime use esas acciones como cualquier menu contextual normal;
5. mantener la modificacion abierta hasta comprobar el flujo completo en Plasma real.

## Validacion

- validacion manual del usuario: pendiente para esta modificacion al momento de abrir el documento;
- validacion local del agente: la logica de configuracion se integra sin sobrescribir menus existentes;
- revision estatica del agente: la precarga nace en la capa de configuracion y reutiliza la estructura `actions` ya existente en el proyecto;
- validacion sintactica: `qmllint` superado para `contents/ui/config/ConfigItems.qml`, `contents/ui/config/components/ActionDialog.qml` y `contents/ui/config/ItemActionEditor.qml`;
- cierre de la modificacion: no procede todavia, porque falta validacion manual completa en Plasma real.

## validacion del usuario en entorno local
- funcionan sus comandos quedando bastante bien tambien para este ejepmplo se tomo firefox y parecieron 2 menus nueva ventana y mdodo incognito


## Implementacion modificacion N° 1 - 2026-07-12 - Sesion 1

- `contents/ui/config/code/configItems.js` incorpora resolucion de presets y acciones sugeridas por identidad de aplicacion;
- la primera version incluye presets base para Firefox, Konsole y Dolphin;
- `contents/ui/config/code/configItemsFormHelper.js` aplica una precarga no destructiva cuando el item aun no tiene acciones y tampoco conserva una desactivacion manual previa;
- el runtime no requiere una ruta especial nueva, porque las acciones sugeridas se guardan en la misma estructura `actions` que ya consume el menu contextual implementado hoy.

### Decisiones tomadas para futuras fases

- la sugerencia inicial debe vivir cerca del modelo de datos y no dispersarse por la UI;
- los presets deben mantenerse pequenos, explicitos y auditables;
- la identidad de app debe resolverse primero por `storageId`, `appId` o comando inferido antes de caer en heuristicas mas fragiles.

### Soluciones descartadas para no mezclar alcance

- no se implementa una descarga dinamica de presets externos;
- no se añade aun una interfaz separada para administrar bibliotecas de acciones por app;
- no se intentan cubrir todas las aplicaciones del sistema en esta primera fase.
