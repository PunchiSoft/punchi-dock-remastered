---
name: kde-official-applet-adaptation
description: Adaptar o corregir funciones de Punchi Dock basándose en el contrato de un applet oficial de KDE Plasma. Usar cuando el usuario pida replicar, comparar o seguir cómo lo hace el applet oficial; no usar para consultas generales del SDK sin implementación o diagnóstico de equivalencia.
---

# Adaptación de applets oficiales de KDE

## Objetivo

Convertir el comportamiento comprobado de un applet oficial de Plasma en una
adaptación modular de Punchi Dock, sin inferir APIs, copiar implementaciones
completas ni confundir una similitud visual con equivalencia funcional.

Esta skill complementa a la skill canónica `kde-sdk-reference`: aquella localiza
y clasifica la API; esta establece cómo comparar, adaptar y validar el contrato
encontrado. El alias `sdk-reference` solo redirige a `kde-sdk-reference`.

## Activación y límites

Usar cuando una modificación o corrección requiera:

- "hacerlo como el applet oficial";
- replicar un control, modelo, acción o estado de Plasma;
- comparar una integración de Punchi con su equivalente upstream;
- corregir una divergencia causada por roles, señales, rangos o ciclo de vida.

No usar para una búsqueda KDE puramente documental ni para copiar la apariencia
completa de otro applet. La skill no autoriza instalar el plasmoide, reiniciar
Plasma, descargar dependencias ni publicar cambios.

## Evidencia oficial

Aplicar `kde-sdk-reference` y reunir evidencia en este orden:

1. SDK local y pruebas upstream incluidas en `kde-sdk/`;
2. metadatos y tipos instalados, como `*.qmltypes`, interfaces D-Bus y
   documentación de la versión efectiva;
3. fuente oficial del componente instalada o disponible localmente;
4. repositorios o documentación oficiales de KDE cuando lo anterior sea
   insuficiente.

Si el SDK local no contiene el applet, registrarlo expresamente; no presentar
otra fuente como si perteneciera a `kde-sdk/`. Distinguir API pública, privada,
experimental y detalle interno. Contrastar la versión observada con Plasma 6.0,
Qt 6.6 y KF 6.0 declarados por el proyecto; si no se puede probar
compatibilidad, proporcionar fallback o detener la decisión.

## Matriz de equivalencia obligatoria

Antes de escribir código, registrar en el documento activo de revisión o
modificación una comparación con estas columnas:

| Aspecto | Evidencia oficial | Adaptación Punchi | Divergencia deliberada |
|---|---|---|---|
| Tipo e import | Símbolo y módulo exactos | Adaptador consumidor | Motivo, si difiere |
| Modelo y roles | Modelo, roles y tipos adjuntos | Lectura equivalente | Selección o resumen |
| Reactividad | Señales y actualización inicial | Conexiones equivalentes | Señales omitidas |
| Valores | Unidad, rango y conversión | Representación Punchi | Conversión necesaria |
| Acción | Método y argumentos | Señal/controlador/servicio | Fallback |
| Estados | Disponible, vacío y error | Estado visible y degradación | Límite conocido |

Añadir ciclo de vida, OSD, permisos, foco o accesibilidad cuando influyan en el
comportamiento. Una captura sólo aporta evidencia visual; no demuestra el
contrato de datos ni la integración.

## Adaptación

1. Reproducir el contrato observable mínimo, no la implementación completa.
2. Conservar el flujo `UI → controlador → servicio → adaptador → KDE`; la vista
   no debe ejecutar procesos ni interpretar modelos complejos.
3. Encapsular cada dominio oficial en su propio adaptador. Una API privada u
   opcional debe cargarse de forma diferida y nunca convertirse en dependencia
   global de `main.qml`.
4. Replicar exactamente nombres de roles, propiedades adjuntas, señales,
   actualización inicial, unidades y argumentos cuando formen parte del
   contrato. No simplificarlos por semejanza nominal.
5. Mantener un estado degradado útil y acceso al KCM oficial cuando el proveedor
   falte, la versión no sea compatible o el modelo esté vacío.
6. Preservar la identidad visual, métricas, tema y accesibilidad de Punchi Dock.
   Copiar estructura visual upstream sólo si el usuario lo pide expresamente.
7. No copiar bloques extensos de código oficial. Reutilizar APIs y patrones,
   conservar las licencias aplicables y documentar la procedencia técnica.

Toda divergencia respecto del applet oficial debe ser deliberada, pequeña y
registrada. Si cambia el comportamiento que el usuario espera replicar, pedir
decisión antes de implementarla.

## Validación proporcional

Aplicar `testing` y, si el componente es alcanzable desde la representación,
`qml-runtime-load-review`.

- crear una regresión que falle con el contrato incorrecto observado;
- ejecutar el tipo o modelo real en una prueba QML cuando roles adjuntos,
  señales o ciclo de vida sean la causa;
- añadir un contrato estático negativo sólo como complemento para impedir que
  reaparezca una forma conocida como inválida;
- cargar el applet completo cuando la integración atraviese `Loader`, imports
  privados o el grafo principal;
- convertir warnings QML inesperados en fallos;
- validar en Plasma real cuando el resultado dependa de D-Bus, PowerDevil,
  NetworkManager, PipeWire, KWin, pantallas o hardware.

Un bus aislado sin el proveedor oficial sólo demuestra degradación segura. No
permite afirmar que el control funciona con el servicio real. Correlacionar el
primer error del journal con el archivo y símbolo adaptados antes de atribuir el
fallo al hardware o declarar una API no disponible.

## Coordinación

- usar `review-cycle` para un bug reportado y `modification-cycle` para una
  capacidad nueva;
- usar la skill de dominio correspondiente para UI, controladores, servicios o
  backend JavaScript;
- activar `ki18n-localization` si cambia texto visible;
- ejecutar `preflight-security-review` antes y después de modificar;
- registrar en revisión y bitácora las fuentes oficiales, divergencias,
  validación realizada y comprobaciones pendientes.

## Criterios de aceptación

- la matriz demuestra qué contrato oficial se reproduce y qué no;
- cada API usada tiene fuente, versión y clasificación conocidas;
- la integración permanece modular y falla de forma segura;
- existe una regresión que protege el detalle contractual relevante;
- los gates globales pasan sin elevar baselines;
- cualquier comprobación pendiente en Plasma real queda declarada con una
  acción concreta para el usuario.
