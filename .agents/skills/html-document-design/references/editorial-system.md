# Sistema editorial HTML de Punchi Dock

## Índice

1. Arquitectura del documento
2. Tokens y color semántico
3. Tipografía, espacio y geometría
4. Iconografía
5. Componentes
6. Capturas y figuras
7. Adaptación e impresión
8. Lista de revisión visual

## 1. Arquitectura del documento

Orden recomendado:

1. enlace para saltar al contenido;
2. `article` como superficie principal;
3. `header` de portada con título, resumen y metadata;
4. `nav` con índice interno;
5. `main` con secciones orientadas a tareas;
6. estado de validación y privacidad;
7. `footer` con versión y fuente editorial.

Evitar más de dos niveles visibles en el índice. Dividir un capítulo cuando
combine objetivos independientes, no solo porque sea largo.

## 2. Tokens y color semántico

Definir todos los colores mediante propiedades CSS. Base sugerida:

```css
:root {
  color-scheme: light dark;
  --page: #f4f7fa;
  --surface: #ffffff;
  --surface-soft: #edf3f8;
  --text: #17212b;
  --muted: #536474;
  --border: #ccd7e1;
  --accent: #216fa8;
  --accent-soft: #e6f3fc;
  --warning: #9a5200;
  --warning-soft: #fff1dd;
  --danger: #a12622;
  --danger-soft: #ffeded;
  --success: #216e39;
  --success-soft: #e8f7ec;
}

@media (prefers-color-scheme: dark) {
  :root {
    --page: #14191e;
    --surface: #20272d;
    --surface-soft: #29323a;
    --text: #edf3f8;
    --muted: #b7c3cd;
    --border: #46535f;
    --accent: #75c3f3;
    --accent-soft: #19394d;
    --warning: #ffb35c;
    --warning-soft: #412c17;
    --danger: #ff9c96;
    --danger-soft: #431c1c;
    --success: #83dda0;
    --success-soft: #183923;
  }
}
```

No comunicar estado mediante color aislado. Combinar color con icono, título y
texto. Comprobar contraste con el tamaño real, no solo con el color teórico.

## 3. Tipografía, espacio y geometría

- Fuente: pila `system-ui`; no descargar webfonts.
- Cuerpo: 16–18 px equivalentes, `line-height` entre 1.55 y 1.7.
- Línea de lectura: aproximadamente 60–75 caracteres.
- Escala de espacio: 0.25, 0.5, 0.75, 1, 1.5, 2 y 3 rem.
- Radio: 0.5–1 rem; usar uno o dos niveles, no uno por componente.
- Sombra: solo para separar la superficie principal del fondo.
- Títulos: usar `clamp()` cuando el rango de pantalla lo justifique.

## 4. Iconografía

Usar el sprite `assets/editorial-icons.svg` como fuente de símbolos. Para
publicar, copiar el SVG a `Documents/assets/` o insertar los símbolos usados al
inicio del HTML. No crear una dependencia runtime hacia `.agents/`.

Patrón con sprite local:

```html
<svg class="icon" aria-hidden="true">
  <use href="assets/editorial-icons.svg#icon-folder"></use>
</svg>
```

```css
.icon {
  width: 1.2em;
  height: 1.2em;
  flex: none;
  fill: none;
  stroke: currentColor;
  stroke-width: 1.75;
  stroke-linecap: round;
  stroke-linejoin: round;
}
```

Mapa semántico:

| Símbolo | Uso |
|---|---|
| `icon-book-open` | manual, capítulo o lectura |
| `icon-list` | índice o vista de lista |
| `icon-grid` | rejilla o comparación visual |
| `icon-detail` | detalle o información secundaria |
| `icon-folder` | carpeta o contenedor |
| `icon-search` | búsqueda |
| `icon-settings` | configuración |
| `icon-info` | información neutral |
| `icon-warning` | precaución recuperable |
| `icon-shield-alert` | bloqueo o seguridad |
| `icon-check` | validado o completado |
| `icon-image` | captura o evidencia visual |
| `icon-print` | impresión o PDF |

No decorar todos los encabezados. Priorizar portada, navegación, comparaciones,
pasos y llamadas de atención.

## 5. Componentes

### Portada

Incluir identidad, versión, idioma, fecha, entorno observado y estado. Evitar
convertir la portada en una pantalla de aplicación.

### Índice

Usar enlaces descriptivos y foco visible. Un icono puede distinguir grupos,
pero el texto debe permanecer completo.

### Tarjetas

Usar para opciones paralelas como Grid/List/Detail. Todas deben compartir
estructura, altura flexible y un icono semántico. No anidar tarjetas.

### Pasos

Usar lista ordenada. Añadir números decorativos solo si el número textual sigue
presente para tecnologías de asistencia.

### Llamadas de atención

- Información: azul, `icon-info`, título **Información**.
- Precaución: ámbar, `icon-warning`, título **Precaución**.
- Seguridad: rojo, `icon-shield-alert`, título **Bloqueado por seguridad**.
- Validación: verde, `icon-check`, título **Validado**.

### Estado de validación

Distinguir `validado`, `inspeccionado estáticamente` y `pendiente`. Nunca usar
el icono de éxito para una observación pendiente.

## 6. Capturas y figuras

- Revisar privacidad visible y metadata antes de publicar.
- Declarar `width`, `height`, `loading="lazy"` y `alt`.
- Usar `figure` y `figcaption` para toda evidencia con explicación.
- Describir en texto el significado de flechas, números y colores.
- Conservar originales; no regenerar una captura técnica con IA.
- Excluir del flujo principal imágenes redundantes o con contenido demasiado
  pequeño, aunque permanezcan en el inventario de evidencia.

## 7. Adaptación e impresión

En móvil:

- una sola columna por debajo de 40 rem;
- superficie a ancho completo;
- índice en una columna;
- imágenes fluidas sin zoom horizontal;
- texto nunca menor de 16 px equivalentes.

En impresión:

- fondo blanco y texto oscuro;
- ocultar navegación no útil y enlaces para saltar;
- evitar cortes dentro de figuras, tarjetas y llamadas;
- conservar iconos semánticos en monocromo si no hay color;
- mostrar URL solo cuando aporte información pública útil;
- probar A4 y no afirmar equivalencia PDF sin revisar el resultado.

## 8. Lista de revisión visual

- [ ] Portada, índice y primer objetivo se reconocen en pocos segundos.
- [ ] Iconos comparten trazo, tamaño óptico y significado.
- [ ] No hay iconos decorativos repetidos sin función.
- [ ] Tarjetas comparables están alineadas y tienen densidad equivalente.
- [ ] Advertencias críticas destacan sin dominar todo el documento.
- [ ] Capturas son legibles al tamaño publicado.
- [ ] Claro y oscuro conservan contraste y jerarquía.
- [ ] A 320 px no aparecen recortes ni desplazamiento horizontal.
- [ ] La impresión mantiene orden, figuras y llamadas completas.
- [ ] El estado editorial coincide con las pruebas realmente realizadas.
