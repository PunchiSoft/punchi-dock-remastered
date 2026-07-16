# Scripts de empaquetado y prueba

## Comando recomendado

```bash
scripts/empaquetar-plasmoid.sh
```

Detecta Fedora o Debian mediante `/etc/os-release`, selecciona el ejecutable de `qmllint` y el baseline correspondientes, y genera un artefacto con distribución, versión y arquitectura en el nombre.

| Sistema detectado | Artefacto esperado |
|---|---|
| Fedora 44 `x86_64` | `dist/punchi-dock-remastered-<version>-fedora44-x86_64.plasmoid` |
| Debian 13 `x86_64` | `dist/punchi-dock-remastered-<version>-debian13-x86_64.plasmoid` |

## Selección explícita

Estos comandos están destinados principalmente a automatización y diagnóstico:

```bash
scripts/build-fedora-package.sh
scripts/build-debian-package.sh
```

Cada uno rechaza ejecutarse en la distribución equivocada. No son scripts de compilación cruzada.

En Debian, los objetos de compilación se guardan por defecto en `~/.cache/punchi-dock-remastered/debian<versión>-<arquitectura>`. Esto evita problemas de timestamps y rendimiento cuando el repositorio está montado mediante una carpeta compartida de VirtualBox. El `.plasmoid` final continúa apareciendo en `dist/`.

## Prueba local

```bash
scripts/probar-plasmoid.sh
```

Genera un artefacto como `dist/punchi-dock-remastered-0.8.8-fedora44-x86_64-local-test.plasmoid`, verifica su instalación para el usuario actual y reinicia Plasma Shell. En sistemas que exponen `plasma-plasmashell.service` usa el servicio systemd de usuario; si el servicio conserva el proceso anterior, fuerza primero el cierre mediante KDE y vuelve a iniciar el servicio. En los demás sistemas conserva el control mediante `kquitapp6` y `kstart`. El script muestra los PID anterior y posterior y solo declara éxito cuando confirma un proceso nuevo. El sufijo `local-test` distingue este paquete temporal de un artefacto publicable.

## Validación limpia

```bash
scripts/validar-empaquetado-limpio.sh
```

Reconstruye desde una copia temporal limpia y verifica lint, CTest, contenido y ZIP. No instala el plasmoide.

## Regla de seguridad

Instala únicamente el artefacto cuyo nombre coincide con el sistema donde fue compilado. El módulo QML nativo enlaza bibliotecas Qt y KDE del host y no es un binario universal.

Ningún script vigente genera `dist/punchi-dock-remastered.plasmoid` sin una etiqueta de plataforma.
