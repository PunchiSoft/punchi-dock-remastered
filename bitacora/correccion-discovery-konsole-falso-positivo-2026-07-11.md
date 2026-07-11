# Corrección de discovery: falso positivo al buscar Konsole

Fecha: 2026-07-11

## Problema

Al usar el autodescubrimiento de aplicaciones desde la configuración, buscar `konsole` podía devolver un launcher personalizado no relacionado, por ejemplo un acceso a ComfyUI cuyo `Exec` contenía `konsole -e ...`.

## Causa

`findApplicationService()` en `src/systemdiscovery.cpp` aceptaba coincidencias parciales demasiado pronto, incluyendo `service->exec().contains(needle)`. Eso permitía que cualquier `.desktop` cuyo comando invocara `konsole` se colara como primer resultado.

## Solución aplicada

Se reordenó la búsqueda con esta prioridad:

- coincidencia exacta por `storageId`
- coincidencia exacta por `desktopEntryName`
- coincidencia exacta por nombre visible
- coincidencia exacta por ejecutable principal normalizado
- coincidencia parcial por nombre visible
- coincidencia parcial por `storageId`

La búsqueda ya no usa coincidencia parcial arbitraria sobre `Exec`.

## Resultado esperado

Buscar `konsole` debe devolver Konsole, no un launcher personalizado cuyo comando contenga `konsole`.

## Validación ejecutada

- `cmake --build build --target stage_plasmoid_module`
- `ctest --test-dir build --output-on-failure`
- `qmllint -I build/bin -I contents/ui -I contents -I /usr/lib64/qt6/qml contents/ui/config/ConfigItems.qml contents/ui/main.qml`
