# Bitácora: Fase 4C de geometría de panel, calendario y papelera

Fecha: 2026-07-11

## Trabajo realizado

- Se ajustó [contents/ui/main.qml](/home/CMUNOZJ/Escritorio/Aprendizaje/punchi-dock-remastered/contents/ui/main.qml:1) para exponer geometría dinámica al panel mediante `Layout.minimumWidth`, `Layout.minimumHeight`, `Layout.preferredWidth` y `Layout.preferredHeight`.
- Se dejó el cálculo del tamaño del dock ligado a:
  - cantidad real de ítems;
  - `iconSize`;
  - `spacing`;
  - márgenes de composición.
- Se eliminó la reacción de `hover` del calendario en [contents/ui/components/DockItem.qml](/home/CMUNOZJ/Escritorio/Aprendizaje/punchi-dock-remastered/contents/ui/components/DockItem.qml:1), evitando tanto el crecimiento propio como el disparo de la ola en ítems vecinos.
- Se creó [src/trashintegration.h](/home/CMUNOZJ/Escritorio/Aprendizaje/punchi-dock-remastered/src/trashintegration.h:1) y [src/trashintegration.cpp](/home/CMUNOZJ/Escritorio/Aprendizaje/punchi-dock-remastered/src/trashintegration.cpp:1) como integración nativa separada para la papelera.
- `TrashIntegration` ahora cubre:
  - apertura de `trash:/`;
  - vaciado nativo con KIO;
  - observación reactiva del contenido mediante `KDirWatch`;
  - señal de cambio de estado para que QML actualice el icono sin sondeo shell periódico.
- Se retiró del flujo principal el `Timer` + `find ... | wc -l` que monitoreaba la papelera desde QML.

## Validación

- `cmake --build build`
- `ctest --test-dir build --output-on-failure`
- `cmake --build build --target stage_plasmoid_module`

## Observación de runtime

- En prueba real dentro de Plasma, la papelera pasó a comportarse de forma claramente más nativa.
- Al abrirla mediante la nueva integración, se observó también la animación visual esperada del icono, consistente con el comportamiento nativo de KDE al lanzar elementos.

## Implicación arquitectónica

- Este resultado refuerza que las rutas nativas de KDE/KIO no solo mejoran robustez y latencia, sino también la integración visual y de experiencia de usuario.
- Conviene tomar esta implementación como referencia para futuras migraciones de acciones que hoy siguen pasando por shell o por lanzamientos genéricos.
- En particular, vale la pena evaluar si aperturas de aplicaciones, carpetas u otros destinos pueden beneficiarse del mismo criterio: priorizar integración nativa cuando exista una API KDE adecuada.

## Pendiente recomendado

- Probar runtime real en panel de Plasma para confirmar:
  - reserva dinámica de espacio;
  - alineación visual del dock;
  - actualización inmediata del icono de papelera;
  - comportamiento del calendario al pasar el mouse.
