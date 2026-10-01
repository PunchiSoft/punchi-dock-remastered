# Matriz de pruebas de Punchi Dock

Leer esta referencia al diseñar una suite nueva, clasificar cobertura,
automatizar CI o preparar una release. No es una lista que deba ejecutarse
completa después de cada edición: seleccionar por riesgo y conservar los gates
globales de `AGENTS.md`.

## Frecuencia

### Por cambio

Debe ser rápida, determinista y apta para repetirse localmente:

- prueba directa del contrato modificado;
- unidades y contratos cercanos;
- QML runtime afectado con warnings convertidos en fallo;
- CTest completo y baseline `qmllint` del mismo perfil;
- catálogos y preflight exigidos globalmente;
- inventario del paquete cuando cambien rutas, metadata o recursos.

### Programada

Ejecutar diariamente o en una automatización dedicada cuando exista:

- ciclos repetidos de creación, mutación y destrucción;
- modelos grandes y carreras con ventanas, popups o servicios;
- fakes DBus/MPRIS y proveedores que aparecen o desaparecen;
- carga integral del applet en más de un perfil compatible;
- mediciones de memoria, CPU, bindings y duración de frames;
- build y paquete en contenedores de distribuciones secundarias.

Una prueba programada debe conservar artefactos diagnósticos cuando falla:
semilla, journal delimitado, versión efectiva, salida de CTest y paquete exacto.

### Pre-release

Validar el mismo `.plasmoid` que se pretende distribuir:

- build universal en el entorno oficial definido por `AGENTS.md`;
- instalación limpia y actualización desde la versión pública anterior;
- preservación de configuración, lanzadores, carpetas y preferencias;
- Plasma Wayland real en la distribución principal;
- smoke secundario en X11 cuando esté disponible;
- distribuciones y versiones que se anunciarán como compatibles;
- temas claro, oscuro y alto contraste; escalas y orientaciones soportadas;
- revisión visual, teclado, accesibilidad, rendimiento y journal;
- inventario, hashes, ELF, SONAME, exclusiones y ausencia de datos locales.

No declarar compatibilidad por haber recompilado fuentes distintas en cada
destino. Para validar portabilidad binaria debe probarse el mismo artefacto.

## Qué demuestra cada entorno

| Entorno | Evidencia válida | No demuestra por sí solo |
|---|---|---|
| Qt offscreen | lógica QML, señales, modelos, ciclo de vida de componentes | KWin, panel, compositor, foco global o integración visual |
| Podman/Docker | build reproducible, dependencias, CTest, lint, traducciones, paquete | una sesión Plasma completa aunque el host use Plasma |
| Plasma anidado | shell, KWin/Wayland, DBus y automatización aislada si realmente se levantan | GPU y comportamiento idénticos al equipo final |
| Máquina virtual | sistema Plasma completo, actualización, compatibilidad y aislamiento | rendimiento o drivers físicos representativos |
| Equipo físico | validación final de GPU, pantallas, escalado, rendimiento y uso real | reproducibilidad automática en otras distribuciones |

Un contenedor que solo exporta `DISPLAY`, Wayland o el bus del anfitrión no se
clasifica automáticamente como prueba aislada de Plasma. Documentar qué
procesos, compositor, shell y bus pertenecen realmente al entorno probado.

En Fedora se puede preferir Podman por integración local; Docker es equivalente
para esta clasificación. La elección no cambia el límite de la evidencia.

## Dominios obligatorios según el cambio

### Carga integral del plasmoide

Cubrir cuando el cambio alcance `main.qml`, imports, representaciones, módulos,
configuración inicial, modelos globales o contenido perezoso:

- descubrir y cargar el paquete por su identificador;
- comprobar applet, item raíz y error de lanzamiento vacío;
- instanciar compact y full representation;
- abrir loaders, popups y diálogos diferidos relevantes;
- cambiar modo, orientación y estado que reconstruyan el árbol;
- destruir, vaciar la cola de eventos y volver a crear;
- fallar ante warnings, excepciones o representación vacía.

Referencia upstream local: `kde-sdk/frameworks/plasma-framework/autotests/applet/applettest.cpp` usa `Plasma::PluginLoader`, comprueba `launchErrorMessage()` y obtiene `PlasmaQuick::AppletQuickItem`. `plasmoidpackagetest.cpp` valida estructura y contenido KPackage. Esos patrones no sustituyen la comprobación de compatibilidad con el mínimo declarado.

### QML y popups

- creación, apertura, cierre, reapertura rápida y destrucción durante animación;
- `Loader.active`, delegates, modelos vacíos/reemplazados y callbacks diferidos;
- Escape, clic exterior, bloqueo modal, restauración del foco y orden Z;
- popup abierto y cerrado durante la misma mutación;
- warnings bloqueantes y ausencia de timers o conexiones supervivientes.

Referencias upstream locales: `kde-sdk/frameworks/plasma-framework/autotests/dialogqmltest.cpp` y `kde-sdk/frameworks/kirigami/autotests/tst_overlayzstacking.qml`.

