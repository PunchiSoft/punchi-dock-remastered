---
name: preflight-security-review
description: Revisar preventivamente seguridad, privacidad y alcance antes de cualquier modificación, commit, empaquetado, instalación o push de Punchi Dock. Usar para detectar secretos, datos personales, telemetría, rutas o artefactos locales, permisos, red, comandos peligrosos y archivos inesperados antes de escribir o publicar cambios; repetir la revisión antes de subir a GitHub.
---

# Revisión preventiva de seguridad

## Objetivo

Impedir fugas de información y cambios fuera de alcance. Ejecutar un control antes de escribir y otro antes de commit, empaquetado o push.

## Preflight obligatorio

1. Leer `AGENTS.md`, instrucciones aplicables y `git status --short`.
2. Delimitar archivos y comportamiento autorizados por el usuario.
3. Inspeccionar consumidores, datos y comandos relacionados antes de editar.
4. Clasificar cada riesgo como `seguro`, `requiere mitigación` o `requiere confirmación`.
5. No escribir mientras exista un riesgo material sin resolver.

## Controles de privacidad y seguridad

Buscar explícitamente:

- secretos, tokens, contraseñas, cookies, claves SSH/GPG, `.env` y credenciales;
- nombres personales, correos, rutas de usuario, hostname, IP, UUID de equipo, perfiles, historiales, capturas o metadata privada;
- telemetría, analítica, estadísticas de uso, crash reporting o envío de logs no autorizados;
- endpoints, descargas, sockets y cualquier acceso nuevo a red;
- `sudo`, gestores de paquetes, cambios de permisos, servicios, procesos o acceso a dispositivos;
- comandos construidos con entradas no confiables, expansión de shell o rutas sin validar;
- binarios, cachés, catálogos compilados, logs y otros artefactos generados;
- archivos añadidos, borrados o modificados fuera del alcance confirmado.

No asumir que un dato deja de ser sensible por estar en documentación, una prueba, un log, una captura o un archivo ignorado.

## Política local del proyecto

Mantener fuera de Git y GitHub:

- `docs/`, `bitacora/`, `kde-sdk/`, `backup/` y `scratch/`;
- `build/`, `dist/`, logs, paquetes y binarios generados;
- `__pycache__/`, `*.pyc`, módulos compilados y `messages.mo` en la raíz.

Permitir `tests/` en Git porque valida la fuente, pero comprobar que:

- no contenga información del entorno personal;
- no requiera red, privilegios ni escrituras fuera de temporales salvo autorización;
- siga siendo opcional para el runtime mediante `BUILD_TESTING`;
- no se incluya dentro del `.plasmoid` instalado.

Antes de añadir una ruta ignorada con `git add -f`, detenerse y pedir confirmación explícita.

## Procesos, red y telemetría

- No introducir telemetría ni estadísticas salientes sin solicitud y consentimiento explícitos.
- No ejecutar instalaciones, elevación de privilegios, reinicios o escrituras externas como efecto de una validación.
- Preferir comprobaciones locales, deterministas y de solo lectura.
- Tratar importaciones de scripts como ejecución de código; comprobar su guardia principal y efectos al importar.
- Mantener Python y herramientas auxiliares fuera del runtime del plasmoide.

## Postflight antes de publicar

1. Revisar `git status --short`, `git diff --check` y el diff completo.
2. Revisar por separado `git diff --cached` antes de cada commit o push.
3. Confirmar que no haya archivos locales forzados, binarios, secretos ni datos personales.
4. Verificar `.gitignore`, `.kpackageignore` y el contenido real del paquete cuando aplique.
5. Ejecutar validación proporcional sin afirmar pruebas de runtime no realizadas.
6. Confirmar que el commit contiene solo el alcance autorizado.
7. No hacer push si aparece una anomalía; informar al usuario y solicitar decisión.

## Condiciones de parada

Detener la modificación y consultar al usuario ante:

- posible secreto, dato personal o información del entorno;
- telemetría, red, privilegios o acceso a dispositivos nuevos;
- eliminación material o reescritura de historial;
- archivo ignorado que se pretende forzar a Git;
- cambio fuera del alcance original;
- diferencia entre lo validado localmente y lo que formará el commit o paquete.

## Salida esperada

Comunicar de forma breve:

- alcance autorizado;
- riesgos encontrados y mitigaciones;
- archivos locales que permanecerán fuera de Git;
- validaciones realizadas y sus límites;
- decisión `apto para modificar`, `apto para commit/push` o `detenido a la espera del usuario`.
