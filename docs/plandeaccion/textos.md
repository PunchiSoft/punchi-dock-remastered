# Plan de acción para instrucciones y skills

## Propósito

Este documento conserva la auditoría inicial y propone una ruta ordenada para mejorar el sistema de instrucciones y skills del proyecto Punchi Dock Remastered.

La auditoría fue de solo lectura. Al momento de redactar este plan no se han movido, fusionado ni eliminado reglas o skills. La creación de este documento es el único cambio realizado.

## Resumen ejecutivo

La base conceptual del sistema es buena: existe una arquitectura clara para Plasma 6, se exige consultar el SDK local y se promueve la separación de responsabilidades. El principal problema no está en la intención, sino en la organización y en el grado real de especialización de las skills.

Actualmente hay cuatro dificultades principales:

1. El archivo de reglas globales se encuentra en `.agents/AGENTS.md`, una ubicación cuyo alcance puede no cubrir todo el repositorio en otras herramientas.
2. Existe un segundo árbol llamado `.agents/skills 2/`, aparentemente duplicado.
3. Varias skills se solapan y no tienen una regla clara de precedencia.
4. Muchas skills son plantillas genéricas que cambian de nombre, pero no ofrecen procedimientos técnicos propios.

La recomendación general es conservar el enfoque, reducir el número de skills y aumentar la calidad operativa de las que permanezcan.

## Diagnóstico detallado

### 1. Alcance de `AGENTS.md`

Solo se encontró el archivo `.agents/AGENTS.md`.

En los sistemas que aplican instrucciones según la jerarquía de directorios, un archivo `AGENTS.md` normalmente gobierna su propio directorio y los descendientes. Por eso, ubicarlo dentro de `.agents/` no garantiza que se aplique sobre:

- `contents/`
- `docs/`
- `metadata.json`
- `.kpackageignore`
- `kde-sdk/`

Aunque el entorno actual expone las skills correctamente, conviene que las reglas principales tengan una ubicación inequívoca.

Recomendación: crear un `AGENTS.md` canónico en la raíz del repositorio y dejar `.agents/` para recursos auxiliares y skills.

### 2. Duplicación de directorios

Se encontraron dos árboles de skills:

- `.agents/skills/`
- `.agents/skills 2/`

El segundo parece una copia casi completa. Esta duplicación tiene varios riesgos:

- una herramienta puede editar la copia incorrecta;
- las búsquedas muestran resultados repetidos;
- pueden aparecer diferencias silenciosas con el tiempo;
- no queda claro cuál es la fuente de verdad;
- el espacio en el nombre del directorio complica scripts y comandos.

No debe eliminarse hasta realizar una comparación completa y conservar cualquier diferencia útil.

### 3. Skills solapadas

Hay grupos que cubren territorios muy similares:

| Grupo | Skills actuales |
|---|---|
| QML e interfaz | `qml`, `qml-ui-creation` |
| JavaScript | `javascript`, `js-plasma-backend` |
| Plasma 6 | `kde-plasma6`, `kde-plasma-6-dev` |
| Localización | `localization`, `ki18n-localization` |
| Empaquetado | `packaging`, `plasmoid-packaging` |
| SDK local | `sdk-reference`, `kde-sdk-reference` |
| Diseño y revisión visual | `ui-design`, `visual-review`, `ux-review`, `accessibility` |

El solapamiento no siempre es malo. Puede ser correcto separar accesibilidad, experiencia de usuario y revisión visual, pero solo si cada skill tiene:

- un disparador diferente;
- un procedimiento propio;
- comprobaciones especializadas;
- criterios de aceptación distintos.

Si dos skills conducen a las mismas acciones, deberían fusionarse o establecer una relación clara entre skill principal y complementaria.

### 4. Skills genéricas

Skills como `architecture`, `code-review`, `debugging`, `documentation`, `javascript`, `kde-plasma6`, `kirigami`, `performance`, `qml`, `testing` y otras contienen principalmente reglas comunes:

- mantener compatibilidad con Plasma 6;
- seguir la arquitectura modular;
- evitar deuda técnica;
- no inventar soluciones ya existentes en KDE.

