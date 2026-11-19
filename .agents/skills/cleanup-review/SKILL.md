---
name: cleanup-review
description: Revisar y ejecutar limpieza local y remota de ramas, worktrees, contenedores, artefactos de CI y archivos generados, con inventario previo, autorización explícita y verificación posterior. Usar al cerrar sesión, después de fusionar un PR o cuando el usuario pida limpieza.
---

# Revisión de limpieza

La limpieza elimina material. Separar siempre el inventario de la mutación: primero
se enumera y clasifica, después se pide autorización y solo entonces se ejecuta.
Una limpieza amplia no es una limpieza segura.

## Alcance

- **Local:** ramas, referencias remotas obsoletas, worktrees, `build/`, `dist/`,
  logs, temporales, contenedores, imágenes, volúmenes y respaldos de herramientas.
- **Remoto:** ramas de PR, estado de PR abiertos o fusionados, ejecuciones y
  artefactos de GitHub Actions.
- **Fuera de alcance sin solicitud expresa:** `main`, etiquetas, releases,
  commits sin fusionar, evidencia de un PR abierto y el único respaldo disponible.

## Inventario de solo lectura

Ejecutar desde la raíz del repositorio y conservar la salida para comparar:

```bash
git status --short --branch
git branch -vv
git worktree list
git remote -v
git remote prune --dry-run origin
git fetch --prune origin
gh pr list --state open --limit 100
gh pr list --state merged --limit 100
gh run list --limit 20
podman ps -a --format '{{.Names}} {{.Status}} {{.Image}}'
podman images --format '{{.Repository}}:{{.Tag}} {{.ID}}'
```

Para artefactos y archivos generados, medir sin borrar:

```bash
du -sh build dist docs/logs 2>/dev/null
find build dist docs/logs -maxdepth 2 -type f -printf '%p %s bytes\n' 2>/dev/null
```

No usar globs ni variables vacías para decidir qué se elimina. Cada candidato debe
tener una ruta exacta.

## Clasificación

| Elemento | Decisión por defecto |
|---|---|
| `main` y ramas protegidas | Nunca se eliminan. |
| Rama local cuyo PR fue fusionado (merge o squash) | Candidata; verificar `state=MERGED` y la coincidencia del head. |
| Rama con PR abierto | No se toca hasta fusionar o cerrar el PR. |
| Rama con commits sin PR fusionado | Se conserva; solo se elimina con autorización explícita. |
| Worktree limpio y sin trabajo pendiente | Candidato a `git worktree remove`. |
| Worktree con cambios o procesos | Se detiene la limpieza y se informa. |
| Contenedor o imagen creado por la tarea | Candidato a retirada por nombre exacto. |
| Contenedor o imagen preexistente | Se conserva salvo autorización explícita. |
| `build/`, `dist/` y temporales de una validación terminada | Candidatos; no borrar mientras haya una ejecución activa. |
| `docs/logs`, `docs/deuda-qmllint/` y `backup/` | Evidencia o respaldo: se conserva según la política aplicable. |
| Artefactos de CI | Retención de 7 días; el borrado manual requiere autorización. |
| PR abierto, borrador o cerrado sin fusionar | No se cierra ni se borra su rama sin solicitud explícita. |

Las ramas se comparan con `origin/main`, no con una copia local desactualizada.
Actualizar `origin` antes de clasificar. En un squash merge, los commits del head
no son ancestros de `origin/main`: la autoridad es `state=MERGED` del PR y la
coincidencia entre el head revisado y la rama local.

## Puertas de autorización

### Ramas locales

```bash
git branch --merged origin/main
git merge-base --is-ancestor <rama> origin/main
git branch -d <rama>
```

- Usar `-d` cuando la ancestría sea verdadera.
- No borrar una rama que tenga un PR abierto.
- Si `git branch -d` se niega, comprobar si el PR fue fusionado con squash. En ese
  caso, verificar `state=MERGED`, `mergedAt` y que
  `git rev-parse <rama>` coincide con `headRefOid`; solo entonces se puede usar
  `git branch -D <rama>` con autorización explícita. No usar `-D` para ocultar
  una rama sin PR fusionado.
- Ejecutar una rama por operación y comprobar `git branch -vv` después.

