---
name: review-cycle
description: Conducir una revision del usuario de Punchi Dock siempre en el mismo orden, usando `docs/revisiones/` como fuente de verdad para registrar contexto, hallazgos confirmados, plan, implementacion, validacion y soluciones ya intentadas. Usar cuando el usuario reporte pruebas locales, abra una nueva sesion de revision o pida convertir observaciones en una rutina repetible.
---

# Ciclo de revision del usuario

## Objetivo

Evitar que cada sesion de revision cambie de metodo. Esta skill fija un orden unico para:

- leer evidencia del usuario;
- separar hechos, hipotesis y pendientes;
- planificar implementaciones sin mezclar diagnosticos viejos;
- dejar memoria util para no repetir intentos fallidos.

## Cuando usarla

Activar cuando ocurra al menos uno de estos casos:

- el usuario deja observaciones de pruebas reales en `docs/revisiones/`;
- se abre una nueva revision del dia o una segunda parte de una revision;
- hace falta consolidar hallazgos antes de implementar;
- existe riesgo de volver a probar soluciones ya descartadas.

Combinar con otras skills segun el tipo de hallazgo:

- `visual-review` para defectos visuales;
- `ux-review` para friccion o comportamiento ambiguo;
- `debugging` para aislar causas tecnicas;
- `qml-ui-creation`, `js-plasma-backend` o `controllers` cuando ya se autorizo implementar;
- `kde-sdk-reference` si la revision toca APIs o patrones de Plasma/KDE.

## Entradas minimas

Antes de actuar, reunir estas piezas:

1. `AGENTS.md` y `.agents/AGENTS.md`.
2. El archivo activo de `docs/revisiones/`.
3. La revision anterior relacionada, si la actual continua una sesion previa.
4. Evidencia disponible: comentarios del usuario, validacion local, notas tecnicas, capturas o pruebas.
5. La plantilla `docs/revisiones/plantilla-revision.md` y la convención de
   nombres del README de la carpeta.

Si falta evidencia de runtime, se puede documentar la revision, pero no marcar un bug como resuelto de forma definitiva.

## Regla de autoria del documento

Dentro de `docs/revisiones/`, asumir esta division de responsabilidades:

- `## Primera revision`, `## Segunda revision`, `## Tercera revision` y siguientes son la zona primaria donde el usuario deja observaciones, bugs, mejoras o notas de prueba;
- el agente no debe reescribir esas observaciones salvo para ordenarlas, corregir errores menores de legibilidad o separarlas mejor por puntos;
- `## Hallazgos confirmados`, `## Plan de accion`, `## Validacion`, `## Implementacion ...` y `### Soluciones ya intentadas para no repetir` quedan bajo responsabilidad del agente;
- si el usuario cambia el contenido de una revision numerada, el agente debe volver a alinear el resto del documento con ese nuevo reporte y descartar analisis heredados que ya no correspondan.

La prioridad siempre sale desde las revisiones numeradas hacia abajo, nunca al reves.

## Orden obligatorio

Seguir siempre esta secuencia y no saltarla:

### 1. Contextualizar la revision

- registrar fecha exacta y estado (`abierta` o `cerrada`);
- explicar si la revision inicia ciclo, continua una revision previa o retoma un pendiente;
- anotar el entorno real cuando el usuario lo haya dado: distro, Plasma, orientacion, modo panel o flotante.

### 2. Transcribir las observaciones sin reinterpretarlas

- copiar las observaciones del usuario con el menor cambio posible;
- corregir solo lo necesario para claridad estructural;
- no convertir una sospecha en hallazgo;
- mantener separadas revisiones sucesivas del mismo dia.

Tratar `Primera revision`, `Segunda revision`, `Tercera revision` y equivalentes como entradas fuente. Si su contenido cambia, revisar y regenerar el resto de las secciones derivadas.

### 3. Clasificar cada observacion

Para cada punto, decidir explicitamente si es:

- `bug confirmado por usuario`;
- `hipotesis pendiente de reproducir`;
- `mejora o decision de producto`;
- `quirk de herramienta de prueba`;
- `pendiente fuera de alcance de esta sesion`.

Si algo solo falla en `plasmoidviewer` y no en Plasma real, dejarlo como quirk del visor salvo evidencia contraria.

### 4. Redactar hallazgos confirmados

