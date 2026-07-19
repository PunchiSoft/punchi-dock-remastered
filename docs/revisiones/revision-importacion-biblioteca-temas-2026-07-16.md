# Revisión del plasmoide: importación y biblioteca de temas

Fecha: 2026-07-16

Estado: abierta.

## Contexto

La revisión continúa la modificación de biblioteca administrada después de
instalar el paquete Fedora con importación recursiva y borrado de temas.

Entorno confirmado:

- Fedora 44;
- Plasma 6 sobre Wayland;
- paquete local `0.8.7`;
- biblioteca de diecisiete temas JSON externos.

## Primera revisión

"Probé eliminando todo y cargando los nuevos con la organización actual;
funciona. Noté algo raro: al pulsar Import se abrió el explorador de ficheros,
pero se demoró en cargar y se pegó un poco. Necesito saber si fue circunstancial
o si quedó algún error."

## Hallazgos confirmados

### Validación funcional del usuario

El usuario confirmó en Plasma real:

- eliminación completa de la biblioteca;
- importación de `docs/themes/` con carpetas por renderer y por tema;
- descubrimiento correcto de los diecisiete JSON;
- funcionamiento del almacenamiento jerárquico actual.

### Error real durante la reconstrucción del selector

El journal registró al finalizar la importación:

```text
ConfigAspect.qml:402: TypeError: Cannot read property 'length' of undefined
```

`ComboBox.currentValue` queda temporalmente indefinido cuando
`availableThemes` se reconstruye. El botón de borrado leía `.length`
directamente durante ese estado transitorio.

### Demora del selector no atribuida al importador

No se encontraron bloqueos, falta de memoria, presión de swap, errores de
disco, OOM ni timeouts de KIO. La validación de los diecisiete temas tarda
aproximadamente `0,01 s`, y sus escrituras se completaron en menos de una
décima de segundo.

La demora antes de aparecer el selector se clasifica por ahora como arranque
en frío circunstancial del diálogo nativo. No existe evidencia suficiente para
declararla regresión de Punchi Dock.

### Ruido del cargador de configuración

Plasma entrega el mapa completo de configuración al crear cada página del KCM.
Las páginas de Punchi Dock, siguiendo el patrón oficial de páginas separadas,
declaran sólo las claves que editan. El cargador registra advertencias por las
propiedades ajenas.

No se duplicarán todas las claves en todas las páginas: esa solución acoplaría
dominios y podría permitir que una página guardase valores que no controla.
Este ruido se mantiene separado del `TypeError` confirmado.

## Plan de acción

1. Convertir `currentValue` a una cadena segura antes de consultarlo.
2. Verificar el índice contra el tamaño real del modelo antes de acceder.
3. Proteger también la selección de fallback después de borrar un tema.
4. Ejecutar validación QML, compilación, pruebas y empaquetado.
5. Instalar el paquete y revisar el journal durante una nueva importación.

## Implementación revisión N° 1

- El botón de borrado usa `String(currentValue || "")`.
- La solicitud de borrado comprueba que el índice siga dentro del modelo.
- El nombre seleccionado se obtiene desde una entrada protegida con fallback.
- La selección posterior al borrado comprueba que el tema de reemplazo exista.
- Si el fallback no produce un ID, el KCM vuelve al fondo Plasma.

## Validación

Validación técnica completada:

- baseline global de `qmllint` conservado:
  - `757` advertencias;
  - `744` `unqualified`;
  - `0` de layout;
  - `13` propiedades conocidas;
  - `0` errores de importación;
- `ctest`: `5/5`;
- paquete Fedora y paquete local generados correctamente;
- paquete local instalado;
- Plasma Shell reiniciado con PID nuevo;
- diagnóstico de arranque sin errores propios de Punchi Dock;
- la copia instalada contiene las conversiones seguras y comprobaciones de
  índice.

Pendiente:

- nueva importación en Plasma real;
- ausencia del `TypeError` en el journal.

### Soluciones ya intentadas para no repetir

- No atribuir la demora al escaneo JSON: las mediciones muestran un coste
  demasiado pequeño para explicar la apertura lenta del diálogo.
- No declarar todas las claves de configuración en todas las páginas sólo para
  silenciar advertencias del cargador; esa duplicación rompería la separación
  de responsabilidades del KCM.
