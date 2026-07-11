# Instrucciones para `.agents/`

La fuente canónica de reglas del proyecto es [`../AGENTS.md`](../AGENTS.md) y también se aplica a este directorio.

## Alcance local

- `.agents/skills/` es la única fuente canónica de skills.
- `.agents/skills 2/` es una copia pendiente de retirada y no debe editarse ni consultarse.
- Cada skill debe limitarse a instrucciones operativas de su dominio y evitar duplicar reglas globales.
- No renombrar, fusionar o retirar una skill sin actualizar primero sus referencias y el inventario del plan de acción.
- El front matter de cada `SKILL.md` debe conservar al menos `name` y `description`, coherentes con el directorio y el disparador real.

