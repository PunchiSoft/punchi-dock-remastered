---
name: js-plasma-backend
description: Activa esta skill al escribir, modificar o estructurar lógica de negocio, manejo de estado o llamadas a la API de KDE Plasma en JavaScript. Utilízala cuando el usuario pida gestionar datos, ventanas, procesos o modelos lógicos del plasmoide.
---

# JavaScript Plasma Backend Skill

## Instrucciones Detalladas
Esta skill abarca la lógica de negocio del plasmoide. En el ecosistema de Plasma, el código JS se usa para mantener el estado, comunicarse con servicios del sistema y alimentar de datos a la interfaz QML.
1. Crea archivos `.js` independientes (en un directorio como `js/` o `logic/`) y exprótalos como librerías (usando `.pragma library` si el estado debe ser compartido, o instanciado por componente).
2. Estructura el código en controladores/modelos. Evita manipular la UI directamente desde el JS.
3. El código JS debe actualizar propiedades o emitir señales que QML consuma reactivamente.
4. Interactúa con los DataEngines de Plasma u otros servicios del sistema de forma asíncrona para no bloquear el hilo de la UI.

## Checklist
- [ ] ¿El archivo JS está completamente desacoplado de IDs específicos de la interfaz QML?
- [ ] ¿El estado se gestiona de forma centralizada o predecible?
- [ ] ¿Se utiliza `.pragma library` correctamente si el estado debe persistir entre múltiples componentes?
- [ ] ¿Las operaciones pesadas se manejan de manera no bloqueante?

## Buenas Prácticas
- Usar el patrón MVC o similar, donde JS es el Controlador/Modelo y QML es la Vista.
- Documentar funciones JS con JSDoc.
- Minimizar el estado global siempre que sea posible.

## Errores Comunes
- **Manipular la UI desde JS**: Usar referencias directas a objetos visuales desde el archivo JS (ej. `miBoton.text = ...`) rompe la encapsulación. JS debe devolver datos y QML debe usar binding (`text: backend.textoBoton`).
- **Bloquear el hilo principal**: Ejecutar bucles pesados en JS congela la shell de Plasma.
- **No gestionar la destrucción**: Fugas de memoria al no limpiar listeners o timers en JS cuando el componente QML se destruye.

## Criterios de Aceptación
- La lógica de JS opera de manera independiente y puede ser probada o importada sin fallos de dependencia circular.
- La interfaz de QML refleja los cambios del backend reactivamente usando bindings de propiedades y señales.
