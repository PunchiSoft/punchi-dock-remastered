# Instrucciones del proyecto: Punchi Dock Remastered

## Alcance y precedencia

Este archivo es la fuente canónica de instrucciones para todo el repositorio.

- Se aplica a todos los archivos y directorios, salvo que exista un `AGENTS.md` más cercano con instrucciones específicas.
- Las instrucciones específicas complementan estas reglas; no deben contradecirlas sin explicar la excepción.
- `.agents/skills/` contiene procedimientos especializados que se activan según la tarea.
- Si una skill contradice este archivo, prevalece este archivo.
- `.agents/skills 2/` es una copia no canónica detectada durante la auditoría. No debe consultarse ni editarse.

## Contexto del proyecto

Punchi Dock Remastered es un plasmoide para KDE Plasma 6 construido principalmente con QML, Qt 6 y JavaScript.

- El código ejecutable del plasmoide vive en `contents/`.
- `metadata.json` define la identidad, versión y compatibilidad declarada del paquete.
- `kde-sdk/` contiene repositorios locales de KDE usados como referencia técnica.
- `docs/` conserva diseño, revisiones y planes.
- `bitacora/` registra cambios relevantes del proyecto.

## Matriz de compatibilidad

| Dimensión | Política actual |
|---|---|
| Sistema | Linux |
| Plasma mínimo declarado | 6.0, según `metadata.json` |
| Plasma objetivo | Plasma 6 disponible en Fedora 44 o posterior |
| Qt | Qt 6; no hay una versión menor fijada todavía |
| KDE Frameworks | KF6; no hay una versión menor fijada todavía |
| Sesión principal | Wayland |
| Entorno principal de desarrollo y pruebas | Fedora 44 o posterior |
| SDK local | Referencia upstream reciente, no versión mínima implícita |

Reglas derivadas:

1. No elevar el mínimo declarado de Plasma, Qt o KF sin autorización explícita y evidencia de necesidad.
2. No afirmar compatibilidad efectiva con Plasma 6.0 sin una prueba en ese entorno. `metadata.json` expresa el mínimo declarado, no una garantía de pruebas.
3. Una API encontrada en el SDK local puede ser posterior al mínimo declarado. Antes de usarla, comprobar desde cuándo existe o proporcionar una alternativa compatible.
4. Priorizar Wayland. Solo implementar comportamiento específico de X11 cuando la tarea lo requiera expresamente.
5. Los comandos de desarrollo deben ser compatibles con Fedora 44+ salvo indicación contraria.

## Uso del SDK local

Consultar `kde-sdk/` antes de introducir o cambiar integraciones con Plasma, Kirigami, KPackage, KConfig, ki18n, iconos o modelos de tareas.

La búsqueda debe ser dirigida:

| Dominio | Rutas prioritarias |
|---|---|
| Tareas y ventanas | `kde-sdk/plasma-workspace/libtaskmanager/` |
| Componentes Plasma | `kde-sdk/frameworks/plasma-framework/`, `kde-sdk/plasma-workspace/components/` |
| Kirigami | `kde-sdk/frameworks/kirigami/` |
| Empaquetado | `kde-sdk/frameworks/kpackage/` |
| Configuración | `kde-sdk/frameworks/kconfig/` |
| Traducciones | `kde-sdk/frameworks/ki18n/` |
| Iconos | `kde-sdk/frameworks/kiconthemes/` |
| Servicios | `kde-sdk/frameworks/kservice/` |

Al usar el SDK:

- buscar primero símbolos, tipos, ejemplos y pruebas relacionados con la tarea;
- preferir patrones oficiales sobre APIs inventadas o integraciones externas;
- registrar en la explicación final qué referencia respaldó una decisión relevante;
- distinguir una API estable de una implementación interna o snapshot de desarrollo;
- no modificar `kde-sdk/` salvo que la tarea sea explícitamente mantener o estudiar el SDK.

Las consultas puramente documentales o los cambios que no afectan integraciones KDE no requieren una búsqueda artificial en el SDK.

