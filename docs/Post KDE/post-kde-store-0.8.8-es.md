# Punchi Dock 0.8.8

Punchi Dock es un dock de lanzadores personalizable y una interfaz de tareas para KDE Plasma 6. Está diseñado principalmente para Wayland y puede funcionar como dock flotante o como parte de un panel de Plasma, respetando el tema activo de Plasma.

La versión 0.8.8 incorpora una biblioteca de temas JSON externos, mejora el tratamiento de aplicaciones portables y ventanas de VirtualBox, mantiene estable el tamaño de los iconos con el autoocultado del panel y refuerza los flujos separados de compilación para Fedora y Debian.

> **Elige el paquete que corresponda a tu sistema**
>
> Punchi Dock contiene un módulo nativo Qt/KDE. Los paquetes `.plasmoid` de Fedora y Debian no son intercambiables. Nunca instales en Debian un `.plasmoid` etiquetado para Fedora ni un paquete etiquetado para Debian en Fedora.

## Aspectos destacados de 0.8.8

### Temas JSON externos

- Importación de un archivo JSON o exploración recursiva de una carpeta y sus subcarpetas.
- Los temas se validan y copian a una biblioteca administrada del usuario.
- Los archivos duplicados, inválidos, demasiado grandes, ilegibles o incompatibles se rechazan de forma segura.
- Los temas instalados pueden borrarse desde la configuración de Apariencia.
- Si el tema seleccionado desaparece o deja de ser válido, Punchi Dock vuelve al fondo Plasma.
- Los archivos y presets de temas no se incluyen en el `.plasmoid`; continúan siendo contenido externo del usuario.

El primer esquema admite fondos planos 2D y fondos de repisa 2.5D. Cada tema puede definir gradientes, bordes, esquinas, sombras, rims, facetas y separadores coordinados. El glow se limita para impedir que separadores y rims sobresalgan del dock.

Los temas externos se aplican actualmente al dock flotante. Una instancia dentro de un panel Plasma conserva el fondo nativo del panel.

### Tareas y aplicaciones portables

- La asociación de tareas sigue el criterio estándar de KDE comparando `AppId` y `LauncherUrlWithoutIcon`.
- Las aplicaciones portables sin servicio de escritorio instalado pueden usar el icono publicado por su propia ventana.
- Las ventanas cuya identidad difiere de la del lanzador disponen de una segunda vía estándar de asociación, mejorando casos como las máquinas de VirtualBox.
- La agrupación dinámica conserva ambas identidades en lugar de depender de un único identificador exacto.

### Comportamiento del panel

- El tamaño de los iconos ya no cambia al alternar entre Siempre visible y Ocultar automáticamente.
- El grosor se obtiene desde la geometría real del panel, no desde el área de trabajo reservada que desaparece con el autoocultado.
- Si la geometría no está disponible temporalmente, se conserva el tamaño configurado.

### Configuración y empaquetado

- El visualizador de audio tiene ahora su propia página de configuración.
- Debian compila en una carpeta de caché fuera de las carpetas compartidas de VirtualBox.
- Fedora y Debian conservan baselines de `qmllint` independientes porque sus versiones de Qt generan diagnósticos diferentes.
- Se restauró compatibilidad con Qt 6.8 en los diálogos de importación.
- El script de prueba verifica la instalación y confirma que Plasma Shell reinició realmente con un proceso nuevo.

## Características

- Modos dock flotante y panel de Plasma.
- Lanzadores fijados y grupos de tareas dinámicas opcionales.
- Tarjetas de ventanas, miniaturas vivas proporcionadas por el compositor, acciones para ventanas agrupadas y gestión de desbordamiento.
- Contenedores de carpetas configurables, notas rápidas, papelera, calendario, reloj, separadores y espaciadores.
- Animaciones configurables de apertura de popups y transiciones fluidas entre vistas previas y acciones.
- Acciones nativas de archivos `.desktop` y controles de ventana en los menús contextuales.
- Tarjetas multimedia MPRIS adaptables con carátula, información de pista y controles de reproducción.
- Visualizador de audio PipeWire nativo y opcional con seis estilos, densidad configurable, colores dinámicos o adaptados al tema, dirección y flujo.
- Operaciones asíncronas de papelera mediante KIO con progreso, información de estado, sonido de finalización y notificaciones adaptadas al tema.
- Biblioteca de temas JSON externa que admite fondos planos 2D y de repisa 2.5D.

## Compatibilidad

- KDE Plasma 6 o posterior está declarado en los metadatos.
- Wayland es la sesión principalmente soportada.
- Fedora 44 o posterior sobre `x86_64` continúa siendo el objetivo principal para paquetes precompilados.
- Un artefacto para Debian 13 `x86_64`, compilado por separado, superó las validaciones de compilación, instalación e inicio; la revisión funcional más amplia continúa en curso.
- PipeWire sólo es necesario para el visualizador de audio opcional.

El `.plasmoid` incluye binarios nativos enlazados con las bibliotecas Qt y KDE del entorno de compilación. No debe presentarse como un único paquete universal para todas las distribuciones Linux o arquitecturas de CPU.

Las miniaturas vivas de ventanas dependen del soporte del compositor y pueden usar tarjetas de ventanas como fallback cuando no están disponibles. Los paneles verticales continúan soportados, aunque el ajuste visual avanzado se centra principalmente en docks y paneles horizontales.

## Rendimiento y privacidad

Punchi Dock no depende de herramientas externas de automatización para X11 como `xdotool`, `wmctrl` o `xprop`, y no modifica los archivos de configuración global de Plasma.

El visualizador de audio procesa niveles de espectro temporales en memoria. No almacena muestras de audio ni las transmite por la red. Plasma puede seguir mostrando un indicador de grabación porque la monitorización de la salida requiere un flujo de entrada de audio.

## Nota de actualización

Después de actualizar, reinicia Plasma Shell una vez o cierra y vuelve a iniciar sesión si el dock no se actualiza inmediatamente. La configuración existente se conserva.

## Licencia

GPL-3.0-or-later

## Registro de cambios

### Versión 0.8.8

- Añadida biblioteca administrada de temas JSON externos.
- Añadida importación recursiva de carpetas y borrado de temas instalados.
- Añadidos renderers plano 2D y repisa 2.5D con separadores temáticos.
- Los temas externos permanecen fuera del `.plasmoid` distribuido.
- Añadido fallback de icono para ventanas portables mediante TaskManager.
- Mejorada la asociación entre lanzadores y ventanas usando identificadores y URLs de lanzador.
- Corregida la reducción de iconos en paneles autoocultables.
- Movida la configuración del visualizador a una página independiente.
- Mejorada la compatibilidad Debian Qt 6.8 y la compilación en VirtualBox.
- Añadidas pruebas de validador y repositorio; la suite actual pasa `5/5`.
