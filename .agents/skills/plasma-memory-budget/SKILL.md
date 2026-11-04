---
name: plasma-memory-budget
description: Presupuestar, medir y reducir el consumo de memoria de Punchi Dock dentro de plasmashell, incluida la atribución por componente, la carga diferida de diálogos y superficies pesadas, el coste marginal por instancia, la retención tras cerrar y el gate de memoria del repositorio. Usar al añadir componentes pesados, al revisar consumo, al investigar crecimiento de plasmashell, al abrir o cerrar overlays y al decidir si una superficie debe instanciarse al cargar o bajo demanda; complementar con `plasma-animation-performance` para coste por fotograma y con `performance` para el diagnóstico global.
---

# Presupuesto de memoria del plasmoide

## Alcance

Un plasmoide no tiene proceso propio: su memoria vive en `plasmashell` y se
mide como diferencia, no como cifra absoluta. Esta skill fija cómo se mide, qué
se considera aceptable y qué decisiones de diseño se derivan de ello.

Queda fuera:

- coste por fotograma, fluidez y respeto a la velocidad de animación →
  `plasma-animation-performance`;
- diagnóstico global de rendimiento → `performance`;
- elección del mecanismo de una animación → `plasma-fluid-motion`.

## Reglas

1. Aplicar las políticas de `AGENTS.md`; esta skill solo añade lo específico de
   memoria.
2. Medir siempre con `scripts-dev/memory-budget.py`, nunca con `top`, `htop` ni
   RSS de `plasmashell`.
3. Reportar `Pss_Anon` (memoria privada anónima), no `Rss`. El `Rss` incluye
   bibliotecas compartidas que no pertenecen al plasmoide.
4. Medir el delta de la **segunda** instancia: la primera arrastra cachés
   compartidas (tema de iconos, tipos QML) que el shell pagaría igualmente.
5. Medir en estado asentado: descartar los primeros 15–20 s tras cargar.
6. No declarar un consumo sin indicar entorno (Qt, Plasma, tema de iconos),
   número de elementos del dock y si la cifra es delta o valor absoluto.
7. Un baseline de memoria solo puede bajar. Elevarlo exige autorización
   explícita y evidencia de cambio de herramienta o de entorno.

## Presupuesto vigente

| Métrica | Presupuesto | Fuente |
|---|---|---|
| `second_instance_mb` | ≤ 97 MB | `scripts-dev/memory-baseline.env` |
| `first_instance_mb` | ≤ 137 MB | `scripts-dev/memory-baseline.env` |
| `retention_mb` tras retirar | ≤ 233 MB | `scripts-dev/memory-baseline.env` |

Los valores del archivo son la referencia operativa; esta tabla solo explica su
sentido.

### Cómo se fija cada cifra

El presupuesto es **el valor más alto observado más 1,0 MB de margen de ruido**,
nunca el valor medido en una sola pasada. Un presupuesto igual al valor observado
falla en la ejecución siguiente sin que nada haya empeorado: el 2026-11-04 un
límite de 95,5 MB se superó con 96,0 MB en la misma versión del árbol.

Reglas:

- si el margen obligaría a **subir** una cifra ya registrada, la cifra se queda
  como estaba: el baseline solo baja;
- dos ejecuciones consecutivas son el mínimo para fijar un valor;
- una mejora real de producto debe superar 3 MB para distinguirse del ruido.

## Protocolo de medición

```bash
python3 scripts-dev/memory-budget.py             # mide e informa
python3 scripts-dev/memory-budget.py --check     # falla si supera el baseline
```

El arnés:

1. lanza `kwin_wayland --virtual` y un `plasmashell` con `DBUS_SESSION_BUS_ADDRESS`,
   `XDG_CONFIG_HOME`, `XDG_CACHE_HOME`, `XDG_DATA_HOME` y `XDG_RUNTIME_DIR`
   propios;
2. copia el paquete del árbol de trabajo a ese entorno aislado;
3. añade y retira instancias del applet mediante
   `org.kde.PlasmaShell.evaluateScript`;
4. muestrea `/proc/<plasmashell>/smaps_rollup`;
5. elimina el entorno temporal en todas las rutas de salida.

Nunca toca la sesión del usuario ni requiere red.

### Atribución por componente

Qt no expone «memoria por archivo QML». Para atribuir MB:

