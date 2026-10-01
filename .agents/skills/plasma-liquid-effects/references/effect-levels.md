# Niveles de efecto y criterios de admisión

Detalle operativo de `plasma-liquid-effects`.

## Nivel 1 — líquido simulado

Coste esperado: **BAJO**. Es el nivel preferido para la mayoría de componentes.

Propiedades disponibles sin shaders ni capas offscreen:

| Propiedad | Efecto percibido |
|---|---|
| `scale`, `scaleX`, `scaleY` | hinchazón, presión, rebote contenido |
| `opacity` | aparición, desvanecido, énfasis |
| `radius` | transición entre cuadrado y cápsula |
| `x`, `y`, `transform` | desplazamiento, follow-through |
| sombra y borde del tema | profundidad y separación del fondo |
| highlight del tema | brillo y sensación de material |

Muchas sensaciones de material líquido pueden obtenerse sin shaders:

- presión: `scaleX` sube levemente y `scaleY` baja levemente;
- al liberar, retorno suavizado a 1 con duración corta;
- cápsula que respira: `radius` y `scale` coordinados en menos de tres
  propiedades;
- fusión visual de dos formas contiguas: acercar el radio y solapar el borde
  antes de recurrir a un shader.

## Nivel 2 — Qt Quick Effects y MultiEffect

`MultiEffect` está exportado como `QtQuick.Effects/MultiEffect 6.5`. El mínimo
declarado del proyecto es Qt 6.6, por lo que está disponible en el entorno
objetivo; verificar aun así en cada distribución.

Usos razonables: blur, sombra, máscara, colorización y composición.

Reglas:

- evitar grandes superficies con blur; el coste crece con el área;
- evitar múltiples blur superpuestos sobre la misma superficie;
- reutilizar el efecto cuando varios elementos necesitan el mismo acabado;
- no animar propiedades que obliguen a recalcular el efecto cada fotograma
  (radio de blur, máscara, fuente) si puede animarse la opacidad o la escala del
  resultado;
- no aplicar efectos complejos a todos los delegates del dock.

## Nivel 3 — ShaderEffect

Herramienta especializada, nunca la solución predeterminada.

Casos donde puede estar justificado:

- metaballs y fusión real entre formas;
- campos de distancia con signo;
- distorsión o refracción simulada con desplazamiento;
- morphing entre siluetas distintas.

Antes de introducirlo, comprobar y reportar:

| Punto | Qué debe responderse |
|---|---|
| 1. ¿Podía hacerse con QML normal? | Qué se intentó y por qué no basta |
| 2. Coste de renderizado | Superficie, resolución, número de pases |
| 3. Instancias | Cuántas copias pueden coexistir |
| 4. Qt | Versión mínima y disponibilidad del módulo |
| 5. Plasma | Coherencia con el tema y el estilo |
| 6. Wayland | Comportamiento en el compositor objetivo |
| 7. GPU integrada | Rendimiento esperado con gráficos integrados |
| 8. Varios docks | Impacto con más de una instancia del plasmoide |

Fallback obligatorio: sin el módulo o sin soporte del backend, el componente debe
mantener un acabado legible. Si no existe fallback razonable, no se introduce.

## Interacción con las reglas de superficie de Plasma

- La región de blur de una superficie temática se calcula desde `mask` e
  `inset` del `FrameSvgItem`, según `AGENTS.md`. Un efecto nuevo no puede
  sustituir ese cálculo ni usar la ventana completa.
- El velo de `WidgetModal` y la región de blur comparten origen temático pero
  mantienen representaciones distintas; no mezclarlas.
- Los perfiles `WidgetModal` y `ModalElevated` ya definen su material; un efecto
  adicional debe justificar qué aporta.

## Degradación segura

| Situación | Comportamiento esperado |
|---|---|
| Módulo de efecto no disponible | acabado plano del tema, sin error en consola |
| Backend sin soporte de la API | mismo fallback que el caso anterior |
| Movimiento reducido | efecto estático, sin animación, y estado final correcto |
| GPU lenta detectada por el usuario | el efecto no debe ser imprescindible para entender la interfaz |

## Verificación

1. Tema claro y oscuro.
2. Escalado fraccionario y escalado alto.
3. Varias instancias del dock.
4. Panel lleno de iconos frente a panel casi vacío.
5. Degradación: forzar el fallback y comprobar legibilidad.
6. Registrar qué no se pudo medir.