## Arquitectura obligatoria

El flujo preferido es:

```text
UI → señales → controlador → servicio → adaptador de API → KDE
```

Aplicar estas reglas cuando las capas correspondientes existan:

1. La UI representa estado, recoge interacciones y emite señales. No debe ejecutar procesos ni concentrar lógica de negocio compleja.
2. Los controladores coordinan vistas, servicios y estado sin asumir responsabilidades visuales.
3. Los servicios encapsulan operaciones y lógica de negocio. No almacenan estado visual ni preferencias persistentes del usuario.
4. Los adaptadores de API separan dominios como tareas, ventanas o escritorios virtuales. Evitar una API monolítica.
5. Los modelos representan datos; el estado representa condiciones transitorias de la interfaz o aplicación.
6. Los proxies adaptan modelos nativos sin duplicar estructuras que ya expone `QAbstractItemModel`.
7. Ningún módulo lógico o de datos puede depender de componentes visuales.
8. Evitar dependencias circulares entre capas.

La estructura real del repositorio puede evolucionar. No crear carpetas o abstracciones vacías solo para imitar el diagrama; introducir una capa cuando tenga una responsabilidad concreta.

## Modularidad y tamaño

- Cada archivo y componente debe tener una responsabilidad reconocible.
- Evitar concentrar la interfaz y la lógica en `main.qml`.
- Colocar componentes visuales reutilizables en `contents/ui/components/` cuando corresponda.
- Al superar aproximadamente 300–400 líneas, revisar cohesión y oportunidades de extracción.
- El umbral de líneas es una señal de revisión, no una orden de fragmentar código cohesivo.
- Evitar reescrituras extensas si una modificación incremental resuelve el problema.

## QML e integración visual

- Preferir componentes oficiales de Plasma y Kirigami cuando correspondan al contexto del plasmoide.
- Usar colores, tipografía, medidas y métricas proporcionadas por el tema y el sistema.
- No introducir colores fijos para elementos que deban adaptarse al tema claro u oscuro.
- Favorecer bindings declarativos legibles; evitar bindings costosos, ciclos y actualizaciones continuas innecesarias.
- Mantener animaciones sutiles y acotadas. Considerar coste de CPU/GPU y preferencias de reducción de movimiento.
- Preservar navegación por teclado, foco visible, nombres accesibles y escalado.
- No asumir que una API de compatibilidad con Plasma 5 está prohibida solo por su nombre. Si el proyecto ya depende de `Plasma5Support`, evaluar su disponibilidad, necesidad y alternativa antes de retirarla.

## JavaScript, procesos y seguridad

- Usar sintaxis compatible con el motor JavaScript de la versión objetivo de QML.
- Preferir `const` y `let`; evitar contaminar el ámbito global.
- Usar `.pragma library` solo cuando el comportamiento compartido y sin estado lo justifique.
- Tratar entradas, rutas, argumentos y datos externos como no confiables.
- No construir comandos concatenando datos sin validar.
- Aplicar privilegio mínimo y manejar explícitamente fallos, recursos ausentes y resultados vacíos.
- Bajo Wayland, utilizar integraciones nativas de KDE para tareas restringidas por el compositor.
- Python puede utilizarse para herramientas de desarrollo en `Scripts/`, pero no como dependencia del runtime del plasmoide.

## Internacionalización

- Todo texto visible para el usuario debe ser traducible mediante ki18n.
- Usar `i18n`, `i18nc` o `i18np` según contexto y pluralidad.
- Usar marcadores como `%1` en lugar de concatenar fragmentos traducidos.
- No traducir anticipadamente en JavaScript si ello impide reaccionar a cambios de idioma.

## Empaquetado

- Mantener `metadata.json` coherente con las capacidades reales del plasmoide.
- Revisar `.kpackageignore` cuando se creen carpetas o artefactos que no pertenezcan al paquete.
- `docs/`, `bitacora/`, `kde-sdk/`, `.agents/`, copias, logs y artefactos de desarrollo no deben incluirse en la distribución.
- No cambiar versión, licencia, compatibilidad mínima o identificador del plugin como efecto lateral de otra tarea.

