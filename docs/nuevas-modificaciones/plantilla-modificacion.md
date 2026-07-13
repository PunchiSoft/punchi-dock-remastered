# Plantilla de modificacion del plasmoide

Fecha: YYYY-MM-DD o YYYY-MM-DD-2

Estado: abierta.

## Contexto

Describir aqui el origen de la modificacion y su relacion con trabajo previo.

Incluir, cuando corresponda:

- si la modificacion nace desde una idea nueva, una necesidad funcional o una continuidad de trabajo;
- el alcance previsto para la sesion;
- restricciones tecnicas, de compatibilidad o de diseno;
- cualquier dependencia previa ya implementada.

## Objetivo de la modificacion

Explicar con una frase clara que se quiere incorporar o mejorar.

Ejemplo:

Añadir una capacidad nueva al dock sin alterar el comportamiento validado de las funciones existentes.

## Observaciones

Registrar aqui el marco general de la propuesta antes de enumerar modificaciones puntuales.

Esta seccion solo prepara el contexto general. Las propuestas concretas del usuario deben vivir en las modificaciones numeradas.

## Primera modificacion

Anotar aqui la solicitud textual del usuario para la primera modificacion.

Esta seccion, y las modificaciones numeradas equivalentes, son la fuente principal del pedido del usuario. El agente debe tomar su contenido como base para construir o actualizar el resto del documento.

- propuesta 1;
- propuesta 2.

## Segunda modificacion

Usar esta seccion solo si existen nuevas solicitudes dentro de la misma jornada o sesion.

- propuesta 1;
- propuesta 2.

Agregar `## Tercera modificacion`, `## Cuarta modificacion` y siguientes cuando el usuario incorpore nuevos pedidos en el mismo documento.

## Alcance confirmado

Registrar aqui lo que realmente se va a implementar en esta sesion a partir de las modificaciones numeradas vigentes.

Cada punto debe dejar claro:

- que se va a agregar o cambiar;
- que parte del dock quedara afectada;
- que limites se imponen para no mezclar trabajo no solicitado;
- que dependencias o piezas existentes se reutilizaran si corresponde.

## Riesgos y dependencias

Documentar aqui las consecuencias no obvias de la modificacion.

Ejemplo:

- posibles diferencias entre apps nativas, Flatpak o lanzadores indirectos;
- necesidad de respetar configuraciones previas del usuario;
- impacto en runtime, configuracion o empaquetado.

## Plan de implementacion

Definir aqui el plan de trabajo en un orden pequeno, secuencial y verificable.

Reglas:

1. confirmar primero el alcance funcional exacto;
2. localizar la capa adecuada para introducir la modificacion;
3. aplicar el cambio minimo necesario;
4. validar el flujo nuevo y vigilar regresiones previsibles;
5. dividir por fases o sesiones si el alcance lo requiere.

## Validacion

Documentar con honestidad que se verifico realmente y que continua pendiente.

Separar siempre:

- validacion manual del usuario;
- validacion local en Plasma real;
- revision estatica o sintactica;
- pendientes no verificados todavia.

Si el usuario confirma despues que la modificacion funciona en su entorno real, registrar esa evidencia en una seccion visible y separada.

## validacion del usuario en entorno local

Usar esta seccion cuando el usuario confirme de forma explicita que la modificacion ya fue probada en su entorno real.

Ejemplo:

- la modificacion funciona correctamente en entorno local;
- en Firefox aparecen las acciones `nueva ventana` y `modo incognito`;
- los comandos sugeridos se ejecutan como se esperaba.

## Implementacion modificacion N° X - YYYY-MM-DD - Sesion N

Describir aqui los cambios realmente aplicados durante la modificacion correspondiente.

Incluir:

- componentes o archivos afectados;
- criterio tecnico seguido;
- decisiones que conviene conservar para futuras sesiones;
- limites deliberados de esta fase.

### Decisiones tomadas para futuras fases

Registrar aqui decisiones tecnicas o de producto que la siguiente sesion debe respetar.

### Soluciones descartadas para no mezclar alcance

Registrar aqui caminos que parecian posibles, pero que se dejaron fuera para no convertir la modificacion en una reescritura o en una mezcla de objetivos.

## Cierre de la modificacion

Cerrar una modificacion solo cuando el comportamiento nuevo quede implementado y validado en el nivel de riesgo adecuado.

Si la verificacion es parcial o la fase continua, mantener:

`Estado: abierta.`

Cuando la modificacion quede finalizada, actualizar:

`Estado: cerrada.`

y dejar constancia breve del criterio de cierre.