### Configuración KConfig/KCM

- defaults y tipos de `main.xml`;
- correspondencia de páginas, fuentes y propiedades `cfg_*`;
- Aplicar, Cancelar, restaurar defaults y cerrar con cambios pendientes;
- hot refresh sin reiniciar `plasmashell`;
- límites, entradas inválidas y valores ausentes;
- persistencia después de destruir y recrear el applet;
- migración desde la versión anterior cuando cambie nombre, tipo, default o
  semántica de una clave;
- apertura real de todas las páginas sin errores QML.

Referencia upstream local: `kde-sdk/frameworks/plasma-framework/autotests/applet/applettest.cpp`, método `testConfig()`.

### TaskManager y ventanas

- lanzadores anclados, inválidos, agrupados, separados y reordenados;
- una y varias ventanas por aplicación;
- ventana que aparece o desaparece con preview, DnD o menú abierto;
- cambio de escritorio, actividad y estado de ventana si el código los usa;
- paridad de la ruta soportada en Wayland y smoke secundario en X11.

Usar ventanas controladas y esperar señales del modelo. Referencia upstream
local: `kde-sdk/plasma-workspace/libtaskmanager/autotests/tasksmodeltest.cpp`.

### DBus y MPRIS

- proveedor que aparece, desaparece, reinicia o cambia propietario del bus;
- cero, uno y varios reproductores;
- metadata vacía, malformada, excesiva y artwork ausente o inválido;
- capacidades que cambian durante una interacción;
- error, timeout, cancelación y cleanup del proceso falso.

Usar un bus o servicio controlado, nunca una cuenta o reproductor personal como
único fixture. Referencia upstream local: `kde-sdk/plasma-workspace/libkmpris/autotests/mprisdeclarativetest.py`.

### Teclado y accesibilidad

- Tab y Mayús+Tab completos, flechas 2D, Enter, Espacio y Escape;
- foco visible, foco inicial y restauración después de cerrar superficies;
- nombres, descripciones, roles y estados accesibles no vacíos;
- scroll que mantiene visible el elemento enfocado;
- tema de alto contraste, escalado de texto y movimiento reducido;
- alternativa de teclado para acciones que normalmente dependen de DnD.

Activar también la skill `accessibility`. Referencia upstream local:
`kde-sdk/frameworks/kirigami/autotests/tst_keynavigation.qml`.

### Pantallas, geometría y tema

- panel horizontal y vertical en los cuatro bordes;
- tamaños mínimos, normales y extremos del panel;
- escalas 100 %, 125 %, 150 % y 200 % cuando el entorno las soporte;
- monitor añadido, retirado, reordenado y cambio de pantalla principal;
- resolución o escala que cambia con popup abierto;
- temas claro, oscuro y alto contraste sin fijar colores ni métricas observadas.

Referencia upstream local: `kde-sdk/plasma-workspace/shell/autotests/screenpooltest.cpp` muestra un compositor Wayland falso para carreras de pantallas.

### Empaquetado y actualización

- paquete válido y entrada QML existente;
- lista permitida y exclusiones, sin symlinks prohibidos ni rutas personales;
- instalación limpia, actualización y fallo controlado de un paquete inválido;
- preservación de configuración durante actualización;
- artefacto idéntico identificado por hash en todos los destinos;
- desinstalación probada solo cuando la tarea la autorice y sin borrar datos de
  usuario de manera implícita.

### Entradas no confiables y recursos

- JSON, URLs, rutas, metadata, nombres y argumentos malformados;
- traversal, symlinks, esquemas KIO inesperados y metacaracteres de shell;
- límites de tamaño, cantidad, profundidad y frecuencia;
- fallo seguro sin red, ejecución de comandos o escrituras fuera del alcance.

Activar `security` cuando se auditen superficies de ataque y
`preflight-security-review` antes de modificar o publicar.

### Rendimiento y estabilidad

- idle sin timers o bindings continuamente activos;
- apertura/cierre y mutaciones repetidas con una secuencia reproducible;
- modelos grandes representativos y ráfagas de eventos;
- memoria que vuelve a un rango acordado después de destruir componentes;
- presupuesto de regresión basado en una línea base del mismo entorno.

No usar un umbral absoluto inventado ni convertir una sola medición ruidosa en
un gate. Registrar hardware, sesión, escala, versión y carga del sistema.

## Criterio de evidencia

Por cada resultado registrar:

1. contrato comprobado;
2. archivo o test que lo observa;
3. entorno y versiones efectivas;
4. transición ejecutada, no solo estado final;
5. resultado y artefacto diagnóstico;
6. limitación o prueba pendiente.

Una captura demuestra apariencia en un instante; no prueba foco, accesibilidad,
ciclo de vida, ausencia de warnings ni estabilidad. Una prueba offscreen
demuestra lógica ejecutada; no prueba integración con el shell. Mantener esas
afirmaciones separadas.
