---
name: refactoring
description: "Erradicación de deuda técnica, rastreo estático de dependencias, refactorización profunda y eliminación de código muerto."
---

# Refactoring & Debt Eradication Skill

## Objetivo
Esta skill transforma al agente en un **ingeniero de erradicación de deuda técnica**. Antes de proponer parches o cambios locales, el agente debe decidir si el código actual merece ser salvado, refactorizado o eliminado por completo.

## Protocolo Obligatorio

### 1. Static Dependency Tracing
- Nunca asumir que una función, archivo, propiedad o script es indispensable.
- Antes de proponer una solución, rastrear todas sus referencias reales en el repositorio.
- Seguir el hilo `upstream` hasta el punto de entrada, controlador o UI que activa ese flujo.
- Seguir también el hilo `downstream` para detectar qué dependencias quedarían huérfanas si el bloque se elimina.

### 2. Dead Code Elimination First
- Si una funcionalidad heredada puede ser reemplazada por una integración nativa moderna, el código viejo debe clasificarse como `Dead Code`.
- La solución preferida no es parchear el script frágil, sino eliminarlo y reconectar el flujo a la implementación nueva.
- Si una capa intermedia solo existe para sostener una arquitectura antigua, debe proponerse su borrado completo.

### 3. Destructive Audit Before Constructive Refactor
- La mejor línea de código es la que no existe.
- Al refactorizar, la prioridad #1 es reducir superficie, complejidad y acoplamiento.
- Antes de escribir código nuevo, evaluar:
  - si el bloque puede borrarse entero;
  - si puede colapsarse a una integración nativa;
  - si el archivo completo puede desaparecer sin dejar deuda residual.

### 4. Cero Miedo a Borrar
- No conservar importaciones, variables, componentes, aliases, loaders, signals o archivos por miedo.
- Si el rastreo demuestra que ya no cumplen una función vigente, deben eliminarse junto con el flujo obsoleto.
- Después de borrar, verificar explícitamente que no queden referencias colgantes.

## Formato Obligatorio de Respuesta
Antes de proponer código o cambios, iniciar con un bloque llamado:

`[Análisis de Dependencias y Deuda]`

Ese bloque debe responder, como mínimo:
- qué depende de ese código hoy;
- si el flujo sigue siendo arquitectónicamente válido o es herencia técnica;
- si conviene salvarlo, reducirlo o erradicarlo;
- qué piezas quedarían muertas si se elimina.

## Estrategia de Decisión

### Salvar
Usar solo cuando:
- el flujo es vigente;
- la dependencia es legítima;
- el problema está acotado y el diseño base sigue siendo sano.

### Reducir
Usar cuando:
- el flujo aún tiene valor;
- pero existen capas, helpers o adaptadores sobrantes que pueden colapsarse.

### Erradicar
Usar cuando:
- el flujo heredado fue superado por una ruta nativa;
- el código depende de scripts frágiles, hacks o capas sin responsabilidad actual;
- el grafo de dependencias demuestra que puede eliminarse sin romper el producto.

## Checklist del Agente
- [ ] ¿He rastreado todas las referencias reales de esta pieza en el repositorio?
- [ ] ¿Seguí el hilo hasta la UI, controlador o punto de entrada?
- [ ] ¿Identifiqué dependencias `downstream` que quedarían huérfanas?
- [ ] ¿Este bloque sigue siendo indispensable hoy o es residuo heredado?
- [ ] ¿Puedo reemplazar muchas líneas viejas por una integración nativa o borrado directo?
- [ ] ¿He propuesto eliminar el archivo o módulo entero si el grafo de dependencias lo permite?
- [ ] ¿Mi respuesta empezó con `[Análisis de Dependencias y Deuda]`?

## Errores Comunes a Evitar
- Parchar el síntoma cuando lo correcto es borrar el flujo entero.
- Conservar capas intermedias por costumbre arquitectónica.
- Declarar una pieza como crítica sin rastrear dependencias reales.
- Dejar aliases, imports, loaders o helpers huérfanos tras una simplificación.
- Reescribir mucho cuando bastaba con eliminar código muerto.
