# Revision del plasmoide: temas JSON, espectro y modo panel

Fecha: 2026-07-16

Estado: abierta.

## Contexto

La revisión continúa la fase de temas JSON externos después de la prueba visual
del usuario en Plasma real. Afecta la convivencia entre el fondo personalizado
y el visualizador de espectro, además del alcance de la función en modo panel.

## Primera revision

"Al activar el EQ con el tema personalizado, el tema queda sobre el EQ. El EQ
debería quedar por encima porque ambos efectos son compatibles. En modo panel
no debe detectarse la función de temas personalizados."

## Segunda revision

"Los separadores son el problema actualmente: superan el tamaño de la altura
de un icono. Esto se podría corregir."

## Tercera revision

"Las sombras son las que siguen sobresaliendo de forma irregular."

## Cuarta revision

"Sólo con Marco Neón sucede este efecto que aún se puede corregir."

## Hallazgos confirmados

### Bug confirmado por el usuario: jerarquía visual ambigua

Con un tema personalizado y el visualizador activos simultáneamente, el fondo
puede percibirse por encima del espectro. Aunque `AudioSpectrumLayer` estaba
declarado después del fondo, la jerarquía no tenía niveles `z` explícitos.

### Decisión de producto: temas exclusivos del modo flotante

Los temas personalizados no deben cargarse, aplicarse ni ofrecer controles de
configuración cuando el plasmoide está integrado en un panel Plasma. La
preferencia guardada debe conservarse para un posible regreso al modo flotante.

### Bug confirmado por el usuario: separador más alto que el icono

Con un tema personalizado que usa una línea larga y glow, el separador supera
visualmente la altura de los iconos. La captura aportada muestra que tanto el
cuerpo como el resplandor atraviesan la silueta vertical del dock.

La capa involucrada es `DockItem.qml`: la longitud se calculaba usando
`visualAreaHeight`, equivalente a `iconSize + 12`, y no descontaba la expansión
del glow dibujado por `ThemedSeparator.qml`.

La prueba posterior confirmó que el cuerpo ya respetaba el límite, pero el
shader de `Kirigami.ShadowedRectangle` continuaba expandiendo el halo de forma
irregular. La implementación oficial ajusta la sombra según la relación de
aspecto del rectángulo; una línea estrecha y alta amplifica esa expansión.

La cuarta captura confirmó que el separador quedó corregido. La franja
horizontal restante pertenece al rim de `ShelfThemeBackground.qml`. Marco Neón
la hacía visible porque declara un glow de `12`, frente a los valores de `2–5`
de los otros cuatro temas 2.5D.

## Plan de accion

1. Establecer niveles de apilamiento explícitos para fondos y espectro.
2. Impedir que el repositorio cargue el tema en modo panel.
3. Ocultar la sección completa de temas externos en la página de Apariencia
   cuando el plasmoide esté en panel.
4. Limitar la huella vertical completa de cada separador temático a
   `iconSize`, incluyendo el glow.
5. Validar QML, pruebas nativas y empaquetado, dejando pendiente la confirmación
   visual del usuario.

## Implementacion revision N° 1

- Los fondos Plasma y JSON usan `z: 0`.
- `AudioSpectrumLayer` usa `z: 10`, garantizando que se componga por encima del
  fondo seleccionado.
- `customDockThemeActive` exige explícitamente que el dock no esté en panel.
- `DockThemeRepository` recibe un identificador vacío en panel y no carga el
  tema administrado.
- `ConfigAspect.qml` detecta el `formFactor` de Plasma y oculta título,
  información, selector, importador, nombre activo y errores de temas.
- La configuración guardada no se borra; vuelve a estar disponible al regresar
  al modo flotante.

## Implementacion revision N° 2

- La longitud solicitada por el tema se calcula ahora sobre `iconSize`, no
  sobre `iconSize + 12`.
