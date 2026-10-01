---
name: modification-cycle
description: Conducir solicitudes de nuevas modificaciones de Punchi Dock siempre en el mismo orden, usando `docs/nuevas-modificaciones/` como fuente de verdad para registrar contexto, alcance confirmado, riesgos, plan, validacion, implementacion y decisiones futuras. Usar cuando el usuario proponga features, mejoras, nuevas opciones o ampliaciones del dock y no un bug correctivo.
---

# Ciclo de nuevas modificaciones

## Objetivo

Evitar que las nuevas capacidades del dock se documenten e implementen de forma improvisada. Esta skill fija un orden unico para:

- recoger la propuesta del usuario;
- separar alcance, riesgos y dependencias;
- introducir la modificacion con el cambio minimo razonable;
- dejar memoria util para futuras fases sin mezclarla con revisiones de bugs.

## Cuando usarla

Activar cuando ocurra al menos uno de estos casos:

- el usuario pide una mejora o capacidad nueva en `docs/nuevas-modificaciones/`;
- se quiere registrar una funcion nueva antes de implementarla;
- hace falta dividir una mejora grande en fases limpias;
- se necesita conservar decisiones de producto o de arquitectura ligadas a una modificacion.

Combinar con otras skills segun el tipo de trabajo:

- `ui-design` si la modificacion exige decidir estructura o jerarquia visual;
- `visual-review` si la mejora requiere comprobar acabado visual ya implementado;
- `qml-ui-creation`, `js-plasma-backend` o `controllers` cuando ya se autorizo implementar;
- `kde-sdk-reference` si la modificacion toca APIs o patrones de Plasma/KDE;
- `testing` cuando la fase requiera pruebas adicionales o validaciones guiadas.

## Entradas minimas

Antes de actuar, reunir estas piezas:

1. `AGENTS.md` y `.agents/AGENTS.md`.
2. El archivo activo de `docs/nuevas-modificaciones/`.
3. La modificacion anterior relacionada, si la actual continua una sesion previa.
4. Evidencia disponible: pedido del usuario, restricciones, decisiones previas, validacion local y notas tecnicas.
5. La plantilla `docs/nuevas-modificaciones/plantilla-modificacion.md` y la
   convención de nombres del README de la carpeta.

Si la propuesta aun es abierta o ambigua, se puede documentar el alcance y el plan sin afirmar que la modificacion ya quedo validada.

## Regla de autoria del documento

Dentro de `docs/nuevas-modificaciones/`, asumir esta division de responsabilidades:

- `## Primera modificacion`, `## Segunda modificacion`, `## Tercera modificacion` y siguientes son la zona primaria donde el usuario deja la propuesta o ampliacion;
- el agente no debe reescribir esas observaciones salvo para ordenarlas, corregir errores menores de legibilidad o separarlas mejor por puntos;
- `## Alcance confirmado`, `## Riesgos y dependencias`, `## Plan de implementacion`, `## Validacion`, `## Implementacion ...`, `### Decisiones tomadas ...` y `### Soluciones descartadas ...` quedan bajo responsabilidad del agente;
- si el usuario cambia el contenido de una modificacion numerada, el agente debe volver a alinear el resto del documento con ese nuevo pedido y descartar analisis heredados que ya no correspondan.

La prioridad siempre sale desde las modificaciones numeradas hacia abajo, nunca al reves.

## Orden obligatorio

Seguir siempre esta secuencia y no saltarla:

### 1. Contextualizar la modificacion

- registrar fecha exacta y estado (`abierta`, `implementada; pendiente de
  validación`, `cerrada` o `descartada`);
- explicar si la modificacion inicia una linea nueva o continua una fase previa;
- anotar restricciones tecnicas, de compatibilidad, de diseno o de entorno cuando existan.

### 2. Transcribir la propuesta sin reinterpretarla

- copiar la solicitud del usuario con el menor cambio posible;
- corregir solo lo necesario para claridad estructural;
- no ampliar por cuenta propia el alcance;
- mantener separadas modificaciones sucesivas del mismo dia.

Tratar `Primera modificacion`, `Segunda modificacion`, `Tercera modificacion` y equivalentes como entradas fuente. Si su contenido cambia, revisar y regenerar el resto de las secciones derivadas.

### 3. Confirmar el alcance real

Para cada propuesta, decidir explicitamente:

- que si entra en esta sesion;
- que queda fuera para no mezclar alcance;
- que dependencias previas condicionan la implementacion;
- si la mejora requiere una sola fase o varias.

### 4. Redactar el alcance confirmado

Solo entran aqui compromisos reales de la sesion. Cada punto debe responder:

- que se va a agregar o cambiar;
- que capa o modulo quedara afectado;
- que limites se mantienen para no abrir una reescritura;
- que piezas existentes se van a reutilizar.

