---
name: documentation
description: Activa esta skill para operar sobre aspectos relacionados con documentation.
---

# documentation Skill

## Scope
Definición del alcance exacto de esta skill dentro del contexto del plasmoide Punchi Dock Remastered.

## Rules
- Aplicar la compatibilidad, la arquitectura y las demás políticas globales
  definidas en `AGENTS.md`; esta skill solo añade las reglas específicas de su
  dominio.
- Regla 3: En `docs/Post KDE/`, conservar separadas las series de posts públicos
  (`post-kde-store-<version>.md` y `-es.md`) y checklists internos
  (`checklist-publicacion-<version>.md`).
- Regla 4: Usar las plantillas y el README de cada carpeta antes de crear
  documentación nueva; no reescribir documentos históricos para reflejar una
  versión posterior.
- Regla 5: Toda carpeta documental nueva debe incluir un `README.md`; si tiene
  un proceso repetible, debe incluir además una plantilla y describir su fuente
  de verdad.
- Regla 6: Antes de crear o actualizar un post de KDE Store, leer el contrato
  editorial de `AGENTS.md`, `docs/Post KDE/README.md`, la plantilla y el último
  post confirmado como publicado. Conservar su orden de secciones, tabla
  comparativa y changelog temático; cambiar solo el contenido propio de la
  versión salvo autorización explícita del usuario para rediseñar el formato.

## Checklist
- [ ] ¿Los cambios se ajustan al scope de esta skill?
- [ ] ¿Se ha evitado generar deuda técnica en el proceso?
- [ ] ¿La versión, el idioma, el estado de validación y la estructura coinciden
      con el documento compañero y con `CHANGELOG.md`?
- [ ] ¿El post conserva el contrato editorial del último post publicado y evita
      sustituirlo por un esquema genérico `Added / Changed / Fixed`?

## Common Mistakes
- Desviarse del diseño base de KDE.
- Inventar soluciones que ya existen en el SDK oficial.
