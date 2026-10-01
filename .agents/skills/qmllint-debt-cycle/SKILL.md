---
name: qmllint-debt-cycle
description: Conducir el inventario, clasificación y reducción progresiva de advertencias qmllint de Punchi Dock sin aumentar baselines ni perder observaciones. Usar cuando se analicen, corrijan, supriman o cierren diagnósticos QML, se modifique QML con deuda existente, cambie una versión o perfil de qmllint, o se proponga actualizar un baseline.
---

# Ciclo de deuda qmllint

## Fuente de verdad

Leer completamente, en este orden:

1. la política de deuda estática QML de `AGENTS.md`;
2. `docs/deuda-qmllint/README.md`;
3. `docs/deuda-qmllint/recomendaciones.md`;
4. el inventario activo del mismo perfil y versión de Qt.

No tratar un baseline como objetivo de calidad. Es únicamente el máximo
histórico tolerado para un entorno concreto.

---

## Regla obligatoria de trinquete unidireccional (Ratchet Down)

**Reducción inmediata de límites en toda modificación, fix o mejora:**

1. **Ajuste automático al reducir advertencias**:
   - Siempre que durante el desarrollo de una corrección de bug (fix), nueva característica, refactorización o auditoría se repare o elimine una o más advertencias de `qmllint`, es **obligatorio reducir inmediatamente el baseline del perfil correspondiente** (`scripts-dev/qmllint-baseline-fedora.env` o `scripts-dev/qmllint-baseline-debian.env`).
2. **Efecto trinquete**:
   - El límite solo puede descender. Una vez que se logra un nuevo mínimo comprobado y reproducible (ej. bajar de 638 a 633), ese nuevo número pasa a ser de inmediato el nuevo techo máximo infranqueable.
3. **Prohibición de holguras históricas**:
   - No se permite mantener un baseline con un valor superior al conteo real alcanzado tras una sesión de trabajo. Todo avance en limpieza de código debe consolidarse actualizando el archivo `.env` de baseline respectivo para bloquear cualquier regresión futura.

---

## Flujo obligatorio

1. Identificar distribución, ejecutable y versión efectiva de `qmllint`. No
   reutilizar evidencia ni baseline de otro perfil.
2. Revisar `git status` y preservar cambios ajenos.
3. Ejecutar un corte completo sobre `contents/ui/**/*.qml` y guardar el log.
4. Generar o actualizar el cuadro con
   `scripts-dev/qmllint_debt_inventory.py`. Comprobar que el número de filas coincide
   con las líneas `Warning:` y que no contiene rutas absolutas.
5. Elegir un lote acotado de 5–20 firmas relacionadas. Priorizar
   `missing-property`, imports, tipos, ciclos y layout antes que `unqualified`.
6. Registrar las filas y archivos del lote antes de editar. Corregir la causa
   con el cambio más pequeño; no elevar el baseline, excluir archivos ni añadir
   supresiones amplias.
7. Ejecutar lint focalizado. Para cerrar un ID, usar obligatoriamente el comando
   transaccional descrito abajo; no editar manualmente checkbox o baseline.
8. Confirmar en la salida que el ID desapareció, no surgieron firmas nuevas, el
   gate del perfil pasó y el baseline solo disminuyó.
9. Validar carga/runtime cuando se hayan tocado imports KDE, tipos dinámicos,
   `Loader`, delegates, modelos, KConfig o componentes alcanzables desde la
   representación principal.
10. Disminuir el baseline del mismo perfil siempre que la reducción sea
    reproducible y forme parte de la modificación validada.

---

## Comando obligatorio de cierre de lote

Todas las rutas de esta skill son relativas a la raíz del proyecto; ejecutar el
comando desde ella. El ejemplo usa el perfil Fedora; el perfil, el baseline y el
gate deben corresponder al entorno real.

`--qmllint` debe recibir el ejecutable de Qt 6 del entorno real y nunca una ruta
fija de una distribución concreta: respetar `QMLLINT_BIN` si está definido y, en
su defecto, resolverlo con `command -v qmllint` o con el mecanismo que el proyecto
ya usa (el gate de empaquetado lo hace en `resolve_qmllint`, en
`scripts-user/lib/package-plasmoid.sh`).

Después de corregir y revisar el cambio, ejecutar para Fedora:

```bash
scripts-dev/qmllint_debt_cycle.py \
  --id QML-ID-1 \
  --id QML-ID-2 \
  --observation "Confirmed technical cause and resolution" \
  --profile fedora \
  --inventory docs/deuda-qmllint/inventario-YYYY-MM-DD-fedora-qtX.Y.Z.md \
  --baseline scripts-dev/qmllint-baseline-fedora.env \
  --qmllint "$(command -v qmllint)" \
  --gate-script scripts-dev/distro/fedora-package.sh
```

El comando debe:

- ejecutar `qmllint` sobre todo `contents/ui` y reconciliar IDs;
- aceptar uno o varios `--id` relacionados como un único lote verificable;
- rechazar el cierre si algún objetivo continúa activo o aparece cualquier ID nuevo;
- rechazar cualquier aumento de total o categoría del baseline;
- ejecutar el gate de empaquetado con el baseline prospectivo;
- escribir solo después del éxito total;
- respaldar inventario y baseline antes de reemplazarlos;
- mover todos los IDs ausentes al histórico, marcar `[x]`, registrar evidencia y reducir
  el baseline al resultado reproducible.

Usar `qmllint_debt_inventory.py` directamente solo para crear un corte inicial,
migrar un perfil o recuperar un inventario; no para cerrar manualmente IDs en
el flujo normal.

---

## Reglas del inventario

- Mantener una fila por ocurrencia real de `Warning:`. Informar `Info:` en el
  resumen, sin mezclarlo con el contador del gate vigente.
- Preservar checkbox, observación y evidencia de firmas aún presentes al
  regenerar el cuadro.
- No borrar una fila manualmente para reducir el total.
- Crear un corte nuevo cuando cambien distribución o versión de Qt.
- Tratar una firma que cambia de archivo, categoría o mensaje como diagnóstico
  nuevo, aunque el total permanezca igual.
- Mantener una corrección sin validación como `[ ]`.
- Considerar un fallo del comando de cierre como condición de parada. No
  reproducir a mano solo las escrituras finales para eludir una comprobación.

---

## Condiciones de parada

Detener la entrega y comunicar el bloqueo si:

- aparece cualquier firma nueva atribuible al lote;
- el total o una categoría supera su baseline;
- la única forma propuesta de pasar el gate es elevar, regenerar o relajar el
  baseline;
- no puede reproducirse el mismo perfil utilizado como evidencia;
- una corrección dinámica no puede validarse en carga/runtime y existe riesgo
  de dejar vacía o romper la representación.

---

## Entrega

Informar el perfil y versión usados, las filas trabajadas, las firmas retiradas,
las firmas nuevas (debe ser cero), el nuevo baseline disminuido y las
validaciones realmente ejecutadas. No afirmar funcionamiento en Plasma si solo
se ejecutó análisis estático.