Estas reglas son válidas, pero deberían vivir principalmente en `AGENTS.md`. Una skill especializada tiene que explicar cómo actuar dentro de su dominio.

Por ejemplo, una skill de pruebas debería indicar:

- qué archivos inspeccionar;
- qué tipos de validación existen;
- qué comandos ejecutar;
- cómo diferenciar una comprobación estática de una prueba real;
- cómo informar limitaciones del entorno;
- qué evidencia se requiere antes de declarar una tarea terminada.

### 5. Skills actualmente más útiles

Las skills con mayor valor operativo son las que incluyen reglas técnicas concretas:

- `kde-plasma-6-dev`
- `qml-ui-creation`
- `js-plasma-backend`
- `ki18n-localization`
- `plasmoid-packaging`
- `python-tooling`

Estas pueden servir como referencia para reescribir o consolidar las demás.

### 6. Fortalezas de las reglas actuales

El archivo `.agents/AGENTS.md` contiene decisiones arquitectónicas valiosas:

- flujo `UI → Signals → Controller → Service → API → SDK KDE`;
- separación entre modelos y estado transitorio;
- uso de proxies para adaptar modelos nativos;
- prohibición de dependencias desde `core` hacia `ui`;
- consulta previa del SDK local;
- preferencia por componentes, colores y medidas del entorno KDE;
- consideraciones de Wayland;
- control del contenido incluido en el paquete.

Estas reglas deberían conservarse, refinando su obligatoriedad y alcance.

### 7. Reglas que necesitan mayor precisión

#### Compatibilidad

La frase «compatibilidad absoluta con Plasma 6» es demasiado amplia. Conviene declarar versiones objetivo y mínimas de:

- KDE Plasma;
- Qt;
- KDE Frameworks;
- Fedora, si forma parte del entorno soportado.

#### Bitácora

«Todo el progreso debe quedar documentado» puede generar ruido en consultas, diagnósticos sin cambios o correcciones triviales. Se debería definir cuándo una entrada de bitácora es obligatoria.

#### Tamaño de archivos

El umbral de 300–400 líneas es una buena señal de revisión, pero no debería forzar divisiones artificiales. La responsabilidad del archivo importa más que una cifra aislada.

#### Consulta del SDK

La obligación de buscar en `kde-sdk/` es valiosa, pero debería incluir rutas prioritarias según el dominio para evitar búsquedas demasiado amplias.

#### Nivel normativo

Conviene distinguir explícitamente entre:

- reglas obligatorias;
- recomendaciones;
- comprobaciones antes de finalizar;
- excepciones justificadas.

## Evaluación inicial

| Área | Evaluación aproximada |
|---|---:|
| Visión arquitectónica | 8/10 |
| Organización física | 5/10 |
| Especialización real de las skills | 4/10 |
| Claridad de activación | 5/10 |
| Utilidad práctica actual | 6/10 |

Estas cifras no miden la calidad del proyecto completo. Solo resumen el estado del sistema de instrucciones y skills.

## Plan de acción

### Seguimiento de fases

| Fase | Estado | Evidencia |
|---|---|---|
| Fase 0: línea base | Completada | [`fase-0-inventario.md`](fase-0-inventario.md) |
| Fase 1: reglas globales | Completada | [`fase-1-reglas-globales.md`](fase-1-reglas-globales.md) |
| Fase 2: duplicación física | Pendiente | — |
| Fase 3: consolidación | Completada | [`fase-3-consolidacion-skills.md`](fase-3-consolidacion-skills.md) |
| Fase 4: procedimientos | Pendiente | — |
| Fase 5: activación | Pendiente | — |
| Fase 6: validación automatizada | Pendiente | — |
| Fase 7: escenarios reales | Pendiente | — |

### Fase 0: crear una línea base

Antes de cambiar la estructura:

1. Inventariar todos los archivos de `.agents/skills/` y `.agents/skills 2/`.
2. Comparar las dos carpetas archivo por archivo.
3. Registrar nombres, descripciones, tamaños y duplicados.
4. Clasificar cada skill como:
   - conservar;
   - mejorar;
   - fusionar;
   - retirar;
5. Confirmar las versiones reales soportadas por el proyecto.

Criterio de aceptación: existe un inventario completo y ninguna eliminación depende de suposiciones.

