---
name: editorial-voice
description: Redactar y revisar cualquier texto de Punchi Dock con una voz de una sola persona responsable, sin plural institucional, con claridad, brevedad, registro formal culto y lectura pensada para quien usa el dock. Usar al crear o editar README, CHANGELOG, manuales, guías, textos de tienda, notas de publicación, respuestas externas, mensajes de la interfaz y documentación interna nueva; no sustituye la aprobación previa de `notice-copy-approval` ni la gestión de catálogos de `ki18n-localization`.
---

# Voz editorial y texto claro

## Objetivo

Punchi Dock Remastered lo construye una sola persona en su tiempo libre, con
asistencia de agentes de IA declarada en el propio proyecto. Esa realidad debe
notarse en cómo está escrito: sin «nosotros», sin equipo imaginario, sin
promesas institucionales. Este procedimiento fija la voz, la claridad, la
brevedad y el registro de todo texto del repositorio.

## Cuándo activarla

- Al redactar o revisar README, CHANGELOG, `CONTRIBUTING.md`, `SECURITY.md`,
  `SUPPORT.md`, manuales, guías, notas de publicación y textos de tienda.
- Al escribir documentación interna nueva en `docs/` o `bitacora/`.
- Al preparar respuestas externas, junto con `github-issue-response`.
- Al redactar o corregir textos visibles de la interfaz, junto con
  `ki18n-localization` y, si explican algo, con `notice-copy-approval`.
- Al revisar un texto ajeno antes de publicarlo o de abrir un pull request.

No se activa para renombrar variables, comentarios de código ni mensajes de log:
esos siguen las reglas de idioma de `AGENTS.md`.

## Alcance y límites

- Cubre todo texto del repositorio, incluidos `docs/` y `bitacora/`.
- Gobierna el texto nuevo y el texto que ya se esté modificando por otro motivo.
- No autoriza reescribir documentos históricos ni notas de revisión cerradas.
- Las citas textuales de una persona se conservan literales, incluso si usan
  primera persona plural; el texto que las rodea no la imita.
- No sustituye la aprobación previa de cualquier nota o aviso dirigido a quien
  usa el dock, que pertenece a `notice-copy-approval`.
- No decide catálogos, plurales ni marcadores de traducción: eso pertenece a
  `ki18n-localization`.

## Regla de voz

| Caso | Forma correcta | Forma prohibida |
|---|---|---|
| Describir qué hace el producto | «Punchi Dock Remastered muestra…» | «Mostramos…» |
| Instruir a quien lo usa | «Ejecuta el script desde la raíz.» | «Ejecutaremos el script.» |
| Declarar una decisión técnica | Impersonal: «La compatibilidad declarada no se eleva sin evidencia.» | «Decidimos elevar…» |
| Nombrar al responsable | «The maintainer…» / «El mantenedor…» | «Maintainers…», «los mantenedores», «nuestro equipo» |
| Hablar del proceso de desarrollo | «AI agents assist with…» / «Los agentes de IA asisten…» | Omitir la asistencia de IA o atribuirle decisiones técnicas |
| Declaración personal del autor | «I validated this release on Fedora 44.» | «We validated…», «validamos…» |
| Propiedad del repositorio | «PunchiSoft publishes…» como titular | «En PunchiSoft creemos…» |

Reglas derivadas:

- `I` en primera persona singular es la única forma personal admitida, y solo
  cuando la frase necesita un actor concreto que asume la afirmación.
- `PunchiSoft` identifica al titular de derechos y al propietario del
  repositorio; nunca actúa como colectivo con opiniones o compromisos.
- La asistencia de IA se declara al describir el proceso, no se usa para
  justificar una decisión técnica ni para diluir responsabilidad.
- Prohibido en cualquier idioma: `we`, `our`, `us`, `nosotros`, `nuestro`,
  `nuestros`, `wir`, `uns`, `unser`, `nós`, `nosso`, `nossa`.

## Claridad

- Una idea por frase. Si una frase necesita dos comas y una conjunción, se
  divide.
- Voz activa y verbo concreto: «El script compila el módulo» en lugar de «se
  realiza la compilación del módulo».
- Sujeto explícito cuando el lector pueda dudar de quién actúa.
- El resultado antes que el procedimiento: qué obtiene la persona y después
  cómo lo consigue.
- Cada término técnico se define en su primer uso o se enlaza a donde se
  define. No introducir siglas sin expandirlas una vez.
- Sin cadenas de dos o más gerundios.
- Sin dobles negaciones ni condicionales apilados.

## Brevedad

- No repetir una instrucción que ya aparece en un paso, una tabla o un bloque
  cercano. Si el párrafo no añade un dato nuevo, se elimina.
- Sin adjetivos promocionales: «potente», «increíble», «revolucionario»,
  «perfecto», «único».
- Sin muletillas: «cabe destacar», «es importante mencionar», «como sabemos»,
  «en este sentido».
- Un bloque de texto de un README no supera las cuatro frases. Una lista no
  supera los cinco elementos sin una razón de contenido.
- Los datos verificables se dan una vez y con su fecha; no se repiten al final
  del documento.

## Lectura para usuario final

- Escribir para quien quiere instalar, configurar o recuperar el dock, no para
  quien conoce QML, KWin, KPackage o la arquitectura interna.
- Orden útil: qué es, qué necesita, cómo se hace, qué debe verse, qué hacer si
  no se ve.
