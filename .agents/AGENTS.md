# Instrucciones para `.agents/`

La fuente canónica de reglas del proyecto es [`../AGENTS.md`](../AGENTS.md) y también se aplica a este directorio.

## Alcance local

- `.agents/skills/` es la única fuente canónica de skills.
- Cada skill debe limitarse a instrucciones operativas de su dominio y evitar duplicar reglas globales.
- Al cambiar la identidad, el rol o las relaciones de una skill, actualizar sus
  referencias y `.agents/skills-map.yaml`, realizar el cambio estructural,
  regenerar `.agents/skills-inventory.json` con
  `python3 scripts-dev/skill_inventory.py --update` y validar después con
  `python3 scripts-dev/skill_inventory.py --check`.
- El front matter de cada `SKILL.md` debe conservar al menos `name` y `description`, coherentes con el directorio y el disparador real.