Solo entran aqui problemas con evidencia suficiente. Cada hallazgo debe responder:

- que pasa;
- bajo que condicion ocurre;
- que capa parece involucrada;
- que evidencia lo sostiene.

No incluir soluciones en esta seccion.

### 5. Construir el plan de accion

El plan debe ser secuencial, pequeno y comprobable:

1. primero confirmar o acotar la causa;
2. luego aplicar el cambio minimo necesario;
3. despues validar flujo normal, borde y regresiones previsibles;
4. por ultimo decidir si la revision sigue abierta o puede cerrarse.

Si el problema es grande, dividir por fases o sesiones. No prometer cierre total sin evidencia.

### 6. Implementar con trazabilidad

Cuando se hagan cambios:

- crear una seccion `Implementacion revision N° ...`;
- describir que se cambio y por que;
- registrar correcciones de diagnostico si una hipotesis anterior fue falsa;
- dejar constancia de codigo retirado o caminos descartados cuando eso evite recaidas.

### 7. Registrar soluciones ya intentadas

Esta seccion es obligatoria cuando hubo mas de un intento o un bug persistente.

Documentar:

- que se probo;
- por que parecia razonable;
- por que no debe repetirse sin evidencia nueva.

No borrar intentos fallidos relevantes; condensarlos para que la siguiente sesion no vuelva al mismo bucle.

### 8. Validar con honestidad

Separar con claridad:

- validacion manual del usuario;
- validacion local en Plasma real;
- revision estatica;
- puntos aun pendientes.

Nunca escribir que algo quedo "perfecto" o "cerrado" si solo hubo inspeccion estatica.

### 9. Cerrar, mantener abierta o dejar en validación

Cerrar solo cuando:

- el hallazgo fue validado en el entorno pertinente;
- no quedan dudas materiales sobre la regresion principal;
- la documentacion deja claro que no debe reabrirse sin evidencia nueva.

Si existe una corrección, pero falta una comprobación definida, usar
`Estado: en validación.`. Si falta una decisión explícita del usuario, usar
`Estado: pendiente de decisión.`. En cualquier otro caso incompleto, mantener
`Estado: abierta.`.

## Estructura recomendada del documento

Usar esta secuencia de encabezados como base:

```md
# Revision del plasmoide

Archivo: `revision-YYYY-MM-DD-descriptor.md`

Fecha: YYYY-MM-DD

Estado: abierta.

## Contexto
## Observaciones
## primera revision
## segunda revision
## Hallazgos confirmados
## Plan de accion
## Validacion
## Implementacion revision N° ...
### soluciones ya intentadas para no repetir
```

No todas las subsecciones son obligatorias en todas las sesiones, pero el orden general si lo es.

## Reglas de consistencia

- usar fechas absolutas, no "hoy", "ayer" o "mañana";
- distinguir siempre evidencia del usuario, evidencia del agente e inferencia;
- tratar las revisiones numeradas como fuente canonica del reporte del usuario;
- si `Hallazgos confirmados`, `Plan de accion` o `Validacion` quedaron desalineados respecto de una revision numerada nueva, reescribir esas secciones antes de continuar;
- no mezclar en una sola lista bugs, decisiones de diseno y tareas futuras sin etiquetarlos;
- cuando una revision nueva continue otra previa, resumir la herencia en `Contexto` en vez de duplicar todo el historial;
- si una solucion cambia el criterio de funcionamiento esperado, actualizar tambien la seccion de validacion vigente;
- si una revision produce una decision tecnica durable, reflejarla ademas en `bitacora/`.

## Antipatrones a evitar

- improvisar un formato distinto cada dia;
- reabrir intentos descartados sin citar que cambio;
- cerrar revisiones por intuicion;
- usar `Hallazgos confirmados` como lista de deseos;
- ocultar que una prueba fue solo estatica;
- mezclar implementacion con observaciones del usuario en la misma seccion.

## Salida esperada

Al terminar una sesion de revision, debe quedar al menos uno de estos resultados:

- una revision ordenada y lista para implementar;
- una revision implementada con validacion y pendientes honestos;
- una revision cerrada con criterio de no reabrir sin evidencia nueva.

Si la solicitud consiste en convertir una revision en rutina base, esta skill pasa a ser la referencia prioritaria para futuras revisiones del usuario en `docs/revisiones/`.