### Fase 1: asegurar las reglas globales

1. Crear `AGENTS.md` en la raíz.
2. Migrar las reglas vigentes desde `.agents/AGENTS.md`.
3. Separar el contenido en:
   - contexto del proyecto;
   - reglas obligatorias;
   - arquitectura;
   - flujo de trabajo;
   - validación;
   - excepciones.
4. Declarar versiones objetivo y mínimas.
5. Definir cuándo consultar `kde-sdk/` y qué evidencia conservar.
6. Definir cuándo actualizar `bitacora/`.
7. Decidir si `.agents/AGENTS.md` se elimina, se convierte en referencia o queda como instrucción exclusiva para esa carpeta.

Criterio de aceptación: cualquier herramienta que abra el repositorio desde la raíz encuentra reglas inequívocas y aplicables a todo el proyecto.

### Fase 2: eliminar la duplicación física

1. Comparar `.agents/skills/` y `.agents/skills 2/`.
2. Trasladar a la carpeta canónica cualquier diferencia que deba conservarse.
3. Buscar referencias a `skills 2`.
4. Retirar el directorio duplicado solo después de verificar los pasos anteriores.
5. Comprobar que el catálogo de skills continúa cargando correctamente.

Criterio de aceptación: hay una sola fuente de verdad y no existen referencias rotas.

### Fase 3: consolidar skills solapadas

Propuesta inicial:

| Skills actuales | Destino propuesto |
|---|---|
| `qml`, `qml-ui-creation` | `qml-ui` |
| `javascript`, `js-plasma-backend` | `plasma-js-backend` |
| `localization`, `ki18n-localization` | `ki18n-localization` |
| `packaging`, `plasmoid-packaging` | `plasmoid-packaging` |
| `sdk-reference`, `kde-sdk-reference` | `kde-sdk-reference` |
| `kde-plasma6`, `kde-plasma-6-dev` | `kde-plasma-6-dev` |

Las skills `ui-design`, `ux-review`, `visual-review` y `accessibility` deberían conservarse separadas solamente si se desarrollan procedimientos distintos para cada una.

Criterio de aceptación: cada dominio tiene una skill principal inequívoca y los nombres retirados no siguen apareciendo en instrucciones o documentos.

Estado aplicado: los nombres genéricos se conservaron temporalmente como alias de compatibilidad con activación negativa explícita. Esto evita romper referencias antes de completar la eliminación física de la fase 2, mientras deja una única skill operativa por dominio.

### Fase 4: convertir skills en procedimientos operativos

Cada `SKILL.md` debería incluir:

1. **Propósito:** qué problema resuelve.
2. **Disparadores:** cuándo debe activarse y cuándo no.
3. **Entradas:** archivos y contexto que debe inspeccionar.
4. **Referencias:** rutas concretas dentro de `kde-sdk/` o `docs/`.
5. **Procedimiento:** pasos técnicos ordenados.
6. **Reglas específicas:** restricciones propias del dominio.
7. **Validación:** comandos o comprobaciones concretas.
8. **Errores frecuentes:** fallos reales de ese dominio.
9. **Criterios de aceptación:** evidencia necesaria para finalizar.
10. **Relaciones:** skills complementarias y precedencia.

Las reglas globales no deben repetirse completas en cada skill. Se pueden resumir o referenciar desde el `AGENTS.md` principal.

Criterio de aceptación: dos skills diferentes provocan procedimientos realmente diferentes.

### Fase 5: definir activación y precedencia

Propuesta inicial de enrutamiento:

| Tipo de tarea | Skill principal | Complementarias posibles |
|---|---|---|
| Crear o modificar interfaz QML | `qml-ui` | `accessibility`, `animations`, `ki18n-localization` |
| Gestionar ventanas o tareas | `taskmanager-api` | `plasma-js-backend`, `services` |
| Diagnosticar un fallo | `debugging` | `logging`, `testing` |
| Revisar rendimiento | `performance` | `qml-ui`, `plasma-js-backend` |
| Preparar distribución | `plasmoid-packaging` | `release`, `security` |
| Consultar APIs de KDE | `kde-sdk-reference` | skill técnica del dominio |
| Revisar experiencia | `ux-review` | `accessibility`, `visual-review` |