1. medir el coste total por instancia;
2. reducir el componente candidato a una `Loader` inactiva o a un `Item {}` en
   una copia del paquete;
3. volver a medir con el mismo arnés y la misma configuración;
4. atribuir la diferencia al componente y registrar la medición.

La bisección se hace sobre el paquete, no sobre el runtime del usuario.

## Reglas de diseño derivadas

### Carga diferida de superficies

- Un `PlasmaCore.Dialog` crea su `mainItem` al existir el diálogo, no al
  mostrarse. Un diálogo declarado dentro de un `Component` y creado con
  `createObject(...)` al abrir no cuesta memoria en frío: ese es el patrón de
  `contents/ui/main.qml` para los overlays grandes.
- El caso que sí cuesta es un diálogo declarado dentro de un delegado que existe
  por elemento. `DockItem` creaba una ventana de tooltip por elemento del dock;
  cada ventana nativa arrastra su propio contexto gráfico aunque nunca se muestre.
- Por eso: ningún diálogo debe declararse directamente dentro de un delegado. Se
  crea bajo demanda con un `Loader` o `createObject` y se libera al dejar de
  usarse.
- El diálogo puede existir desde el arranque si es barato. Lo que no debe existir
  es una ventana nativa por elemento.
- Si el diálogo se dimensiona a partir de `mainItem`, el marcador de posición
  debe declarar `implicitWidth` e `implicitHeight` equivalentes, o el diálogo
  debe fijar `width`/`height` explícitos.

### Una variante por instancia

- Modos mutuamente excluyentes (Normal/Float, Fullscreen/Normal/Compact) no
  deben instanciarse todos a la vez.
- Si dos superficies del mismo applet muestran el mismo contenido, ese contenido
  se instancia una vez y se comparte por referencia, no por copia.

### Coste por delegado

- El consumo escala con la cantidad de elementos del dock: medido en 2026-11-03,
  ≈ 2,8 MB por elemento con la configuración por defecto.
- Un delegado no debe instanciar ventanas, servicios ni efectos que pertenezcan a
  otro tipo de elemento; cada uno de esos subárboles se multiplica por elemento.
- Un valor por defecto con decenas de elementos se paga en cada instancia y en
  cada sesión: revisar la lista por defecto es una decisión de memoria, no solo
  de producto.

### Contenido, modelos y cachés

- Modelos acotados; para colecciones grandes usar modelos nativos, no arrays JS.
- Limpiar filas y cachés al cerrar una vista transitoria.
- Iconos y miniaturas al tamaño de uso; no ampliar y reducir en el mismo
  componente.
- Evitar un `Timer` por elemento: compartir y agrupar.
- Evitar blur, sombras y shaders por delegado en listas numeradas.

### Retención

- Qt conserva heap tras destruir objetos QML. Una retención moderada es normal y
  no debe reportarse como fuga.
- Para recuperar memoria hace falta reiniciar `plasmashell`; documentarlo en la
  validación, no ocultarlo.

## Antipatrones

- Reportar «el dock usa X MB» leyendo el `Rss` completo de `plasmashell`.
- Comparar una medición local con cifras de foros, wikis o de otra máquina.
- Optimizar sin medir antes y después con el mismo arnés.
- Declarar una mejora de memoria sin `--check` ejecutado sobre el baseline.
- Convertir todos los diálogos en `Loader` de golpe sin medir ni validar
  contratos de prueba.
- Añadir red, `git` remoto o telemetría al arnés de medición.

## Checklist antes de entregar

- [ ] ¿Se midió antes y después con `scripts-dev/memory-budget.py`?
- [ ] ¿El baseline se mantuvo o bajó?
- [ ] ¿Se indica entorno, configuración del dock y tipo de cifra?
- [ ] ¿Los diálogos pesados se instancian solo cuando se abren?
- [ ] ¿Se evitó duplicar superficies equivalentes en la misma instancia?
- [ ] ¿La retención tras cerrar quedó registrada como limitación medida?
- [ ] ¿CTest, `qmllint`, ki18n, preflight e integridad de pruebas se ejecutaron?

## Evidencia

- `docs/Referencias/referencia-memoria-plasma-qt.md` — método, umbrales y citas
  del SDK.
- `scripts-dev/memory-baseline.env` — presupuesto vigente por entorno.
- `docs/nuevas-modificaciones/` — la modificación que introdujo esta doctrina.
