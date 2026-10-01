---
name: html-document-design
description: "Diseñar, implementar y auditar documentación HTML profesional y autocontenida de Punchi Dock: arquitectura editorial, iconografía SVG, jerarquía visual, navegación, capturas, componentes semánticos, temas claro/oscuro, accesibilidad, adaptación móvil e impresión/PDF. Usar al crear o rediseñar manuales y guías públicas en `Documents/`, añadir iconos o secciones, integrar evidencia visual o revisar que un HTML resulte coherente y publicable; no usar para interfaces QML del plasmoide."
---

# Diseño editorial HTML

## Objetivo

Convertir Markdown canónico y evidencia visual validada en un documento HTML
profesional, legible sin red, accesible y preparado para pantalla e impresión.
Mantener el contenido por encima de la decoración.

## Recursos obligatorios

- Leer
  `.agents/skills/html-document-design/references/editorial-system.md` antes de
  definir o cambiar el sistema visual, iconografía, componentes o estilos de
  impresión.
- Usar `.agents/skills/html-document-design/assets/editorial-icons.svg` como base
  de iconos semánticos. Copiar solo los símbolos necesarios al documento o a su
  carpeta pública; no referenciar archivos dentro de `.agents/` desde el manual
  publicado.
- Ejecutar
  `python3 .agents/skills/html-document-design/scripts/audit_html.py <documento.html>`
  después de cada lote.

## Flujo

1. Leer `AGENTS.md`, `Documents/README.md`, la plantilla pública, el Markdown
   canónico, el HTML derivado y el inventario de capturas aplicable.
2. Inventariar archivos, estado Git y privacidad. Respaldar documentos
   ignorados o no rastreados antes de sobrescribirlos.
3. Definir la tarea principal, audiencia, estado editorial, versión, idioma y
   secciones. Corregir primero arquitectura y jerarquía; después decoración.
4. Establecer tokens CSS para color, tipografía, espaciado, radios, sombras y
   ancho de lectura. Proporcionar tema claro, oscuro y estilos de impresión.
5. Componer con elementos semánticos: portada, índice, secciones, pasos,
   figuras, tarjetas, llamadas de atención, estado de validación y pie.
6. Añadir iconos únicamente cuando mejoren reconocimiento, navegación o estado.
   Mantener etiqueta textual o nombre accesible equivalente.
7. Integrar capturas revisadas con dimensiones, texto alternativo, leyenda y
   explicación suficiente para no depender de flechas o color.
8. Actualizar Markdown y HTML en el mismo lote. El Markdown conserva autoridad
   editorial; el HTML es una edición de lectura derivada.
9. Validar estructura, recursos, privacidad, tema oscuro, ancho reducido e
   impresión. Distinguir inspección estática de prueba visual real.

## Reglas de iconografía

- Preferir SVG local con `viewBox="0 0 24 24"`, `currentColor`, trazos
  redondeados y geometría simple coherente con Breeze.
- Usar 16 px junto a texto compacto, 20 px en controles y 24 px en títulos o
  llamadas de atención. No escalar un icono por encima del texto sin función.
- Reservar rojo para bloqueo, peligro, pérdida o seguridad; ámbar para
  precaución; azul para información; verde para confirmación.
- No usar emoji, fotografías, logos de terceros ni iconos remotos como sistema
  editorial principal.
- No depender solo del icono o color. Acompañar estados críticos con palabras
  como **Información**, **Precaución**, **Bloqueado** o **Validado**.
- Mantener un significado estable: no reutilizar el mismo símbolo para acciones
  o estados diferentes dentro del documento.

## Reglas de composición

- Mantener una sola superficie principal y un ancho de lectura cómodo.
- Usar tarjetas para comparar opciones o tareas paralelas, no para envolver
  cada párrafo.
- Limitar el índice a destinos útiles y mantener identificadores estables.
- Usar una escala tipográfica breve y consistente; evitar texto diminuto y
  líneas excesivamente largas.
- Separar bloques mediante espacio antes que mediante múltiples bordes.
- Evitar JavaScript salvo necesidad funcional demostrada. No cargar fuentes,
  CSS, iconos ni scripts desde red.
- Mantener CSS y SVG comprensibles; no minificar el documento fuente.

## Accesibilidad y adaptación

- Declarar `lang`, título, descripción, viewport y esquema de color.
- Añadir enlace para saltar al contenido, jerarquía de encabezados lógica,
  foco visible y landmarks semánticos.
- Proporcionar `alt` útil en cada imagen informativa y `alt=""` en decoración.
- Ocultar iconos decorativos a tecnologías de asistencia con
  `aria-hidden="true"`.
- Verificar contraste en claro y oscuro y que ningún estado dependa solo del
  color.
- En móvil, reducir columnas y conservar tamaño de texto y objetivos. En
  impresión, evitar cortes dentro de figuras, pasos y advertencias.

## Decisiones editoriales

- Integrar una captura cuando demuestre una decisión, un resultado o un estado
  difícil de explicar solo con texto.
- Conservar como evidencia, sin publicar, capturas redundantes, privadas,
  ambiguas o con legibilidad insuficiente.
- Usar una advertencia roja solo cuando la acción esté bloqueada o exista un
  riesgo material; una recomendación ordinaria no es peligro.
- Conservar la versión como borrador mientras exista un procedimiento o estado
  relevante pendiente de validación real.

## Validación mínima

1. Ejecutar
   `python3 .agents/skills/html-document-design/scripts/audit_html.py <documento.html>`
   y corregir todos los errores.
2. Comprobar manualmente tema claro y oscuro, ancho de 320 px y escritorio.
3. Revisar vista previa de impresión A4 y saltos de página.
4. Confirmar que enlaces, imágenes y SVG son locales y existen.
5. Revisar capturas y texto por rutas personales, hostnames, notificaciones,
   correos, credenciales y metadatos privados.
6. Comparar inventario antes/después y ejecutar `git diff --check` donde
   aplique.

## Criterios de aceptación

- La jerarquía permite orientarse sin leer todo el documento.
- La iconografía es consistente, local, semántica y accesible.
- El documento funciona sin red ni JavaScript.
- El contenido coincide con el Markdown canónico y su estado de validación.
- Claro, oscuro, móvil e impresión conservan legibilidad.
- El auditor no informa errores y los límites de la revisión visual quedan
  declarados.