- Nominar elementos por lo que la persona ve en la interfaz, no por el
  componente QML que los implementa.
- No exigir conocimiento del repositorio: si una ruta o un comando es
  necesario, se muestra completo y se dice desde dónde se ejecuta.
- Reconocer límites y dependencias de KDE sin convertirlos en excusas.

## Registro y gramática

- Registro formal culto, sin afectación y sin coloquialismos.
- Tuteo imperativo consistente en español («ejecuta», «elige»); nunca mezclar
  con «usted» en el mismo documento.
- Concordancia de número, género y tiempo revisada frase por frase.
- Nombres de producto con su grafía oficial: `Punchi Dock Remastered`,
  `PunchiMenu`, `KDE Plasma 6`, `Qt 6`, `KDE Frameworks 6`.
- Nombres de archivos, comandos, rutas y claves en `code formatting`, sin
  traducir.
- Comillas angulares en español, comillas rectas en inglés, `code` para
  literales.
- Cifras con unidad y espacio: `12 px`, `20 %`, `6.8.2`. Fechas en formato
  ISO cuando se ordenan o comparan.
- Evitar anglicismos evitables; conservar el término técnico cuando la
  traducción pierda precisión, y explicarlo una vez.

## Paridad entre idiomas

- El inglés es el idioma fuente. Los textos compañeros conservan el mismo
  orden, los mismos hechos y el mismo estado de validación.
- No añadir en una traducción matices, promesas ni cifras ausentes en el
  original.
- Si cambia una frase del original, se actualizan todas sus traducciones en el
  mismo cambio.
- Una traducción sin revisión nativa se declara como tal; no se presenta como
  mantenida.

## Relación con otras skills

| Skill | Conserva |
|---|---|
| `notice-copy-approval` | La aprobación previa del texto explicativo y su énfasis |
| `ki18n-localization` | Marcadores, plurales, catálogos y textos de interfaz |
| `github-issue-response` | Su formato de respuesta externa y su verificación previa |
| `documentation` | La estructura documental y las plantillas por carpeta |
| `html-document-design` | La arquitectura editorial y visual de documentos HTML |
| `ui-design` | Las decisiones de interfaz que el texto describe |

Esta skill aporta voz, claridad y registro; no reemplaza ninguna de las
anteriores ni autoriza saltarse sus pasos.

## Ejemplos reales de este repositorio

### Voz impersonal en una instrucción de instalación

```text
Antes:   We recommend `./scripts-user/setup.sh --install --no-restart` to build
         the native module against your system’s Qt and KDE libraries.
Después: Building from source requires KDE Plasma 6 and the project’s development
         dependencies.
```

```text
Antes:   Recomendamos `./scripts-user/setup.sh --install --no-restart` para compilar
         el módulo nativo.
Después: La compilación desde el código fuente requiere KDE Plasma 6 y las
         dependencias de desarrollo del proyecto.
```

### Responsable en singular

```text
Antes:   Maintainers remain responsible for technical decisions.
Después: The maintainer remains responsible for technical decisions.
```

```text
Antes:   Los mantenedores conservan la responsabilidad de las decisiones técnicas.
Después: El mantenedor conserva la responsabilidad de las decisiones técnicas.
```

### Público y mantenedor sin colectivo

```text
Antes:   Project maintainers should use the developer scripts.
Después: For project maintenance, use the developer scripts.
```

### Posesión del proyecto en documentación interna

```text
Antes:   Nuestro ajuste de círculo sobre la misma captura produce un paso de 1.238°.
Después: El ajuste de círculo aplicado a la misma captura produce un paso de 1.238°.
```

### Redundancia

```text
Antes:   Paso 4: `./scripts-user/setup.sh --install --no-restart`. Después del
         paso, el mismo comando se recomienda otra vez.
Después: La frase se elimina; el paso y la tabla de scripts ya lo indican.
```

### Adjetivo promocional (ejemplo ilustrativo)

```text
Antes:   Un dock extraordinario que transforma tu escritorio.
Después: Un dock con lanzadores, ventanas, carpetas y controles de medios.
```

## Checklist de cierre

- [ ] Cero primera persona plural en el texto propio, en cualquier idioma.
- [ ] El actor de cada instrucción se entiende sin conocer el repositorio.
- [ ] Ninguna frase repite un dato ya presente en un bloque cercano.
- [ ] Los términos técnicos se definen o enlazan en su primer uso.
- [ ] El registro es formal y el tuteo, consistente.
- [ ] La asistencia de IA se declara donde corresponde y no asume decisiones.
- [ ] Todas las traducciones compañeras dicen lo mismo que el original.
- [ ] Los textos explicativos ya fueron aprobados por `notice-copy-approval`.
- [ ] Los textos visibles de interfaz están envueltos con ki18n.

## Errores comunes

- Escribir «nosotros» porque la frase suena más cordial: no es cordial, es
  inexacta.
- Sustituir el plural por un sujeto pasivo vacío: «se recomienda» oculta la
  recomendación en lugar de aclararla.
- Convertir cada instrucción en primera persona singular: `I` solo aparece
  cuando alguien asume una afirmación concreta.
- Añadir una nota explicativa sin pasar por `notice-copy-approval`.
- Reescribir un documento histórico porque incumple esta guía: se corrige el
  texto nuevo y se deja el registro como evidencia.
- Traducir nombres de producto, rutas o comandos.
