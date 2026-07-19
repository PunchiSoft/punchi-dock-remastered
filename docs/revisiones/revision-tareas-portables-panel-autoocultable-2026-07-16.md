# Revisión del plasmoide: tareas portables y panel autoocultable

Fecha: 2026-07-16

Estado: abierta.

## Contexto

La revisión se realiza en Fedora 44, Plasma 6 y Wayland sobre una instancia de
Punchi Dock integrada en un panel horizontal.

## Primera revisión

"No detecta una aplicación portable como Antigravity ni específicamente la
ventana donde VirtualBox simula el sistema operativo. Al configurar el panel
para ocultarse automáticamente, los iconos se vuelven más pequeños; siguen
funcionando y recuperan su tamaño al volver a Siempre visible."

## Información adicional del usuario

- Antigravity no está instalada mediante un archivo de aplicación; es portable.
- La bandeja del sistema sí muestra un icono publicado por Antigravity.
- Se inició una máquina virtual para apoyar la inspección de la ventana de
  ejecución de VirtualBox.

## Hallazgos confirmados

### Reducción de iconos

Punchi calculaba el grosor del panel mediante la diferencia entre
`screenGeometry` y `availableScreenRect`. Un panel autoocultable deja de
reservar espacio de pantalla, por lo que esa diferencia pasa a cero aunque la
geometría visual del panel no haya cambiado. El fallback volvía a dividir el
tamaño configurado por la escala de hover y reducía todos los iconos.

### Identidad incompleta de tareas

Punchi comparaba lanzadores y ventanas únicamente mediante `AppId`. El modelo
oficial de KDE también usa `LauncherUrlWithoutIcon`; esta segunda identidad es
necesaria cuando una ventana y su lanzador publican identificadores distintos,
como puede ocurrir con la ventana de ejecución de VirtualBox.

### Iconos de aplicaciones portables

Cuando no existe un servicio instalado, `SystemDiscovery` no puede resolver el
icono por `KService`. TaskManager entrega además el icono asociado a la ventana
mediante `Qt.DecorationRole`, pero Punchi no lo utilizaba como respaldo.

La presencia de un icono en la bandeja confirma que Antigravity publica un
recurso visual, aunque la bandeja y el modelo de tareas son canales distintos.

## Plan de acción

1. Medir el grosor desde la geometría real del containment del panel.
2. Evitar cualquier reducción del tamaño configurado cuando no haya una medida
   válida.
3. Comparar tareas mediante `AppId` o `LauncherUrlWithoutIcon`.
4. Agrupar ventanas que compartan cualquiera de esas identidades.
5. Usar `Qt.DecorationRole` como respaldo del icono de ventanas portables.
6. Validar QML, compilación y comportamiento manual con Antigravity, VirtualBox
   y los modos Siempre visible/Ocultar automáticamente.

## Implementación revisión N° 1

- El grosor del panel se obtiene desde `containment.width` o
  `containment.height`, según orientación.
- El fallback conserva el tamaño configurado sin dividirlo por la escala de
  hover.
- El controlador de tareas normaliza y compara tanto identificadores de
  aplicación como URLs de lanzador.
- La agrupación dinámica acepta coincidencia por cualquiera de ambas
  identidades.
- Los iconos dinámicos aceptan el `QIcon` entregado por `Qt.DecorationRole`
  cuando no existe un icono resoluble mediante `KService`.

## Validación

Validación técnica completada:

- baseline global de `qmllint` conservado:
  - `757` advertencias;
  - `744` `unqualified`;
  - `0` de layout;
  - `13` propiedades conocidas;
  - `0` errores de importación;
- compilación Fedora completada;
- `ctest`: `5/5`;
- paquete local generado e instalado;
- Plasma Shell reiniciado con PID nuevo;
- la copia instalada coincide con `main.qml` y `TaskModelController.qml`;
- journal de arranque sin errores propios de Punchi Dock.

Pendiente de validación manual del usuario:

- alternar entre Siempre visible y Ocultar automáticamente y confirmar que el
  tamaño no cambia;
- comprobar que Antigravity portable usa el icono publicado para su ventana;
- comprobar detección y agrupación de la ventana de ejecución de VirtualBox.

### Soluciones ya intentadas para no repetir

- No inferir el grosor del panel desde el área de trabajo reservada: cambia con
  la política de visibilidad.
- No depender exclusivamente de `KService` para iconos de aplicaciones
  portables.
- No introducir excepciones por nombre para Antigravity o VirtualBox; la
  corrección debe usar las identidades estándar de TaskManager.
