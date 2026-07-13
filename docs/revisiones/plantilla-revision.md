# Plantilla de revision del plasmoide

Fecha: YYYY-MM-DD o YYYY-MM-DD-2

Estado: abierta.

## Contexto

Describir aqui el origen de la revision y su relacion con sesiones previas.

Incluir, cuando corresponda:

- si la revision inicia un ciclo nuevo o continua uno anterior;
- el entorno de prueba real utilizado;
- la distribucion, version de Plasma y modo de uso relevante;
- cualquier restriccion conocida de la sesion.

Ejemplo:

Esta revision continua el seguimiento funcional del plasmoide despues del cierre de la sesion anterior. Los hallazgos se incorporaran a medida que se confirmen en Plasma local.

## Observaciones

Registrar aqui el marco general de la prueba antes de enumerar revisiones puntuales.

Esta seccion solo prepara el contexto general. Los reportes concretos del usuario deben vivir en las revisiones numeradas.

Ejemplo:

Las pruebas se realizaran en Fedora 44 actualizado, con KDE Plasma 6, priorizando validacion en runtime real. Si se usa `plasmoidviewer`, sus resultados deben distinguirse de los obtenidos dentro de Plasma.

## Primera revision

Anotar aqui las observaciones textuales del usuario para la primera pasada de pruebas.

Esta seccion, y las revisiones numeradas equivalentes, son la fuente principal del reporte del usuario. El agente debe tomar su contenido como base para construir o actualizar el resto del documento.

- observacion 1;
- observacion 2;
- observacion 3.

## Segunda revision

Usar esta seccion solo si existen nuevas observaciones dentro de la misma jornada o sesion.

- observacion 1;
- observacion 2.

Agregar `## Tercera revision`, `## Cuarta revision` y siguientes cuando el usuario incorpore nuevos reportes en la misma revision.

## Hallazgos confirmados

Registrar solamente problemas o comportamientos con evidencia suficiente derivados de las revisiones numeradas vigentes.

Cada hallazgo debe dejar claro:

- que sucede;
- en que condicion ocurre;
- que evidencia lo confirma;
- que capa o modulo parece involucrado.

Ejemplo:

- el popup de confirmacion de papelera se cierra de inmediato cuando el menu padre pierde foco durante la transicion;
- el indicador visual de tarea activa se dibuja en mas de un item cuando su visibilidad depende de ventanas abiertas y no del estado activo real.

## Plan de accion

Definir aqui el plan de trabajo en un orden pequeno, secuencial y verificable.

Si el usuario modifica una revision numerada, este plan debe actualizarse para responder al reporte nuevo y no al anterior.

Reglas:

1. confirmar o acotar la causa primero;
2. aplicar despues el cambio minimo necesario;
3. validar flujo normal, casos borde y regresiones previsibles;
4. dividir por fases o sesiones si el alcance lo requiere.

Ejemplo:

1. confirmar si el fallo ocurre en Plasma real, en `plasmoidviewer` o en ambos;
2. aislar la capa responsable del comportamiento;
3. implementar la correccion;
4. validar el resultado en el entorno pertinente;
5. mantener la revision abierta o cerrarla segun la evidencia.

## Validacion

Documentar con honestidad que se verifico realmente y que continua pendiente.

Esta seccion tambien debe alinearse siempre con el contenido vigente de `Primera revision`, `Segunda revision`, `Tercera revision` y siguientes.

Separar siempre:

- validacion manual del usuario;
- validacion local en Plasma real;
- revision estatica o sintactica;
- pendientes no verificados todavia.

Ejemplo:

- validacion manual: el usuario confirma que el popup ya respeta el borde del panel;
- validacion local: el comportamiento se reproduce correctamente en panel inferior;
- revision estatica: `qmllint` no reporta errores en los archivos modificados;
- pendiente: falta comprobar panel superior y modo flotante.

## Implementacion revision N° X - YYYY-MM-DD - Sesion N

Describir aqui los cambios realmente aplicados durante la revision correspondiente.

Incluir:

- componentes o archivos afectados;
- criterio tecnico seguido;
- correcciones de diagnostico si una hipotesis previa resulto incorrecta;
- decisiones relevantes para no repetir trabajo.

Ejemplo:

- `TaskIndicator.qml` pasa a separar la deteccion de ventanas abiertas del estado activo;
- `TaskModelController.qml` reduce la resolucion de actividad al rol oficial correspondiente;
- el popup de confirmacion de papelera se difiere un ciclo para evitar su cierre inmediato al perder foco.

### Soluciones ya intentadas para no repetir

Registrar aqui intentos previos que no resolvieron el problema o que no deben reintroducirse sin evidencia nueva.

El objetivo de esta seccion es evitar bucles de parches y conservar memoria tecnica entre sesiones.

Ejemplo:

- se intento resolver la app activa comparando indices de filas directamente; no debe repetirse sin validacion runtime adicional;
- se probo una correccion visual que solo mitigaba el sintoma, pero no la causa funcional;
- se descarta tratar como bug real un comportamiento que solo aparece en `plasmoidviewer` y no en Plasma local.

## Cierre de la revision

Cerrar una revision solo cuando exista evidencia suficiente de que el problema principal fue resuelto en el entorno correcto.

Si la verificacion es parcial o quedan dudas materiales, mantener:

`Estado: abierta.`

Cuando la revision quede finalizada, actualizar:

`Estado: cerrada.`

y dejar constancia breve del criterio de cierre.
