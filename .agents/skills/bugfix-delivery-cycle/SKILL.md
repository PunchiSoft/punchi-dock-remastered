---
name: bugfix-delivery-cycle
description: Conducir un error reportado desde la documentacion hasta la pull request en Punchi Dock, siempre en el mismo orden: documentar, preguntar si se procede, crear la rama de trabajo, implementar, validar, interpretar commit y push como aprobacion y abrir el PR con descripcion estructurada. Usar cuando el usuario reporte o pregunte por un error y espere una correccion, o cuando pida convertir ese recorrido en una rutina repetible.
---

# Ciclo de entrega de correcciones

## Objetivo

Evitar que cada correccion cambie de metodo. Esta skill fija un recorrido unico
desde el reporte hasta la pull request, con puntos de decision explicitos para
no implementar de mas, no publicar antes de tiempo y no fusionar sin
autorizacion.

## Cuando usarla

- el usuario reporta un error, una regresion o un comportamiento inesperado;
- el usuario pregunta si algo es un fallo o si hace falta corregirlo;
- el usuario pide que un arreglo llegue a `main` mediante commit, push y PR.

No usarla para funciones nuevas o mejoras: ahi corresponde
`modification-cycle`.

## Senales del usuario

Interpretar literalmente lo que pide, sin adelantar fases:

| Senal | Significado |
|---|---|
| reporte o pregunta | solo diagnostico y documentacion |
| "procede", "hazlo", "corrigelo" | autorizacion para implementar |
| "sigue modificando", "falta", "no funciona" | aun hay correcciones; no es aprobacion |
| "commit y push" | aprobacion explicita de la solucion implementada |
| "fusiona", "merge" | unica autorizacion valida para fusionar |

Un commit o push pedido antes de la validacion no convierte el cambio en
aprobado: primero se valida, y si algo queda pendiente se informa antes de
publicar.

## Orden obligatorio

### 1. Escuchar y acotar el reporte

- registrar el comportamiento observado, el esperado y el entorno;
- distinguir bug confirmado, limitacion conocida, decision de producto y
  comportamiento ajeno al proyecto;
- no aceptar el diagnostico del reporte como si fuera una causa confirmada.

### 2. Documentar antes de tocar codigo

- activar `review-cycle` y crear o actualizar el documento en
  `docs/revisiones/` con la plantilla vigente;
- registrar contexto, observaciones, hallazgos, plan y pendientes;
- conservar lo ya intentado para no repetir soluciones descartadas.

### 3. Preguntar si se procede

Si falta autorizacion, alcance o evidencia, preguntar con `ask_user` antes de
implementar. Preguntas utiles, una sola vez y concretas:

- alcance exacto del arreglo;
- modo o superficie afectada;
- si el aviso o texto visible debe cambiar;
- si se autoriza instalar y reiniciar Plasma para validar.

El silencio no autoriza. Si el usuario ya dijo "procede", no volver a
preguntar lo mismo.

### 4. Comprobar el entorno antes de implementar

- verificar version instalada, rama actual y estado de Git;
- comparar lo instalado con el arbol cuando el reporte venga de una prueba real;
- confirmar que el fallo existe en el codigo actual y no solo en una version
  antigua.

### 5. Crear la rama de trabajo

- hacerlo siempre antes de modificar, nunca sobre `main`;
- nombre segun el tipo: `fix/<descriptor>` para correcciones;
- una rama por asunto; no mezclar correcciones no solicitadas.

### 6. Implementar el cambio minimo

- aplicar el cambio mas pequeño que resuelva el problema;
- añadir o ajustar la prueba que distingue el fallo de la correccion;
- si la prueba no falla sin el arreglo, la evidencia no es suficiente;
- no debilitar pruebas existentes ni tocar `tests/` protegido sin autorizacion.

### 7. Validar de forma proporcional

- ejecutar la suite y los gates que apliquen al dominio afectado;
- registrar resultados reales y sus limites;
- no afirmar validacion en Plasma si solo hubo pruebas offscreen;
- si la validacion requiere instalar o reiniciar Plasma, pedir autorizacion.

### 8. Interpretar la respuesta del usuario

- si pide seguir modificando, volver al paso 6 y no commitear;
- si pide commit y push, tratar la solucion como aprobada y continuar;
- si detecta un problema nuevo, documentarlo como hallazgo aparte antes de
  ampliar el alcance.

### 9. Preparar el commit

- revisar `git status` y preparar solo rutas concretas con `git add --`;
- revisar el diff preparado antes de confirmar;
- mensaje en ingles con formato `fix(scope): resumen`;
- incluir el trailer `Co-authored-by` del proyecto;
- sincronizar la version incremental y sus tres campos canonicos cuando
  corresponda a un respaldo Git;
- no incluir documentacion local ignorada, artefactos, logs ni binarios.

### 10. Publicar la rama

- `git push -u origin <rama>`;
- confirmar que la rama remota apunta al commit esperado.

### 11. Abrir la pull request

- crear la PR contra `main` con `gh pr create` inmediatamente despues del push,
  salvo que el usuario pida lo contrario;
- titulo igual al commit principal;
- cuerpo obligatorio en ingles, breve y estructurado;
- asignar solo etiquetas que ya existan en el repositorio; no inventarlas;
- no crear tags, releases ni fusionar sin pedido explicito.

Cuerpo minimo de la PR:

```markdown
## Summary
<Causa raiz y efecto observable del arreglo.>

## Changes
- <Cambio funcional y archivo principal.>
- <Prueba de regresion añadida o ajustada.>

## Validation
| Check | Result |
|---|---|
| Full CTest | <n>/<n> passed |
| qmllint baseline | <metricas> |
| ki18n | <estado> |
| Security preflight | <estado> |
| Test integrity | <estado> |

## References
- Fixes #<issue> (solo si existe y corresponde)

## Pending
- <Validacion en Plasma real, instalacion o seguimiento.>
```

### 12. Verificar la PR y resolver conflictos

- comprobar `mergeable` y `mergeStateStatus`;
- si hay conflicto, rebasar sobre `origin/main`, no crear un commit de merge
  desde la rama;
- resolver conservando el comportamiento ya validado;
- volver a verificar contenido, versiones, integridad y pruebas dirigidas;
- publicar con `--force-with-lease`, nunca con `--force` simple.

### 13. Cerrar el ciclo

- actualizar la revision y la bitacora con la evidencia final;
- informar la URL de la PR y su estado;
- eliminar ramas ya fusionadas solo con autorizacion o cuando el usuario lo
  haya pedido;
- no borrar ramas con commits sin integrar.

## Reglas de seguridad y alcance

- no instalar, empaquetar ni reiniciar servicios sin autorizacion;
- no modificar `tests/` ni sus gates sin autorizacion explicita;
- no publicar secretos, rutas personales ni datos del entorno;
- no ampliar el alcance con refactorizaciones no pedidas;
- si falta evidencia para decidir, detenerse y preguntar.

## Checklist de salida

- [ ] El reporte esta documentado y clasificado.
- [ ] La implementacion fue autorizada antes de tocar codigo.
- [ ] La rama se creo desde `main` antes del primer cambio.
- [ ] La prueba falla sin el arreglo y pasa con el.
- [ ] La validacion aplicable se ejecuto y sus limites estan declarados.
- [ ] Commit y push solo se hicieron tras la aprobacion del usuario.
- [ ] La PR tiene descripcion estructurada y referencia al issue cuando existe.
- [ ] La PR es fusionable o el conflicto se resolvio y se documento.
- [ ] La revision y la bitacora reflejan el resultado final.
