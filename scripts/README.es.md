# Scripts de empaquetado y prueba

[English](README.md) | [Español](README.es.md)

## Comprobar el entorno

```bash
scripts/check-build-environment.sh
```

Este comando no instala ni reemplaza paquetes. Informa la distribución,
arquitectura y versiones locales de Plasma, CMake y `qmllint`, y clasifica el
perfil de lint encontrado:

| Versión de `qmllint` | Tratamiento |
|---|---|
| Qt 6.11 | Perfil principal de desarrollo y validación. |
| Qt 6.8 | Perfil de compatibilidad con baseline separado; puede producir diagnósticos distintos. |
| Otra versión Qt 6 | Perfil aún no calibrado; deben ejecutarse las pruebas y revisarse sus diagnósticos antes de crear un baseline propio. |

El baseline de `qmllint` mide los diagnósticos de una combinación concreta de
herramienta y plataforma. No define la versión mínima de ejecución del
plasmoide. Los usuarios que instalan un `.plasmoid` precompilado para su sistema
no necesitan `qmllint`.

Para compilar, deben usarse los paquetes Qt 6, KF6 y Plasma proporcionados por
la misma distribución. No se debe reemplazar Qt del sistema por una instalación
independiente de Qt 6.11 para silenciar el lint: el módulo QML nativo necesita
una pila de bibliotecas coherente.

## Comandos recomendados

```bash
scripts/setup-fedora.sh
scripts/setup-debian13.sh
scripts/setup-debian14-testing.sh
scripts/setup-kubuntu.sh
```

Cada comando valida su distribución, detecta las dependencias instaladas y usa
el ejecutable de `qmllint` y baseline correspondientes. Los motores comunes de
compilación e instalación permanecen internos en `scripts/lib/`.

Fedora y Debian conservan sus perfiles validados. Kubuntu dispone de un perfil
de compilación local validado en Plasma 6.6.4: prepara una instalación limpia,
compila el módulo contra las bibliotecas anfitrionas, instala el paquete y
permite su prueba funcional. No es un binario universal ni reemplaza el objetivo
principal de publicación Fedora.

| Sistema detectado | Artefacto esperado |
|---|---|
| Fedora 44 `x86_64` | `dist/punchi-dock-remastered-<version>-fedora44-x86_64.plasmoid` |
| Debian 13 `x86_64` | `dist/punchi-dock-remastered-<version>-debian13-x86_64.plasmoid` |
| Kubuntu con Plasma 6 `x86_64` | `dist/punchi-dock-remastered-<version>-kubuntu<version>-plasma<version>-x86_64.plasmoid` |

## Debian 13

El perfil estable validado para Debian 13/trixie se ejecuta con:

```bash
scripts/setup-debian13.sh
```

Sin opciones genera el artefacto publicable `debian13`. Para instalarlo y
reiniciar Plasma durante una prueba local:

```bash
scripts/setup-debian13.sh --local-test
```

El script rechaza Debian 14/testing y detecta mediante `dpkg-query` si las
dependencias ya están instaladas. `--dependencies-only`, `--skip-apt` y
`--dry-run` permiten limitar explícitamente el flujo.

En Debian y Kubuntu, los objetos de compilación se guardan por defecto en
`~/.cache/punchi-dock-remastered/`. Esto evita problemas de marcas de tiempo y
rendimiento cuando el repositorio está montado mediante una carpeta compartida
de VirtualBox. El `.plasmoid` final continúa apareciendo en `dist/`.

Kubuntu mantiene un baseline de `qmllint` propio en esa caché. La primera
ejecución de prueba local lo registra automáticamente para la combinación
concreta de Kubuntu, Plasma y Qt; las siguientes ejecuciones rechazan aumentos
de advertencias. Ese baseline local sirve para diagnóstico; la validación de
Kubuntu corresponde al flujo de compilación nativa, no a reutilizar paquetes de
otras distribuciones.

## Preparar Debian 14/testing experimental

Para probar desde un Live CD o instalación limpia de Debian 14/testing `forky`,
usar el wrapper dedicado:

```bash
scripts/setup-debian14-testing.sh --yes
```