- `DockItem.qml` limita el grosor efectivo al tamaño del icono.
- El espacio ocupado por el glow se descuenta de la longitud del cuerpo.
- `ThemedSeparator.qml` recibe el grosor y el glow efectivos, de forma que la
  huella pintada completa no supere la altura del icono.
- Los valores del JSON no se reescriben: el límite pertenece al renderer y se
  aplica también a futuros temas externos.

## Implementacion revision N° 3

- Se retiró `Kirigami.ShadowedRectangle` únicamente del renderer de
  separadores.
- El glow se representa mediante tres rectángulos translúcidos sin animación.
- La expansión vertical usa exactamente el margen reservado por
  `DockItem.qml`.
- La expansión horizontal se limita en función del grosor del separador para
  evitar bloques luminosos demasiado anchos.
- Cuerpo, gradiente, borde y patrones continúan usando el mismo contrato JSON.

La decisión se apoya en
`kde-sdk/frameworks/kirigami/src/primitives/shadowedrectangle.cpp`: la función
`adjustRectForShadow()` multiplica la expansión por la relación de aspecto.

## Implementacion revision N° 4

- Se retiró `Kirigami.ShadowedRectangle` del rim del renderer `shelf`.
- El glow del rim usa ahora un gradiente vertical estático.
- Su expansión horizontal está limitada a un máximo de tres píxeles.
- La expansión vertical continúa respetando `rim.glow.size`, por lo que Marco
  Neón mantiene una presencia más intensa sin proyectar una franja lateral.
- Los cinco temas conservan sus JSON y diferencias de material.

## Validacion

Validación técnica realizada:

- `qmllint` global Fedora:
  - `757` advertencias totales;
  - `744` advertencias `unqualified`;
  - `0` advertencias de layout;
  - `13` propiedades Plasma del baseline;
  - `0` errores de importación;
- compilación completada;
- `ctest`: `5/5` pruebas superadas;
- `git diff --check`: sin errores;
- paquete Fedora creado:
  - `dist/punchi-dock-remastered-0.8.7-fedora44-x86_64.plasmoid`.
- `ThemedSeparator.qml` superó `qmllint` focalizado sin diagnósticos;
- la corrección conserva el mismo conteo global de `qmllint`;
- `ctest` continúa en `5/5` después del límite de altura;
- el paquete Fedora fue regenerado con el renderer corregido.
- `ThemedSeparator.qml` continúa sin diagnósticos después de sustituir el
  shader de sombra;
- el empaquetado completo conserva el baseline global de `757` advertencias;
- `ctest`: `5/5` después de introducir el halo acotado;
- paquete Fedora regenerado correctamente con el nuevo glow.
- `ShelfThemeBackground.qml` y `ThemedSeparator.qml` superaron `qmllint`
  focalizado sin diagnósticos;
- el nuevo halo del rim conserva el baseline global de `757` advertencias;
- `ctest`: `5/5` después de sustituir la sombra del rim;
- paquete Fedora regenerado correctamente.

Pendiente:

- inspección visual del usuario con EQ y tema personalizado activos;
- comprobación visual de que la sección no aparece en modo panel.
- confirmación visual de que cuerpo y glow del separador quedan dentro de la
  altura de los iconos.
- confirmación visual de Marco Neón sin extensión horizontal irregular del
  rim.

La revisión permanece abierta hasta recibir evidencia visual en Plasma real.

### Soluciones ya intentadas para no repetir

- Confiar solamente en el orden de declaración de los componentes no expresa
  suficientemente el contrato visual. La relación fondo → espectro debe
  conservar niveles `z` explícitos.
- Reducir `lengthRatio` tema por tema sólo escondería el defecto. El renderer
  debe imponer el límite porque el glow cambia la huella real del separador.
- Reservar el tamaño correcto sin sustituir `ShadowedRectangle` tampoco basta
  para líneas muy estrechas: su shader expande la sombra según el aspecto.
- Reducir sólo el glow de Marco Neón ocultaría el problema del renderer. El rim
  debe controlar su halo para cualquier tema externo con una línea muy ancha.
