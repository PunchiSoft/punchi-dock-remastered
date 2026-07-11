---
name: python-tooling
description: Activa esta skill cuando se solicite automatización, creación de scripts auxiliares, despliegue local, formateadores de código, linters, o herramientas de validación. Solo aplica para herramientas fuera del ciclo de ejecución principal del plasmoide.
---

# Python Tooling Skill

## Instrucciones Detalladas
Python se utiliza en este proyecto única y exclusivamente para crear herramientas auxiliares que mejoren la experiencia del desarrollador, automaticen tareas y realicen pruebas (fuera del código del plasmoide).
1. Todos los scripts deben ir en la carpeta `Scripts/`.
2. Utiliza bibliotecas estándar de Python siempre que sea posible para evitar dependencias innecesarias en los entornos de desarrollo.
3. Si se requieren dependencias, crea un archivo `requirements.txt` dentro de `Scripts/`.
4. Los scripts deben aceptar argumentos a través de CLI (usa `argparse`) y proveer ayuda detallada (`--help`).

## Checklist
- [ ] ¿El script resuelve una tarea administrativa, de despliegue o prueba externa?
- [ ] ¿El script se encuentra en la carpeta `Scripts/`?
- [ ] ¿Es ejecutable de forma independiente (`chmod +x` y shebang `#!/usr/bin/env python3`)?
- [ ] ¿Tiene manejo de errores adecuado para evitar fallas silenciosas?

## Buenas Prácticas
- Usar tipado estático (Type Hints) en todas las funciones.
- Añadir docstrings a módulos y funciones.
- Mantener los scripts enfocados en una sola responsabilidad (Unix philosophy).
- Retornar códigos de salida apropiados (0 para éxito, >0 para errores) para que puedan usarse en pipelines de CI/CD.

## Errores Comunes
- **Integrar Python en el plasmoide**: Intentar hacer que el plasmoide de Plasma llame directamente al script Python para su funcionamiento básico. Python es solo para herramientas, no para el runtime del widget.
- **Asumir rutas absolutas**: Siempre construye las rutas relativas al directorio del script usando `pathlib`.

## Criterios de Aceptación
- El script de Python cumple su propósito (ej. instalar el plasmoide localmente) sin fallar y retornando el código de estado correcto.
- No existe código Python que sea indispensable para el funcionamiento principal del widget en un entorno de producción.
