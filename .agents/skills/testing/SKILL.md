---
name: testing
description: "Diseñar, implementar o revisar pruebas de Punchi Dock por riesgo y nivel de evidencia: contratos, unidades, QML runtime, applet completo, integraciones KDE, estrés y matrices de compatibilidad. Usar al corregir una regresión, ampliar cobertura, definir gates o decidir entre pruebas offscreen, contenedores, Plasma anidado, máquinas virtuales y equipo físico; no usar para afirmar validación visual sin ejecutar Plasma."
---

# Estrategia de pruebas

## Objetivo

Obtener confianza proporcional al riesgo sin confundir análisis estático,
ejecución aislada y comportamiento real dentro de Plasma. El número total de
tests no es una métrica de cierre: importa qué contrato observable protegen y
en qué entorno se ejecutaron.

## Inicio obligatorio

1. Leer `AGENTS.md`, las instrucciones aplicables, `tests/CMakeLists.txt` y las
   pruebas cercanas al dominio modificado.
2. Inventariar qué evidencia ya existe y qué fallo seguiría escapando aunque
   todas esas pruebas pasaran.
3. Definir el contrato en términos de entrada, transición y resultado
   observable antes de elegir herramienta.
4. Elegir el nivel más bajo que reproduzca la causa, y añadir una prueba de
   integración cuando el riesgo dependa del grafo completo o de KDE.
5. Para una regresión, demostrar que la prueba distingue el comportamiento
   defectuoso del corregido cuando sea viable y seguro.

## Capas de evidencia

- **Estática y contrato:** estructura, imports, referencias, inventario del
  paquete y reglas que no necesitan ejecutar QML. No sustituye runtime.
- **Unidad:** lógica C++ o JavaScript aislada, límites, errores y datos vacíos.
- **QML runtime de componente:** creación, interacción, mutación, destrucción y
  recreación con la cola de eventos activa.
- **Integración del applet:** paquete real cargado como plasmoide, árbol de
  `main.qml`, representaciones, configuración e integraciones controladas.
- **Sistema Plasma:** KWin, Wayland/X11, DBus, panel, pantallas, tema, foco y
  journal de una sesión real o anidada.
- **Compatibilidad y release:** mismo artefacto probado en los entornos que se
  declararán compatibles.

Una prueba estática puede respaldar una invariante textual o estructural, pero
no debe ser la única evidencia de una propiedad de ciclo de vida, foco,
geometría, renderizado, DBus o integración con Plasma.

## Diseño de pruebas

- Afirmar estado inicial, transición crítica, estado posterior y, cuando
  aplique, destrucción y recreación; no comprobar solamente el resultado final.
- Preferir señales, `SignalSpy`, `tryVerify` y condiciones observables sobre
  pausas fijas. Toda espera debe tener timeout y diagnóstico útil.
- Usar fakes deterministas para DBus/MPRIS, modelos de tareas, archivos y datos
  externos. No depender de aplicaciones personales instaladas ni de red.
- Aislar configuración y archivos con temporales o modo de prueba. Limpiar
  procesos, conexiones, ventanas y recursos aun cuando falle una aserción.
- Incluir valores vacíos, límites, entradas inválidas, cancelación, error y
  desaparición del proveedor además del camino exitoso.
- Sembrar y registrar cualquier aleatoriedad. Un fallo de estrés debe poder
  repetirse con la misma semilla y secuencia.
- En Qt Quick Test usar `failOnWarning(/.?/)`; CTest debe fallar también ante
  `QWARN`, `TypeError` y `ReferenceError`. Ignorar solo una firma ambiental
  exacta, comprobada y explicada.
- No elevar baselines, relajar gates ni sustituir una prueba rota por una
  expresión que solo compruebe texto generado.

## Preflight y limpieza del entorno

- Recompilar antes de CTest cuando hayan cambiado fuentes, runners o la
  configuración de pruebas.
- Antes de una suite QML/D-Bus confinada, ejecutar un probe breve de D-Bus y un
  smoke test representativo. Si aparece una restricción ambiental repetible,
  detener la suite confinada y ejecutar el mismo contrato en el host con la
  autorización correspondiente.