### Ramas remotas de PR

Antes de borrar, confirmar que el PR está fusionado y que el head revisado
coincide con la rama local:

```bash
gh pr view <número> --json state,mergedAt,headRefName,headRefOid,baseRefName,mergeCommit
git rev-parse <rama-local>
git ls-remote --heads origin <headRefName>
```

- `mergedAt` debe existir y `state` debe ser `MERGED`.
- En squash merge no se exige que `headRefOid` sea ancestro de `origin/main`.
  Si `mergeCommit` existe, se puede comprobar su ancestría como evidencia
  adicional.
- Para borrar la rama local, `git rev-parse <rama-local>` debe coincidir con
  `headRefOid`; no borrar una rama que apunte a otro commit.
- Si GitHub ya eliminó la rama remota, no hay nada que borrar.
- Si la rama sigue existiendo y el usuario autorizó la limpieza:
  `git push origin --delete <headRefName>`.
- Nunca borrar `main`, una rama con PR abierto o una rama sin PR fusionado.

### PR y ejecuciones de CI

- Cerrar un PR, descartar una ejecución o borrar artefactos requiere solicitud
  explícita; no es una consecuencia automática de fusionar.
- No borrar artefactos de un PR que todavía se está revisando.
- Respetar la retención configurada (7 días en el workflow actual) antes de
  plantear una limpieza manual.

### Worktrees

```bash
git worktree list
git worktree remove <ruta>
git worktree prune
```

- Retirar solo un worktree limpio y sin procesos activos.
- No usar `--force` sin autorización.
- Después de retirarlo, comprobar que `git worktree list` ya no lo muestra.

### Contenedores e imágenes

- Identificar el nombre o ID exacto creado por la tarea.
- Retirar primero el contenedor y después la imagen, si ya no tiene consumidores.
- No usar `podman system prune`, `podman volume prune` ni barridos equivalentes.
- No borrar volúmenes sin confirmar que no contienen datos del usuario.

### Archivos y directorios

Aplicar `safe-removal-review` antes de borrar, mover o sobrescribir. Para material
ignorado o no rastreado, crear un respaldo recuperable y verificar que Git no sea
la única vía de retorno. No usar `git clean -fdx`, `git reset --hard` ni `rm -rf`
sobre rutas amplias.

## Ejecución por lotes

1. Ejecutar una sola categoría por lote: ramas locales, ramas remotas, worktrees,
   contenedores, artefactos o archivos.
2. Verificar después de cada lote:

   ```bash
   git status --short --branch
   git branch -vv
   git worktree list
   gh pr list --state open
   podman ps -a
   ```

3. Si el inventario disminuye de forma no prevista, detener la limpieza y tratar
   el hecho como incidente.
4. No borrar el único respaldo ni la evidencia de una validación todavía
   necesaria.

## Cierre

Informar:

- elementos retirados, con la autorización que los habilitó;
- elementos conservados y su motivo;
- comprobaciones ejecutadas después de cada lote;
- recursos que siguen existiendo y requieren una decisión del usuario;
- cualquier limitación o riesgo pendiente.

## Anti-patrones

- `git clean -fdx`, `git reset --hard` o `git checkout -- .` como limpieza.
- `git branch -D` para ocultar que una rama no tiene un PR fusionado.
- Borrar una rama remota sin comprobar `state=MERGED`, `mergedAt` y la
  coincidencia del head.
- Exigir ancestría del head en un squash merge y concluir por error que la rama
  no está fusionada.
- Borrar una rama con un PR abierto o sin PR fusionado.
- `podman system prune -a` o `podman volume prune`.
- Borrar `build/`, `dist/` o logs mientras una validación sigue activa.
- Borrar el único respaldo, el inventario activo o la evidencia de un PR abierto.
- Usar globs, variables vacías o rutas amplias para seleccionar objetivos.

## Coordinación

`pr-delivery` decide el estado del PR; `git` conserva las reglas de ramas;
`safe-removal-review` gobierna la eliminación de archivos y respaldos;
`session-closure` activa esta revisión al terminar una sesión. La limpieza de
temporales de pruebas pertenece a `testing` y no se sustituye por un barrido
global.
