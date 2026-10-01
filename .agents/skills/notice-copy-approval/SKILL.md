---
name: notice-copy-approval
description: Redactar y hacer aprobar por el usuario toda nota, aviso, advertencia o explicación dirigida a quien usa Punchi Dock antes de implementarla. Usar cuando una tarea añada o cambie un texto que explique una función, un modo, un límite o una precaución —notas de paneles de configuración, avisos y advertencias, tooltips explicativos, textos de ayuda bajo un control, estados vacíos con causa, mensajes de error explicativos, leyendas de manuales o capturas, y cualquier redacción donde el usuario pida "algo así" o "mejóralo"—, o cuando se decida el énfasis de ese texto (qué parte va en negrita). La propuesta se muestra y espera confirmación explícita antes de tocar código, catálogos o documentos. No usar para etiquetas, botones, títulos o nombres de opciones cuyo texto ya define la función, ni para documentación interna del proyecto.
---

# Aprobación previa del texto explicativo

## Objetivo

Ningún texto que explique algo a quien usa Punchi Dock se implementa antes de que
el usuario haya leído y aprobado su redacción y su énfasis. Esta skill convierte
las notas y advertencias en una decisión revisable en lugar de un efecto lateral
de la implementación.

## Por qué existe

Caso registrado (2026-09-26): la nota del tipo seleccionado en la página Elementos
se redactó, tradujo e implementó en la misma sesión sin que el usuario viera el
texto antes. El usuario había pedido «algo así o mejóralo si puedes», y la mejora
de la redacción —y después el énfasis— fue una decisión de producto tomada por el
agente. Ambas cosas se corrigieron luego. Esta skill evita repetirlo.

Aclaración que la motiva: pedir mejorar una redacción **no** delega la decisión.
La mejora sigue siendo una propuesta que el usuario confirma.

## Cuándo activarla

Textos que explican algo al usuario:

- notas dentro de paneles de configuración o de la interfaz;
- avisos, advertencias y precauciones («solo cabe un…», «esto reinicia…», «no
  disponible en Wayland»);
- tooltips que explican para qué sirve un control;
- textos de ayuda bajo un control;
- estados vacíos o mensajes de error que explican una causa o una salida;
- descripciones de funciones, modos, límites o compatibilidad;
- leyendas, referencias y notas de manuales, guías o capturas dirigidas al
  usuario final.

También se activa cuando se decide el **énfasis** de un texto ya aprobado: qué
parte va en negrita y qué parte queda en peso normal.

No hace falta activarla para:

- etiquetas, botones, títulos y nombres de opciones cuyo texto ya define la
  función y el idioma del proyecto;
- mensajes internos de log, de pruebas o de scripts;
- documentación puramente interna (bitácora, revisiones, modificaciones) que
  describe el trabajo del proyecto y no una función para el usuario.

## Procedimiento

1. **Clasificar.** Identificar el texto, su destino (interfaz, catálogo,
   documento público) y si explica, advierte o describe.
2. **Verificar antes de redactar.** Comprobar en el código los nombres reales de
   opciones, modos, estados y límites. La nota describe lo que la app hace hoy:
   no inventar funciones, modos, precauciones ni promesas.
3. **Redactar la propuesta** con el formato de la sección siguiente.
4. **Presentar y detenerse.** Pedir confirmación explícita y no implementar, ni
   traducir, ni extraer catálogos, ni editar documentos antes de la respuesta.
   El silencio no autoriza: la tarea queda pendiente de esa confirmación.
5. **Implementar lo aprobado, literalmente.** Si al implementar aparece una
   necesidad de cambiar la redacción —una traducción no cabe, una etiqueta real
   se llama distinto, el ancho obliga a acortar— se vuelve al paso 3 con el
   delta y se confirma solo lo que cambia.
6. **Registrar** la redacción aprobada y su fecha en la modificación o la
   revisión correspondiente.
7. **Cerrar el ciclo del texto** con `ki18n-localization` cuando el texto sea
   traducible, y medir con la sonda disponible cuando pueda desbordar.

## Formato de la propuesta

```text
Ubicación y disparador: archivo o componente, y cuándo aparece el texto.
Propuesta (en inglés, idioma fuente): "<texto>"
Traducción al español: "<texto>"
Énfasis: qué parte va en negrita y qué parte en peso normal.
Extensión: caracteres y líneas esperadas en el ancho disponible.
Qué no dice: límites, casos que la nota deja fuera.
Efecto: qué cambia en la interfaz y si exige traducción nueva.
```

Cuando el tono o la extensión sean discutibles, ofrecer como máximo tres
variantes, marcar la recomendada y explicar la diferencia en una línea.

## Reglas

- El texto aprobado se implementa tal cual: no volver a «mejorarlo» al codificar.
- Tras la etiqueta corta, la frase empieza con mayúscula, en el mensaje fuente y en
  cada traducción. La etiqueta no es la primera palabra de la oración.
- Una nota no justifica una decisión que el usuario no tomó: si falta
  información, preguntar antes de escribir.
- No prometer funciones, fechas ni compatibilidad dentro de una nota.
- Reutilizar los términos que la interfaz ya muestra y ya traduce; si hace falta
  un término nuevo, proponerlo como parte de la nota.
- Una nota no debe ser el único lugar donde vive una información crítica: si el
  dato importa para operar el dock, también debe estar donde se actúa.
- El marcado forma parte de la redacción: si el texto lleva `<b>` o saltos, la
  propuesta debe mostrarlo y la traducción debe conservarlo.
- Medir cuando el texto pueda desbordar, y usar la evidencia para decidir la
  extensión, no la impresión visual.

## Antipatrones

- Implementar, traducir y extraer catálogos en la misma pasada que la redacción.
- Interpretar «mejora la redacción» como autorización para decidir el contenido.
- Cambiar la negrita, la longitud o el tono sin confirmar, aunque el texto base
  ya esté aprobado.
- Empezar la frase en minúscula después de la etiqueta, o dejar la corrección de
  mayúsculas solo en el idioma que se revisó a mano: el defecto se replica en los
  demás catálogos si no se corrige el mensaje fuente.
- Escribir la nota desde la memoria del agente sin comprobar los nombres reales
  de las opciones en el código.
- Presentar la nota ya traducida e implementada como si fuera una propuesta.

## Relación con otras skills

- `modification-cycle`: el paso de confirmar el alcance de la sesión es donde se
  presenta la propuesta de texto.
- `ki18n-localization`: se aplica **después** de la aprobación, para extracción,
  traducción y validación de catálogos.
- `ux-review` y `ui-design`: pueden aportar dónde hace falta una nota y por qué;
  la redacción concreta sigue este procedimiento.