### 5. Registrar riesgos y dependencias

Documentar aqui consecuencias no obvias, por ejemplo:

- diferencias entre apps nativas, Flatpak o lanzadores indirectos;
- persistencia o configuraciones previas del usuario;
- impactos en runtime, KCM, empaquetado o arquitectura.

### 6. Construir el plan de implementacion

El plan debe ser secuencial, pequeno y comprobable:

1. confirmar el alcance funcional exacto;
2. localizar la capa adecuada;
3. aplicar el cambio minimo necesario;
4. validar el flujo nuevo y vigilar regresiones previsibles;
5. dividir por fases o sesiones si hace falta.

### 7. Implementar con trazabilidad

Cuando se hagan cambios:

- crear una seccion `Implementacion modificacion N° ...`;
- describir que se cambio y por que;
- registrar limites deliberados de la fase;
- dejar constancia de decisiones que la siguiente fase debe respetar.

### 8. Validar con honestidad

Separar con claridad:

- validacion manual del usuario;
- validacion del usuario en entorno local cuando exista confirmacion explicita posterior;
- validacion local en Plasma real;
- revision estatica o sintactica;
- puntos aun pendientes.

**Verificaciones Obligatorias Posteriores a Cada Modificación**:
Aplicar la lista vigente del «Protocolo de validación proporcional posterior a
modificaciones» de `AGENTS.md`, sin mantener aquí una copia propia de los gates.
El agente **debe entregar obligatoriamente la tabla con esas métricas en la
respuesta final**.

Si el usuario confirma que la mejora funciona, esa evidencia debe quedar visible como validacion propia y no escondida como subpunto de cierre.

### 9. Cerrar, mantener abierta o dejar pendiente de validación

Cerrar solo cuando:

- la capacidad nueva quedo implementada;
- el nivel de validacion es proporcional al riesgo;
- no quedan dudas materiales sobre la fase comprometida;
- el documento deja claro que futuras ampliaciones ya pertenecen a otra modificacion o fase.

Si el cambio ya está implementado, pero falta una prueba definida, usar
`Estado: implementada; pendiente de validación.`

Si la propuesta o implementación todavía está en curso, mantener
`Estado: abierta.`. Si se decide no implementarla, usar `Estado: descartada.`.

## Estructura recomendada del documento

Usar esta secuencia de encabezados como base:

```md
# Modificaciones del plasmoide

Archivo: `modificaciones_YYYY-MM-DD-descripcion-breve.md`

Fecha: YYYY-MM-DD

Estado: abierta.

## Contexto
## Objetivo de la modificacion
## Observaciones
## Primera modificacion
## Segunda modificacion
## Alcance confirmado
## Riesgos y dependencias
## Plan de implementacion
## Validacion
## validacion del usuario en entorno local
## Implementacion modificacion N° ...
### Decisiones tomadas para futuras fases
### Soluciones descartadas para no mezclar alcance
```

No todas las subsecciones son obligatorias en todas las sesiones, pero el orden general si lo es.

## Reglas de consistencia

- usar fechas absolutas, no "hoy", "ayer" o "mañana";
- distinguir siempre pedido del usuario, evidencia del agente e inferencia;
- tratar las modificaciones numeradas como fuente canonica del pedido del usuario;
- si `Alcance confirmado`, `Riesgos y dependencias`, `Plan de implementacion` o `Validacion` quedaron desalineados respecto de una modificacion numerada nueva, reescribir esas secciones antes de continuar;
- no mezclar una mejora nueva con un bug correctivo salvo que el usuario pida explicitamente trabajar ambas cosas juntas;
- si una fase nueva continua una anterior, resumir la herencia en `Contexto` en vez de duplicar todo el historial;
- si una decision tecnica cambia el rumbo de futuras fases, reflejarla tambien en `bitacora/`.

## Antipatrones a evitar

- improvisar un formato distinto cada vez que se agrega una feature;
- convertir una modificacion pequena en una reescritura sin acordarlo;
- dejar confirmaciones del usuario escondidas como notas informales;
- mezclar alcance confirmado con ideas futuras no comprometidas;
- presentar como validada una mejora que solo tuvo inspeccion estatica;
- usar la seccion de implementacion para redefinir el objetivo original.

## Salida esperada

Al terminar una sesion de modificacion, debe quedar al menos uno de estos resultados:

- una modificacion ordenada y lista para implementar;
- una modificacion implementada con validacion y siguientes fases claras;
- una modificacion cerrada con criterio de continuidad futura bien separado.

Si la solicitud consiste en convertir este flujo en rutina base, esta skill pasa a ser la referencia prioritaria para futuras solicitudes en `docs/nuevas-modificaciones/`.
