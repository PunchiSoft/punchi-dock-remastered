# Fase 1: reglas globales

## Estado

Fase completada el 10 de julio de 2026.

## Cambios realizados

1. Se creó `AGENTS.md` en la raíz como fuente canónica para todo el repositorio.
2. `.agents/AGENTS.md` se convirtió en una instrucción local breve que referencia al archivo canónico.
3. Se declaró `.agents/skills/` como única fuente canónica de skills.
4. Se marcó `.agents/skills 2/` como copia no canónica pendiente de retirada.
5. Se separaron reglas obligatorias, recomendaciones, flujo de trabajo, validación y lista de cierre.
6. Se definió cuándo consultar el SDK local y qué rutas priorizar.
7. Se limitó la obligación de bitácora a cambios y decisiones relevantes.
8. El umbral de 300–400 líneas pasó de ser una división automática a una señal de revisión de cohesión.

## Matriz de compatibilidad adoptada

| Dimensión | Decisión |
|---|---|
| Plasma mínimo declarado | 6.0, conservando `metadata.json` |
| Plasma objetivo | La versión de Plasma 6 disponible en Fedora 44+ |
| Qt | Qt 6, minor aún no fijado |
| KDE Frameworks | KF6, minor aún no fijado |
| Sesión principal | Wayland |
| Distribución principal | Fedora 44+ |
| SDK local | Referencia upstream reciente, no mínimo implícito |

## Justificación de compatibilidad

Se conservó Plasma 6.0 como mínimo declarado porque es el valor actual de `X-Plasma-API-Minimum-Version`. Elevarlo sin pruebas ni una necesidad funcional sería un cambio de producto no solicitado.

La nueva regla distingue entre:

- **mínimo declarado:** lo que acepta el manifiesto;
- **entorno objetivo:** donde se desarrolla y prueba principalmente;
- **referencia upstream:** snapshots recientes consultados para conocer patrones y APIs.

La compatibilidad efectiva con Plasma 6.0 no se da por demostrada. Deberá validarse o reajustarse en una tarea específica.

## Decisión sobre `.agents/AGENTS.md`

El archivo no se eliminó porque puede ser consumido por herramientas que ya esperan esa ruta. Se redujo a instrucciones exclusivas del directorio y una referencia al archivo raíz. Esto evita mantener dos copias completas que puedan divergir.

## Consulta del SDK

La consulta deja de ser una búsqueda indiscriminada para cualquier tarea. Es obligatoria cuando se cambian integraciones KDE y se dirige primero a rutas relacionadas con el dominio:

- `libtaskmanager` para tareas y ventanas; el clon actual no incluye el directorio del applet oficial de tareas;
- `plasma-framework` y componentes de workspace para UI Plasma;
- repositorios de Kirigami, KPackage, KConfig, ki18n, iconos y servicios para sus dominios respectivos.

Las tareas puramente documentales o sin integración KDE no requieren búsquedas artificiales.

## Criterios de aceptación

- [x] Existe un `AGENTS.md` inequívoco en la raíz.
- [x] Su alcance y precedencia están documentados.
- [x] Las versiones declaradas se distinguen del entorno objetivo y del SDK local.
- [x] La arquitectura obligatoria está descrita sin exigir capas vacías.
- [x] La consulta del SDK tiene rutas y condiciones concretas.
- [x] La bitácora tiene disparadores definidos.
- [x] La validación exige comunicar sus límites.
- [x] `.agents/AGENTS.md` ya no duplica las reglas globales.

## Trabajo pendiente

- Confirmar mediante pruebas el mínimo real de Plasma, Qt y KF6.
- Resolver físicamente `.agents/skills 2/` en la Fase 2.
- Consolidar skills solapadas en la Fase 3.
