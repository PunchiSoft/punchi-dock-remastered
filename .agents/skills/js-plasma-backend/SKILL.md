---
name: js-plasma-backend
description: "Implementar o refactorizar lógica JavaScript de Punchi Dock: transformación de datos, coordinación de estado, controladores y adaptación entre QML y APIs de Plasma. Usar para lógica no visual; combinar con una skill de dominio para tareas, servicios o procesos, y no usar para simples bindings de presentación."
---

# Lógica JavaScript para Plasma

## Procedimiento

1. Inspeccionar quién posee el estado y qué vista o servicio consume el resultado.
2. Definir entradas, salidas, errores y ciclo de vida antes de mover o crear lógica.
3. Mantener controladores y adaptadores independientes de `id` visuales; comunicar mediante propiedades, señales y funciones explícitas.
4. Consultar el SDK local antes de introducir una integración con Plasma.
5. Gestionar operaciones asíncronas, destrucción de objetos, conexiones y resultados obsoletos.

## Reglas

- Preferir `const` y `let`, funciones pequeñas y datos inmutables cuando resulte práctico.
- Usar `.pragma library` solo para utilidades sin dependencia de instancia; no usarla como solución automática para estado global.
- No bloquear el hilo de UI ni ejecutar sondeos continuos sin necesidad.
- No construir comandos de shell con datos concatenados; validar entradas y usar la integración específica disponible.
- No manipular objetos visuales desde lógica externa ni duplicar modelos nativos de KDE.
- Documentar contratos complejos, no cada línea evidente.

## Validación

- Comprobar sintaxis con la herramienta disponible y ejecutar pruebas existentes.
- Probar entradas normales, vacías, inválidas, errores asíncronos y destrucción durante una operación.
- Verificar que QML recibe cambios por bindings o señales sin dependencias circulares.

## Criterios de aceptación

- La propiedad del estado y el flujo de datos son claros.
- La lógica no depende de detalles visuales ni bloquea la shell.
- Los errores y el ciclo de vida tienen tratamiento explícito.