Regla sugerida: activar una skill principal y solo las complementarias necesarias para la tarea concreta.

Criterio de aceptación: ante una solicitud habitual es posible determinar qué skill usar sin ambigüedad.

### Fase 6: crear validación automatizada

Crear una herramienta auxiliar que detecte:

- front matter YAML ausente o inválido;
- nombres o descripciones duplicados;
- carpetas inesperadas o con nombres sospechosos;
- descripciones demasiado genéricas;
- rutas mencionadas que no existen;
- skills sin procedimiento o criterios de aceptación;
- referencias a skills retiradas;
- archivos idénticos o casi idénticos;
- inconsistencias entre el nombre del directorio y el campo `name`.

La herramienta debe ser de solo lectura por defecto y devolver un código de salida distinto de cero cuando encuentre problemas bloqueantes.

Criterio de aceptación: el sistema puede detectar automáticamente una duplicación o referencia rota antes de integrar cambios.

### Fase 7: validar mediante tareas reales

Probar el sistema con escenarios representativos:

1. Crear un componente visual QML.
2. Corregir un problema de modelo de tareas.
3. Diagnosticar un fallo bajo Wayland.
4. Añadir una cadena traducible.
5. Preparar un paquete instalable.
6. Revisar accesibilidad y rendimiento.

En cada escenario se debe observar:

- qué skill se activó;
- qué archivos consultó;
- si encontró referencias pertinentes en `kde-sdk/`;
- qué validaciones ejecutó;
- si hubo instrucciones contradictorias;
- si produjo evidencia suficiente.

Criterio de aceptación: las skills mejoran de manera visible la calidad y consistencia del trabajo en tareas reales.

## Núcleo recomendado

No es aconsejable reescribir todas las skills simultáneamente. El primer núcleo debería concentrarse en:

1. `kde-plasma-6-dev`
2. `kde-sdk-reference`
3. `qml-ui`
4. `plasma-js-backend`
5. `taskmanager-api`
6. `debugging`
7. `testing`
8. `plasmoid-packaging`

Después de comprobar este núcleo en tareas reales, se pueden desarrollar las skills complementarias.

## Prioridades sugeridas

### Prioridad alta

- Establecer `AGENTS.md` en la raíz.
- Comparar y resolver `.agents/skills 2/`.
- Definir versiones soportadas.
- Consolidar los pares de skills claramente duplicados.

### Prioridad media

- Desarrollar procedimientos reales para `debugging`, `testing`, `architecture` y `code-review`.
- Crear la tabla de activación y precedencia.
- Precisar el uso de la bitácora y el SDK local.

### Prioridad baja

- Homogeneizar redacción y estilo.
- Añadir automatización avanzada para similitud de contenido.
- Crear plantillas para futuras skills.

## Secuencia recomendada de ejecución

1. Crear el inventario comparativo.
2. Definir el `AGENTS.md` canónico.
3. Resolver el directorio `skills 2`.
4. Aprobar el mapa de skills que se conservan, fusionan o retiran.
5. Reescribir el núcleo operativo.
6. Definir relaciones y precedencia.
7. Crear el validador.
8. Ejecutar escenarios de prueba.
9. Ajustar las skills según la evidencia obtenida.

## Resultado esperado

Al terminar el plan, el proyecto debería tener:

- un `AGENTS.md` principal y claramente aplicable;
- una sola carpeta canónica de skills;
- aproximadamente 15–20 skills diferenciadas, en lugar de muchas plantillas solapadas;
- procedimientos técnicos concretos;
- reglas de activación y precedencia;
- validación automática de la estructura;
- menos ambigüedad y menor consumo de contexto;
- mayor consistencia entre agentes y sesiones.

## Decisión pendiente antes de implementar

Antes de ejecutar cambios estructurales se debe aprobar:

1. qué versiones exactas de Plasma, Qt, Frameworks y Fedora se soportarán;
2. si `.agents/AGENTS.md` se reemplaza o se conserva como referencia secundaria;
3. qué diferencias, si existen, deben rescatarse de `.agents/skills 2/`;
4. el mapa definitivo de skills que se conservarán, fusionarán o retirarán.
