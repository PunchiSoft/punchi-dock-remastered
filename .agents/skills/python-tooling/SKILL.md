---
name: python-tooling
description: Activa esta skill cuando se solicite automatización, creación de scripts auxiliares, despliegue local, formateadores de código, linters, o herramientas de validación. Solo aplica para herramientas fuera del ciclo de ejecución principal del plasmoide.
---

# Python Tooling Skill

## Instrucciones Detalladas
Python se utiliza en este proyecto única y exclusivamente para crear herramientas auxiliares que mejoren la experiencia del desarrollador, automaticen tareas y realicen pruebas (fuera del código del plasmoide).
1. Ubicar cada script donde el proyecto ya mantiene ese tipo de herramienta, según la política de `AGENTS.md`: `scripts-dev/` para mantenimiento, validaciones y auditores, y `scripts-user/` para el flujo de usuario. No crear una tercera familia de scripts ni mover herramientas sin una decisión arquitectónica explícita.
2. Utiliza bibliotecas estándar de Python siempre que sea posible para evitar dependencias innecesarias en los entornos de desarrollo.
3. Si se requieren dependencias, decláralas junto al script siguiendo la convención documentada en el README de esa carpeta.
4. Los scripts deben aceptar argumentos a través de CLI (usa `argparse`) y proveer ayuda detallada (`--help`).

## Checklist
- [ ] ¿El script resuelve una tarea administrativa, de despliegue o prueba externa?
- [ ] ¿El script está en la carpeta que corresponde a su tipo, sin crear ubicaciones nuevas?
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

## Herramienta mantenida de KConfig

Al modificar `scripts-dev/audit-plasma-config.py`:

- leer `scripts-dev/README.md` y conservar sus salidas de texto y JSON, codigos de
  salida y limite de evidencia;
- mantener biblioteca estandar, rutas relativas al proyecto y ausencia de
  efectos laterales sobre la configuracion personal;
- actualizar `tests/plasma_config_auditor_test.py` para cada diagnostico o
  excepcion nueva;
- ejecutar la unidad `plasma_config_auditor_test` y el gate del arbol real
  `plasma_config_audit`;
- no ampliar `RUNTIME_ONLY_KEYS` ni `EXPECTED_MULTI_PAGE_OWNERS` para hacer pasar
  un fallo sin una decision arquitectonica confirmada.
