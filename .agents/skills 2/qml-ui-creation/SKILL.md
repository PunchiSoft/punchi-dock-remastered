---
name: qml-ui-creation
description: Activa esta skill al crear, modificar o diseñar componentes visuales de interfaz de usuario usando QML para KDE Plasma 6. Utiliza esta skill siempre que el usuario solicite elementos visuales, animaciones, layouts o componentes de la UI del plasmoide.
---

# QML UI Creation Skill

## Instrucciones Detalladas
Esta skill se centra exclusivamente en la creación y modificación de la interfaz visual del plasmoide utilizando QML y KDE Frameworks 6 (KF6).
1. Utiliza siempre los componentes estándar de Plasma (`PlasmaCore`, `PlasmaComponents3`) para mantener la coherencia visual con el resto del escritorio.
2. Evita mezclar lógica de negocio (JavaScript complejo) dentro de los archivos `.qml`. Toda lógica pesada debe referenciarse desde archivos JS.
3. Divide las interfaces complejas en componentes más pequeños y reutilizables. Guárdalos en subdirectorios lógicos y usa las plantillas de `Templates/` si están disponibles.
4. Mantén la escalabilidad: usa layouts (`RowLayout`, `ColumnLayout`, `GridLayout`) en lugar de posicionamiento absoluto.

## Checklist
- [ ] ¿El archivo QML solo maneja la representación visual y el paso de señales?
- [ ] ¿Se utilizan los componentes de `PlasmaComponents3` en lugar de `QtQuick.Controls` básicos donde aplique?
- [ ] ¿La interfaz responde correctamente a cambios de tamaño (layouts dinámicos)?
- [ ] ¿Se han importado correctamente las librerías de KF6 requeridas?

## Buenas Prácticas
- Usar `PlasmaCore.Units` para espaciados, tamaños de fuente e iconos. Esto garantiza que el widget respete las preferencias de escalado y accesibilidad del usuario.
- Usar `PlasmaCore.ColorScope` para adaptarse automáticamente a los temas oscuros/claros.
- Documentar las propiedades expuestas (alias y properties) en la cabecera de los componentes reutilizables.

## Errores Comunes
- **Hardcodear tamaños o colores**: Esto rompe la integración con los temas de KDE. Siempre usa `PlasmaCore.Theme` o `PlasmaCore.Units`.
- **Escribir funciones complejas de manejo de datos en QML**: Esto dificulta el mantenimiento. Delega a `js-plasma-backend`.
- **Uso de versiones antiguas de imports**: En Plasma 6, asegúrate de importar las versiones correctas y evitar módulos deprecados de Plasma 5.

## Criterios de Aceptación
- El componente QML compila y se renderiza sin errores de parseo.
- La interfaz visual se adapta automáticamente al tema del sistema de Plasma.
- El código QML no excede su responsabilidad visual (no realiza llamadas directas a procesos ni lógica de estado compleja).