- Asignar a cada test un temporal único. El propietario debe conocer la ruta
  exacta; quedan prohibidos los barridos globales de `/tmp` y los globs para
  decidir qué borrar.
- Cuando el runtime pueda escribir cachés durante destructores globales, hacer
  que un wrapper padre cree el temporal, espere la salida completa del proceso
  y lo limpie después.
- Aplicar la limpieza en éxito, fallo, señal y timeout. Incluir procesos hijos,
  buses, sockets, locks, caches, configuraciones y artefactos intermedios.
- Si hace falta evidencia adicional, extraer primero solo el diagnóstico
  aprobado y limpiar después el entorno original. La retención indefinida no
  es un modo de depuración aceptable.
- Añadir una regresión de limpieza cuando se corrija un residuo confirmado y
  tratar el fallo de cleanup como fallo de prueba.

## Selección por riesgo

- Cambio de lógica pura: unidad más límites y regresión directa.
- Cambio QML visual o de estado: componente runtime más contrato de foco,
  accesibilidad o geometría según corresponda.
- Cambio alcanzable desde `main.qml`, `Loader`, modelos o popups: ciclo de vida
  y carga integral del applet mediante `qml-runtime-load-review`.
- Cambio KConfig/KCM: ejecutar
  `scripts-dev/audit-plasma-config.py --project-root .`
  y los gates `plasma_config_auditor_test` y `plasma_config_audit`; despues
  comprobar defaults, Aplicar/Cancelar, hot refresh, persistencia y migración
  mediante `plasma-config-review`. El auditor solo acredita conectividad
  estatica.
- Cambio de TaskManager, DBus/MPRIS, KIO, pantallas o ventanas: integración con
  proveedor controlado y una comprobación en Plasma.
- Cambio de paquete o compatibilidad: inventario, instalación/actualización y
  prueba del mismo artefacto mediante `plasmoid-packaging`.

## Matriz compartida

Al planificar pruebas nuevas, CI, contenedores, una sesión Plasma anidada o una
release, leer [la matriz de pruebas](references/test-matrix.md). Usarla para
seleccionar dominios y frecuencias; no ejecutar toda la matriz de release para
un cambio documental sin riesgo de runtime.

## Integridad de las pruebas

La política canónica vive en `AGENTS.md`, sección «Integridad de las pruebas».
Aquí solo el procedimiento.

### Diagnóstico

1. Ante una prueba que falla, investigar primero el código de producción. No
   asumir que la prueba está equivocada.
2. Ejecutar `python3 scripts-dev/test-integrity-guard.py --check` para saber si
   el cambio en curso afecta a material protegido.
3. Usar `--report` para listar las señales de desactivación y su estado
   documentado o nuevo.

### Parada y reporte

Si la conclusión es que debe cambiar una prueba existente, detenerse antes de
tocarla y reportar: nombre y ruta del test; fallo observado; contrato que
verifica; causa estimada; por qué debe cambiar la prueba y no el código; y la
modificación concreta propuesta. Esperar autorización explícita.

### Autorización y actualización

1. Solo tras la autorización, modificar la prueba.
2. Registrar el cambio con `--update --authorized "<motivo>"` y conservar el
   recibo impreso junto al diff del manifiesto.
3. Añadir pruebas nuevas no requiere autorización; incorporarlas con `--update`.
4. Si incorporarlas exige modificar `tests/CMakeLists.txt` u otra infraestructura
   protegida, reportarlo antes.
5. Ejecutar `--self-test` tras modificar el propio mecanismo.

## Criterios de cierre

- existe al menos una prueba que observa directamente el contrato modificado;
- las rutas de error y transiciones de ciclo de vida proporcionales al riesgo
  están cubiertas;
- cada resultado indica qué entorno lo produjo y qué no demuestra;
- las pruebas son deterministas, aisladas y dejan el entorno limpio;
- se ejecutaron los gates globales exigidos por `AGENTS.md` sin modificar sus
  límites para obtener un resultado favorable;
- el gate de integridad de pruebas pasa sin cambios no autorizados en `tests/`,
  en los manifiestos de nombres ni en los suelos por perfil;
- cualquier validación pendiente en Plasma real queda declarada, no inferida.
