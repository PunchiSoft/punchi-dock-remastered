---
name: plasma-config-review
description: Auditar el contrato de configuracion KConfig/KCM de Punchi Dock, sus paginas Config*.qml y los errores de runtime del dialogo de configuracion. Usar al cambiar contents/config/main.xml, contents/config/config.qml, propiedades cfg_*, paginas de preferencias, Aplicar/Cancelar, actualizacion reactiva, o ante warnings de propiedades iniciales, anchors, tipos, bindings y carga del KCM; no sustituye la revision de la representacion principal del plasmoide.
---

# Revision profesional de configuracion Plasma

## Objetivo

Evitar que una pagina de configuracion aparentemente funcional acumule errores
QML, pierda valores o dependa de comportamientos particulares de una version de
Plasma. Tratar el esquema, las paginas y el journal como un solo contrato.

## Entradas obligatorias

1. Leer `AGENTS.md` y las instrucciones aplicables.
2. Inspeccionar `contents/config/main.xml`, `contents/config/config.qml` y las
   paginas `contents/ui/config/Config*.qml` involucradas.
3. Consultar el dialogo oficial instalado en
   `/usr/share/plasma/shells/org.kde.plasma.desktop/contents/configuration/AppletConfiguration.qml`
   cuando exista; usar `kde-sdk/` como referencia portable.
4. Capturar el journal desde inmediatamente antes de abrir la configuracion.
5. Inventariar pruebas existentes de esquema, defaults, persistencia y hot
   refresh antes de decidir cobertura nueva.

## Flujo obligatorio

### 1. Auditar el contrato estatico

Comprobar primero si existe un auditor mantenido:

```bash
test -f scripts-dev/audit-plasma-config.py
```

Si existe, ejecutar
`python3 scripts-dev/audit-plasma-config.py --project-root .`.
Si no existe, no inventar el resultado ni bloquear toda la revision: registrar
la brecha de automatizacion y construir el inventario desde `main.xml`,
`config.qml`, paginas y consumidores `cfg_*` con busquedas dirigidas. Una tarea
posterior puede implementar el auditor con pruebas propias.

Cuando exista el auditor mantenido:

- leer `scripts-dev/README.md` antes de cambiar su contrato o sus excepciones;
- exigir `Result: PASS`, cero errores y el recuento esperado de esquema, paginas,
  superficies KCM y consumidores;
- usar `--format json` solo cuando otra herramienta necesite consumir el
  resultado y `--verbose` para revisar propietarios;
- tratar un codigo de salida distinto de cero como fallo del contrato, no como
  baseline que pueda elevarse;
- modificar `RUNTIME_ONLY_KEYS` o `EXPECTED_MULTI_PAGE_OWNERS` unicamente tras
  confirmar la arquitectura deliberada y añadir una regresion aislada;
- no presentar el resultado estatico como prueba de Aplicar, Cancelar,
  persistencia, hot refresh o efecto visual.

Comprobar:

- entradas, tipos y grupos de `main.xml`;
- categorias y fuentes declaradas en `config.qml`;
- propiedades `cfg_*` declaradas por cada pagina;
- claves sin propietario visible, propietarios multiples y declaraciones sin
  entrada de esquema;
- fuentes ausentes o rutas que escapen de `contents/ui/`.

Una clave sin pagina puede ser intencional si solo pertenece al runtime. No
corregirla automaticamente; clasificarla y buscar sus consumidores.

### 2. Probar defaults y persistencia automaticamente

Cuando cambie una clave, pagina o binding de configuracion, añadir o actualizar
una prueba que cubra lo aplicable:

1. nombre, grupo, tipo y default definidos en `main.xml`;
2. valor efectivo expuesto al applet y propiedad `Default` cuando Plasma la
   publique;
3. escritura y lectura despues de destruir y recrear la instancia;
4. limites, valor ausente, tipo inesperado y fallback seguro;
5. migracion desde la version anterior cuando cambie nombre, tipo, default o
   semantica de una clave.

Usar almacenamiento aislado y nunca la configuracion personal. El patron de
cargar un applet y comprobar su mapa de configuracion esta documentado en
`kde-sdk/frameworks/plasma-framework/autotests/applet/applettest.cpp`, metodo
`testConfig()`. Confirmar compatibilidad con el minimo declarado antes de copiar
una API del snapshot local.

### 3. Probar la maquina de estados del KCM

Separar las transiciones y comprobar estado editable, persistido y observado
por el runtime:

- **Aplicar:** persiste exactamente los cambios y actualiza el plasmoide sin
  reiniciar `plasmashell`;
- **Cancelar:** descarta cambios pendientes y no deja estado parcial en
  controladores, modelos ni previews;
