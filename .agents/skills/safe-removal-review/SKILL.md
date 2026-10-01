---
name: safe-removal-review
description: Revisar y ejecutar eliminaciones, sobrescrituras, movimientos, renombrados masivos y retiros de funciones sin perder datos ni dejar referencias huérfanas. Usar antes de borrar archivos o directorios, reemplazar destinos, normalizar nombres en lote, mover documentación ignorada por Git, retirar código, opciones, componentes, claves KConfig o dependencias de Punchi Dock.
---

# Eliminación, movimiento y retiro seguros

## Principio no negociable

Tratar como operación destructiva cualquier acción que pueda reducir el
inventario o volver irrecuperable contenido existente. Incluye:

- borrar archivos, directorios, funciones o configuración;
- sobrescribir un destino durante `mv`, `cp`, generación o extracción;
- mover o renombrar dos o más rutas;
- sustituir un archivo por otro aunque el nombre final permanezca;
- retirar código, textos, pruebas, dependencias o claves persistidas.

Una sobrescritura es una eliminación del contenido anterior. Un renombrado no
está autorizado para reducir la cantidad de archivos salvo que el usuario haya
pedido explícitamente una consolidación o eliminación.

## Puerta previa obligatoria

No mutar el árbol hasta completar todos estos pasos:

1. Delimitar la intención: eliminación definitiva, movimiento, renombrado,
   reemplazo, desactivación reversible o migración.
2. Resolver una lista exacta de orígenes y destinos dentro de la raíz
   autorizada. No depender de globs, variables vacías ni rutas implícitas.
3. Ejecutar inventario de solo lectura con `rg --files`, `find`, `git status
   --short` y `git check-ignore -v` cuando corresponda.
4. Registrar para material importante tamaño y, si el riesgo lo justifica,
   hash antes de modificar.
5. Determinar si cada archivo está rastreado, ignorado o no rastreado. No asumir
   que Git puede recuperar documentación local.
6. Crear respaldo recuperable antes de tocar archivos ignorados o no
   rastreados. No considerar `/tmp` como único respaldo durable.
7. Detenerse y pedir confirmación si la eliminación material no fue solicitada
   de forma explícita o si el alcance exacto no puede demostrarse.

Clasificar el preflight como `apto para modificar`, `requiere mitigación` o
`detenido a la espera del usuario`.

## Renombrados y movimientos en lote

Para dos o más rutas, separar obligatoriamente planificación y ejecución.

### Fase 1: materializar el mapa

Construir y revisar una tabla completa:

```text
origen -> destino
```

Validar antes de mover:

- todos los orígenes existen y son únicos;
- ningún origen aparece también de forma accidental como destino intermedio;
- ningún destino está vacío ni sale de la raíz autorizada;
- todos los destinos son únicos;
- la cantidad de destinos únicos coincide con la cantidad de orígenes;
- ningún destino preexistente será reemplazado;
- los cambios de mayúsculas, acentos, espacios y extensiones son intencionales;
- los ciclos o intercambios de nombres usan una fase temporal explícita.

Si falla una sola condición, no ejecutar ninguna mutación.

### Fase 2: ejecutar sin sobrescritura

- Preferir movimientos explícitos y pequeños mediante `apply_patch` cuando se
  trate de documentación o código textual.
- No usar `mv` con sobrescritura por defecto en un lote.
- Si se necesita `mv`, comprobar primero que el destino no existe, usar una
  modalidad sin clobber y verificar después que cada origen desapareció solo
  porque su destino válido existe.
- No calcular un destino y moverlo dentro del mismo bucle sin haber validado
  previamente el mapa completo.
- Ejecutar primero una muestra de un solo archivo cuando el patrón sea nuevo y
  volver a comparar inventario antes de continuar.

### Estado mutable de expresiones regulares

`BASH_REMATCH` cambia con cada evaluación `=~`. No leer sus grupos después de
otra expresión regular.

Si es imprescindible usarlo:

1. evaluar una sola expresión;
2. copiar inmediatamente cada captura a variables con nombres específicos;
3. validar que ninguna captura esté vacía;
4. no ejecutar otra expresión regular hasta terminar esa transformación.

Preferir transformaciones que no dependan de estado global mutable. Un valor
vacío para fecha, descriptor, basename o destino es condición de parada.

## Eliminación de archivos y directorios

1. Mostrar la lista exacta de objetivos y comprobar su tipo, tamaño, estado Git
   y consumidores.
2. Preferir una operación recuperable o un respaldo antes de eliminar.
3. No usar rutas amplias, globs no resueltos, variables de entorno genéricas ni
   recursión sobre la raíz del proyecto.
4. No retirar el último respaldo disponible.
5. Informar después qué se eliminó, por qué era seguro y cómo puede recuperarse.

## Retiro de funcionalidad

Identificar la función por sus identificadores, texto visible, clave KConfig,
componentes, imports, pruebas y documentación. Ejecutar `rg` en `contents/`,
`tests/`, scripts, catálogos y documentación activa.

Comprobar cada capa aplicable:

- declaración KConfig, defaults, grupos y configuración existente;
- propiedades `cfg_*`, aliases, bindings, señales y consumidores QML;
- componentes, imports, instancias y propiedades puente;
- textos, accesibilidad, PO/POT y ayudas visibles;
- pruebas, scripts, metadata, `.kpackageignore` y paquete.

Preferir retirar la cadena completa de una función: clave, control, consumidor,
componente auxiliar, pruebas y textos. Si hay configuración persistida,
documentar si se conserva, migra o elimina mediante una migración explícita.

Para XML, validar estructura antes y después con `xmllint --noout`. Nunca dejar
etiquetas, propiedades ni referencias huérfanas.

## Postflight obligatorio

Después de cada lote pequeño:

1. Comparar cantidad de archivos antes y después. Toda reducción no autorizada
   es un incidente y obliga a detenerse.
2. Verificar que cada destino existe, no está vacío y conserva el tamaño o hash
   esperado cuando aplique.
3. Buscar nombres antiguos y actualizar referencias, enlaces e índices.
4. Repetir `git status --short`, `git diff --check` y el inventario del área.
5. Ejecutar validadores proporcionales: enlaces para documentación, `xmllint`
   para XML, `qmllint` para QML, catálogos para textos y CTest/empaquetado para
   cambios del plasmoide.
6. No retirar copias legacy ni respaldos hasta validar destinos y referencias.

## Respuesta ante un incidente

Si el inventario disminuye, aparece una colisión o se sobrescribe un destino:

1. detener inmediatamente todas las mutaciones;
2. preservar el estado actual antes de intentar recuperar;
3. no volver a ejecutar el comando defectuoso;
4. inventariar supervivientes, faltantes y fuentes de recuperación;
5. restaurar solo destinos ausentes, sin reemplazar material superviviente;
6. distinguir contenido recuperado literalmente de contenido reconstruido;
7. documentar causa raíz, impacto, validación y barrera preventiva.

## Entrega

Informar:

- operación autorizada y lista exacta de objetivos;
- respaldo y recuperabilidad;
- mapa validado para movimientos o renombrados;
- elementos retirados, movidos, restaurados o reconstruidos;
- comprobaciones de inventario, referencias, sintaxis y runtime;
- riesgos pendientes y cualquier material que continúe fuera de Git.

No declarar una operación limpia sin inventario posterior y búsqueda de
referencias.
