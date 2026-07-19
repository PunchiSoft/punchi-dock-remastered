# Scripts de empaquetado y prueba

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

## Comando recomendado

```bash
scripts/empaquetar-plasmoid.sh
```

Detecta Fedora, Debian o Kubuntu mediante `/etc/os-release`, selecciona el
ejecutable de `qmllint` y el baseline correspondientes, y genera un artefacto
con distribución, versión y arquitectura en el nombre.

Fedora y Debian conservan sus perfiles validados. Kubuntu dispone de un perfil
de compilación local validado en Plasma 6.6.4: prepara una instalación limpia,
compila el módulo contra las bibliotecas anfitrionas, instala el paquete y permite
su prueba funcional. No es un binario universal ni reemplaza el objetivo
principal de publicación Fedora.

| Sistema detectado | Artefacto esperado |
|---|---|
| Fedora 44 `x86_64` | `dist/punchi-dock-remastered-<version>-fedora44-x86_64.plasmoid` |
| Debian 13 `x86_64` | `dist/punchi-dock-remastered-<version>-debian13-x86_64.plasmoid` |
| Kubuntu con Plasma 6 `x86_64` | `dist/punchi-dock-remastered-<version>-kubuntu<version>-plasma<version>-x86_64.plasmoid` |

## Selección explícita

Estos comandos están destinados principalmente a automatización y diagnóstico:

```bash
scripts/build-fedora-package.sh
scripts/build-debian-package.sh
scripts/build-kubuntu-package.sh
```

Cada uno rechaza ejecutarse en la distribución equivocada. No son scripts de compilación cruzada.

En Debian y Kubuntu, los objetos de compilación se guardan por defecto en
`~/.cache/punchi-dock-remastered/`. Esto evita problemas de timestamps y
rendimiento cuando el repositorio está montado mediante una carpeta compartida
de VirtualBox. El `.plasmoid` final continúa apareciendo en `dist/`.

Kubuntu mantiene un baseline de `qmllint` propio en esa caché. La primera
ejecución de prueba local lo registra automáticamente para la combinación
concreta de Kubuntu, Plasma y Qt; las siguientes ejecuciones rechazan aumentos
de advertencias. Ese baseline local sirve para diagnóstico; la validación de
Kubuntu corresponde al flujo de compilación nativa, no a reutilizar paquetes de
otras distribuciones.

## Prueba local

```bash
scripts/probar-plasmoid.sh
```

Genera un artefacto como `dist/punchi-dock-remastered-0.8.9-fedora44-x86_64-local-test.plasmoid`, verifica su instalación para el usuario actual y reinicia Plasma Shell. En sistemas que exponen `plasma-plasmashell.service` usa el servicio systemd de usuario; si el servicio conserva el proceso anterior, fuerza primero el cierre mediante KDE y vuelve a iniciar el servicio. En los demás sistemas conserva el control mediante `kquitapp6` y `kstart`. El script muestra los PID anterior y posterior y solo declara éxito cuando confirma un proceso nuevo. El sufijo `local-test` distingue este paquete temporal de un artefacto publicable.

En Kubuntu, el mismo comando compila primero un artefacto etiquetado con la
versión local de Plasma. No deben reutilizarse paquetes Debian o Fedora.

## Preparar una instalación limpia de Kubuntu

Desde la raíz del repositorio, ejecutar como el usuario normal de Plasma:

```bash
Scripts/setup_kubuntu_build.py
```

El programa actualiza APT, verifica e instala las dependencias oficiales y
genera el artefacto Kubuntu sin instalarlo. Solicita `sudo` únicamente para APT;
no debe ejecutarse anteponiendo `sudo` al programa completo.

Opciones principales:

```bash
# Instalar dependencias y empaquetar sin preguntas de APT
Scripts/setup_kubuntu_build.py --yes

# Preparar, empaquetar, instalar y reiniciar Plasma para probarlo
Scripts/setup_kubuntu_build.py --yes --local-test

# Instalar y comprobar dependencias sin compilar
Scripts/setup_kubuntu_build.py --dependencies-only

# Mostrar las operaciones sin modificar el sistema
Scripts/setup_kubuntu_build.py --dry-run
```

Si un paquete no aparece en los repositorios configurados, el proceso se
detiene y muestra la lista. No se añaden PPAs ni se mezclan versiones de Qt/KDE.

## Validación limpia

```bash
scripts/validar-empaquetado-limpio.sh
```

Reconstruye desde una copia temporal limpia y verifica lint, CTest, contenido y ZIP. No instala el plasmoide.

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

Instala únicamente el artefacto cuyo nombre coincide con el sistema donde fue compilado. El módulo QML nativo enlaza bibliotecas Qt y KDE del host y no es un binario universal.

Ningún script vigente genera `dist/punchi-dock-remastered.plasmoid` sin una etiqueta de plataforma.
