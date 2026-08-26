# Scripts de instalación para usuarios

[English](README.md) | [Español](README.es.md)

Esta carpeta contiene el flujo para una persona normal. Al ejecutarlo sin argumentos se abre el asistente interactivo:

```bash
./scripts-user/setup.sh
```

El menú interactivo permite:
- **Compilar e instalar localmente** (con confirmación opcional para reiniciar Plasma Shell);
- **Crear solo el paquete `.plasmoid`** (sin instalar);
- **Instalar un paquete existente** desde `dist/` o una ruta personalizada;
- **Desinstalar** el plasmoide limpiamente del escritorio;
- **Reiniciar Plasma Shell** bajo demanda.

Configura CMake con `BUILD_TESTING=OFF` y no ejecuta `qmllint` ni CTest. Esas comprobaciones pertenecen al flujo separado para desarrolladores bajo `scripts-dev/`.

## Opciones CLI

También se puede ejecutar sin interacción mediante flags:

```bash
# Compilar e instalar localmente sin reiniciar Plasma Shell
./scripts-user/setup.sh --install --no-restart

# Crear solo el paquete .plasmoid local
./scripts-user/setup.sh --build-only

# Desinstalar el plasmoide del escritorio actual
./scripts-user/setup.sh --uninstall
```

Solo se puede elegir una acción principal por ejecución. Los modificadores
como `--no-restart` y `--yes` pueden combinarse con una acción aplicable. El
asistente detecta automáticamente `es`, `de` y `pt_BR` desde el locale del
sistema, con inglés como respaldo. Se puede forzar un idioma con
`--lang es`, `--lang de`, `--lang pt_BR` o `--lang en`. Las traducciones se
mantienen en los catálogos PO y no se duplican dentro del código Bash.

El paquete generado utiliza el sufijo `-local-build.plasmoid`. Está compilado para el sistema actual y no debe publicarse como artefacto universal oficial.

Para instalar un paquete existente directamente:

```bash
./scripts-user/setup.sh ruta/al/paquete.plasmoid
# o
./scripts-user/setup-universal.sh [--no-restart] ruta/al/paquete.plasmoid
```

Instalar un paquete existente, desinstalar o reiniciar no requiere la toolchain
de compilación C++. Cada acción comprueba únicamente los comandos que utiliza.

## Archivos internos

- `setup.sh`: comando público de compilación, instalación y reinicio.
- `setup-universal.sh`: instalador de un paquete existente.
- `lib/setup-localization.sh`: detección de locale e integración con gettext.
- `lib/plasma-shell-control.sh`: reinicio compartido y verificado de Plasma Shell.
- `lib/`: implementaciones compartidas de empaquetado e instalación; el usuario
  no debe ejecutarlas directamente.

Quienes desarrollan el proyecto deben usar los
[scripts de desarrollo](../scripts-dev/README.es.md).