## Flujo de trabajo

Antes de cambiar código:

1. Leer este archivo y cualquier `AGENTS.md` aplicable al archivo objetivo.
2. Inspeccionar el estado existente y preservar cambios ajenos.
3. Activar solo las skills necesarias.
4. Consultar el SDK local cuando la tarea afecte integraciones KDE.
5. Elegir el cambio más pequeño que satisfaga el objetivo.

Durante el trabajo:

- no mezclar refactorizaciones no solicitadas con correcciones o funciones;
- no modificar archivos ajenos al alcance sin una razón necesaria;
- documentar decisiones que no sean evidentes desde el código;
- mantener las operaciones reversibles siempre que sea posible.

## Bitácora y documentación

Crear o actualizar una entrada en `bitacora/` cuando ocurra al menos una de estas condiciones:

- se implementa una función o corrección relevante;
- cambia la arquitectura, compatibilidad, empaquetado o flujo de desarrollo;
- se completa una fase de trabajo planificada;
- se toma una decisión técnica que futuras sesiones deben conocer;
- el usuario solicita expresamente un registro.

No es obligatorio crear una bitácora para:

- consultas sin cambios;
- inspecciones breves sin una conclusión duradera;
- correcciones tipográficas triviales;
- acciones ya registradas adecuadamente en una entrada activa.

Los errores visuales reportados por el usuario pueden tener evidencia en `docs/revisiones/`; consultar esa carpeta cuando corresponda.

## Validación proporcional

Toda modificación debe verificarse en proporción a su riesgo.

- Documentación: revisar enlaces, rutas, consistencia y afirmaciones verificables.
- QML/JavaScript: ejecutar validación sintáctica o lint cuando exista la herramienta adecuada.
- Empaquetado: comprobar estructura, metadata y exclusiones.
- Integración visual: complementar la inspección estática con una prueba en Plasma cuando sea posible.
- Cambios de comportamiento: probar el flujo normal, errores previsibles y estados vacíos.

No declarar que algo funciona en runtime si solo fue inspeccionado estáticamente. Informar qué se verificó y qué quedó pendiente.

## Cierre de Sesión y Respaldo (Git)

Cualquier asistente de IA o agente autónomo (ej. Antigravity, Codex, Copilot) debe obedecer este protocolo estricto cuando el usuario solicite terminar la sesión de trabajo, finalizar el día o preparar el código para subir:

1. **Escribir la Bitácora**: Antes de tocar Git, crear un resumen técnico del progreso del día en `bitacora/YYYY-MM-DD-resumen-sesion.md`.
2. **Revisar estado**: Ejecutar `git status` asegurando que no haya basura expuesta (el `.gitignore` debe proteger esto).
3. **Añadir cambios**: Ejecutar `git add .`
4. **Commit Profesional**: Ejecutar `git commit -m "feat/fix/docs/refactor: <resumen claro del trabajo>"`.
5. **Sincronización**: Ejecutar `git push` para respaldar el código en remoto.

Nunca se debe usar git para forzar la subida de binarios u ocultar errores. Este proceso automatiza el fin del día del usuario.

## Lista de cierre

Antes de finalizar una modificación, comprobar lo que aplique:

- [ ] El cambio cumple el alcance solicitado y preserva trabajo no relacionado.
- [ ] Las integraciones KDE se contrastaron con una referencia pertinente.
- [ ] La compatibilidad declarada no se elevó accidentalmente.
- [ ] UI, estado y lógica mantienen responsabilidades separadas.
- [ ] No se introdujeron colores, dimensiones o textos visibles inadecuadamente fijos.
- [ ] Entradas, procesos y errores se manejan de forma segura.
- [ ] Las exclusiones de paquete siguen cubriendo artefactos de desarrollo.
- [ ] Se ejecutaron validaciones proporcionales y se comunicaron sus límites.
- [ ] La bitácora se actualizó si el cambio lo amerita.