El script detecta las dependencias ya instaladas mediante `dpkg-query` y usa APT
únicamente para los paquetes faltantes. Sin opciones registra el baseline local
de `qmllint` si hace falta y crea el artefacto publicable `debian14testing` sin
instalarlo. Debe ejecutarse como usuario normal de Plasma; solo solicita `sudo`
para APT. No añade repositorios externos ni reemplaza Qt/KDE del sistema.

Opciones útiles:

```bash
scripts/setup-debian14-testing.sh --dry-run
scripts/setup-debian14-testing.sh --skip-apt
scripts/setup-debian14-testing.sh --yes --local-test
scripts/setup-debian14-testing.sh --yes --local-test --skip-restart
```

## Prueba local Fedora

```bash
scripts/setup-fedora.sh --local-test
```

Genera un artefacto como
`dist/punchi-dock-remastered-0.9.0-fedora44-x86_64-local-test.plasmoid`, verifica
su instalación para el usuario actual y reinicia Plasma Shell. En sistemas que
exponen `plasma-plasmashell.service` usa el servicio systemd de usuario; si el
servicio conserva el proceso anterior, solicita primero el cierre mediante KDE
y vuelve a iniciar el servicio. En los demás sistemas conserva el control
mediante `kquitapp6` y `kstart`. El script muestra los PID anterior y posterior
y solo declara éxito cuando confirma un proceso nuevo. El sufijo `local-test`
distingue este paquete temporal de un artefacto publicable.

En Kubuntu, `scripts/setup-kubuntu.sh --local-test` ejecuta el equivalente con
la versión local de Plasma. No deben reutilizarse paquetes Debian o Fedora.

## Preparar una instalación limpia de Kubuntu

Desde la raíz del repositorio, ejecutar como el usuario normal de Plasma:

```bash
scripts/setup-kubuntu.sh
```

El script detecta qué dependencias oficiales faltan, actualiza APT solo cuando
debe instalarlas y genera el artefacto Kubuntu sin instalarlo. Solicita `sudo`
únicamente para APT; no debe ejecutarse anteponiendo `sudo` al script completo.

Opciones principales:

```bash
# Instalar dependencias y empaquetar sin preguntas de APT
scripts/setup-kubuntu.sh --yes

# Preparar, empaquetar, instalar y reiniciar Plasma para probarlo
scripts/setup-kubuntu.sh --yes --local-test

# Instalar y comprobar dependencias sin compilar
scripts/setup-kubuntu.sh --dependencies-only

# Compilar usando dependencias que ya fueron instaladas
scripts/setup-kubuntu.sh --skip-apt

# Mostrar las operaciones sin modificar el sistema
scripts/setup-kubuntu.sh --dry-run
```

Si un paquete no aparece en los repositorios configurados, el proceso se
detiene y muestra la lista. No se añaden PPAs ni se mezclan versiones de Qt/KDE.

## Validación limpia

```bash
scripts/validar-empaquetado-limpio.sh
```

Reconstruye desde una copia temporal limpia y verifica lint, CTest, contenido y
ZIP. No instala el plasmoide.

## Traducciones

```bash
scripts/update-translations.sh
```

Regenera la plantilla POT y fusiona los cambios en todos los catálogos PO. El
código ejecutable conserva el inglés como único idioma fuente; las traducciones
se mantienen exclusivamente en `po/`. El empaquetado rechaza catálogos
incompletos o difusos, los compila y coloca únicamente los MO resultantes bajo
`contents/locale/` dentro del `.plasmoid`, que es la ruta resuelta por el
prefijo de contenidos de KPackage.

## Regla de seguridad

Instala únicamente el artefacto cuyo nombre coincide con el sistema donde fue
compilado. El módulo QML nativo enlaza bibliotecas Qt y KDE del host y no es un
binario universal.

Ningún script vigente genera `dist/punchi-dock-remastered.plasmoid` sin una
etiqueta de plataforma.

## Organización interna

La raíz de `scripts/` conserva wrappers cortos para comandos habituales y
compatibilidad con documentación anterior. Las implementaciones viven en:

- `scripts/distro/`: flujos específicos por distribución.
- `scripts/dev/`: herramientas de desarrollo, diagnóstico y validación.
- `scripts/lib/`: motores y helpers compartidos; no son comandos principales.

No ejecutar archivos generados como `__pycache__`; no forman parte del proyecto.