- **Restaurar defaults:** muestra defaults coherentes y solo los persiste al
  aplicar segun el contrato del shell;
- **Cerrar con cambios pendientes:** sigue la decision del dialogo y no guarda
  silenciosamente;
- **Reabrir o recrear:** presenta el ultimo estado persistido, sin depender de
  objetos sobrevivientes.

La prueba automatizada debe cubrir la logica que pueda aislarse. Aplicar,
Cancelar, foco y navegacion entre paginas deben comprobarse tambien en el KCM
real cuando dependan del shell.

### 4. Auditar la carga real

Abrir cada categoria al menos una vez y recorrer contenido perezoso. Si el
auditor mantenido existe, analizar el registro con:

```bash
python3 scripts-dev/audit-plasma-config.py \
  --project-root . \
  --journal /ruta/al/registro.log
```

En su ausencia, filtrar el journal por el PID nuevo de `plasmashell`, la marca
temporal y rutas del KCM/Punchi. No declarar que se ejecuto el auditor ausente.

Clasificar el primer mensaje de cada familia, no cada repeticion:

- **critico**: modulo o tipo ausente, `Error loading QML`, componente no
  disponible o caida de `plasmashell`;
- **error del proyecto**: binding loop, tipo incompatible, anchors
  contradictorios, objeto no colocado o excepcion JavaScript;
- **candidato upstream por `PageRow`**: un objeto no colocado cuya ruta
  corresponda exactamente a una pagina superior declarada por `config.qml`,
  cuando el `PageRow` instalado la cree primero con su gestor no visual y la
  inserte inmediatamente despues en la vista; no generalizar esta excepcion a
  componentes anidados de Punchi;
- **candidato upstream**: propiedades iniciales `cfg_*` que el shell entrega a
  paginas que no las declaran;
- **candidato externo**: excepciones o fallos de carga emitidos por componentes
  del sistema sin una ruta de Punchi; conservar la ruta y version del paquete
  que los emitio antes de atribuirlos al proyecto;
- **ajeno**: mensajes de audio, red u otras aplicaciones sin relacion con la
  configuracion examinada.

### 5. Usar un control oficial para `cfg_*`

Antes de declarar propiedades ficticias en masa, repetir la captura abriendo un
plasmoide oficial con varias paginas, por ejemplo el reloj digital.

- Si el plasmoide oficial reproduce la firma, registrar la version de Plasma y
  mantenerla como candidato upstream.
- Si no la reproduce, rastrear la diferencia de arquitectura antes de cambiar
  Punchi Dock.
- No silenciar el journal ni elevar un baseline para ocultar errores propios.

### 6. Corregir por causa

- Forzar expresiones destinadas a `bool` a devolver siempre un booleano.
- Usar un solo sistema de geometria por objeto: anchors o layout, sin
  restricciones contradictorias.
- Evitar que `implicitWidth` dependa de padding o contenido calculado desde el
  mismo `width`.
- Mantener una sola fuente de verdad por valor editable.
- No duplicar cientos de propiedades `cfg_*` sin comprobar como las guarda el
  shell y si podrian sobrescribir valores no editados.
- Preservar la actualizacion reactiva al aplicar cambios.

### 7. Validar el ciclo completo

1. Ejecutar `qmllint` sobre archivos modificados y consumidores directos.
2. Ejecutar el auditor estatico y `git diff --check`. Confirmar tambien los gates
   CTest `plasma_config_auditor_test` y `plasma_config_audit` cuando cambien el
   esquema, las paginas, los consumidores o la propia herramienta.
3. Abrir todas las categorias en Plasma real.
4. Probar Aplicar, Cancelar, restaurar valores y cerrar con cambios pendientes.
5. Confirmar que cada cambio llega al plasmoide sin reiniciar `plasmashell`.
6. Capturar un journal nuevo y compararlo con el registro anterior.
7. Registrar la revision en `docs/revisiones/` y las decisiones durables en
   `bitacora/` cuando corresponda.

Al ampliar la cobertura o preparar una release, leer la
[matriz compartida de pruebas](../testing/references/test-matrix.md).

## Criterios de cierre

Cerrar solo cuando:

- el esquema y todas las fuentes se pueden auditar;
- no aparecen errores QML nuevos atribuibles al proyecto;
- cada pagina fue instanciada realmente;
- Aplicar y Cancelar conservan los valores correctos;
- defaults, persistencia y cualquier migracion del alcance tienen una prueba
  aislada o una limitacion documentada;
- la actualizacion en caliente funciona;
- los candidatos upstream estan separados y respaldados por una prueba de
  control, no asumidos.
