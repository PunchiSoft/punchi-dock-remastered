---
name: localization
description: Activa esta skill para tareas relacionadas con: Traducción e internacionalización (i18n) de los textos del plasmoide usando ki18n.
---

# Localization Skill

## Instrucciones Detalladas
Esta skill se centra exclusivamente en: Traducción e internacionalización (i18n) de los textos del plasmoide usando ki18n.
1. Mantén el enfoque únicamente en resolver problemas relacionados con localization.
2. Consulta la documentación oficial relevante (KDE/Qt/Plasma) cuando sea necesario.
3. No combines responsabilidades: si necesitas cambiar algo fuera del ámbito de localization, delega o activa la skill correspondiente.

## Checklist
- [ ] ¿Los cambios se limitan estrictamente al ámbito de localization?
- [ ] ¿Se ha mantenido la coherencia con el resto de la arquitectura del proyecto?
- [ ] ¿El código introducido respeta las guías de estilo globales?

## Buenas Prácticas
- Priorizar la modularidad y el bajo acoplamiento.
- Documentar las decisiones importantes que afecten a localization.
- Mantener las implementaciones simples y legibles.

## Errores Comunes
- **Combinar responsabilidades**: Intentar resolver múltiples problemas no relacionados en la misma iteración.
- **Ignorar el contexto de Plasma 6**: Usar enfoques deprecados de Plasma 5 o genéricos que no aplican a este ecosistema.

## Criterios de Aceptación
- La tarea se ha completado según las especificaciones de localization.
- No se han introducido regresiones en otras áreas del plasmoide.
