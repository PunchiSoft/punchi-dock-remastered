# Punchi Dock 0.8.8

Punchi Dock 0.8.8 incorpora una biblioteca de temas JSON externos, mejora el
tratamiento de aplicaciones portables y ventanas de VirtualBox, mantiene
estable el tamaño de los iconos con el autoocultado del panel y refuerza los
flujos separados de compilación para Fedora y Debian.

> **Elige el paquete que corresponda a tu sistema**
>
> Punchi Dock contiene un módulo nativo Qt/KDE. Los paquetes `.plasmoid` de
> Fedora y Debian no son intercambiables.

## Temas JSON externos

- Importación de un archivo JSON o exploración recursiva de una carpeta y sus
  subcarpetas.
- Los temas se validan y copian a una biblioteca administrada del usuario.
- Los archivos duplicados, inválidos, demasiado grandes, ilegibles o
  incompatibles se rechazan de forma segura.
- Los temas instalados pueden borrarse desde la configuración de Apariencia.
- Si el tema seleccionado desaparece o deja de ser válido, Punchi Dock vuelve
  al fondo Plasma.
- Los archivos y presets de temas no se incluyen en el `.plasmoid`; continúan
  siendo contenido externo del usuario.

El primer esquema admite fondos planos 2D y fondos de repisa 2.5D. Cada tema
puede definir gradientes, bordes, esquinas, sombras, rims, facetas y
separadores coordinados. El glow se limita para impedir que separadores y rims
sobresalgan del dock.

Los temas externos se aplican actualmente al dock flotante. Una instancia
dentro de un panel Plasma conserva el fondo nativo del panel.

## Tareas y aplicaciones portables

- La asociación de tareas sigue el criterio estándar de KDE comparando
  `AppId` y `LauncherUrlWithoutIcon`.
- Las aplicaciones portables sin servicio de escritorio instalado pueden usar
  el icono publicado por su propia ventana.
- Las ventanas cuya identidad difiere de la del lanzador disponen de una
  segunda vía estándar de asociación, mejorando casos como las máquinas de
  VirtualBox.
- La agrupación dinámica conserva ambas identidades en lugar de depender de un
  único identificador exacto.

## Comportamiento del panel

- El tamaño de los iconos ya no cambia al alternar entre Siempre visible y
  Ocultar automáticamente.
- El grosor se obtiene desde la geometría real del panel, no desde el área de
  trabajo reservada que desaparece con el autoocultado.
- Si la geometría no está disponible temporalmente, se conserva el tamaño
  configurado.

## Configuración y empaquetado

- El visualizador de audio tiene ahora su propia página de configuración.
- Debian compila en una carpeta de caché fuera de las carpetas compartidas de
  VirtualBox.
- Fedora y Debian conservan baselines de `qmllint` independientes porque sus
  versiones de Qt generan diagnósticos diferentes.
- Se restauró compatibilidad con Qt 6.8 en los diálogos de importación.
- El script de prueba verifica la instalación y confirma que Plasma Shell
  reinició realmente con un proceso nuevo.

## Compatibilidad

- KDE Plasma 6 o posterior está declarado en los metadatos.
- Wayland continúa siendo la sesión principalmente soportada.
- Fedora 44 `x86_64` es el objetivo precompilado principal.
- Debian 13 `x86_64` usa un paquete compilado por separado y validado con Qt
  6.8.2.
- PipeWire sólo es necesario para el visualizador de audio opcional.

Los binarios nativos dependen del entorno de compilación. Instala siempre el
artefacto etiquetado para tu distribución y arquitectura.

## Nota de actualización

Después de actualizar, reinicia Plasma Shell una vez o cierra y vuelve a
iniciar sesión si el dock no se actualiza inmediatamente. La configuración
existente se conserva.

## Registro de cambios

### Versión 0.8.8

- Añadida biblioteca administrada de temas JSON externos.
- Añadida importación recursiva de carpetas y borrado de temas instalados.
- Añadidos renderers plano 2D y repisa 2.5D con separadores temáticos.
- Los temas externos permanecen fuera del `.plasmoid` distribuido.
- Añadido fallback de icono para ventanas portables mediante TaskManager.
- Mejorada la asociación entre lanzadores y ventanas usando identificadores y
  URLs de lanzador.
- Corregida la reducción de iconos en paneles autoocultables.
- Movida la configuración del visualizador a una página independiente.
- Mejorada la compatibilidad Debian Qt 6.8 y la compilación en VirtualBox.
- Añadidas pruebas de validador y repositorio; la suite actual pasa `5/5`.

Licencia: GPL-3.0-or-later.
