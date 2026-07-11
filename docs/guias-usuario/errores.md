# Guía de Depuración y Errores QML

Cuando desarrollas plasmoides en QML para KDE Plasma 6, la consola suele arrojar una gran cantidad de mensajes. Esta guía te ayudará a distinguir qué errores debes solucionar inmediatamente y cuáles puedes ignorar de forma segura.

## 🛠 Comandos Útiles para Previsualización

### 1. Previsualizar el Plasmoide (y su configuración)
Para probar el plasmoide y sus ventanas de configuración sin tener que instalarlo en el entorno de escritorio completo cada vez, utiliza el visor oficial:

```bash
plasmoidviewer -a org.kde.plasma.punchi-dock-remastered
```
* **Para probar la configuración:** Con la ventana del visor abierta, haz clic derecho en el plasmoide y selecciona "Configure Punchi Dock Remastered...".
* **Atajo:** Puedes usar `Ctrl+C` en la terminal para detener el visor.

### 2. Filtrar logs reales en el sistema
Si ya tienes el plasmoide instalado en Plasma y quieres ver los errores en tiempo real, filtra la salida de `journalctl` para omitir el ruido:
```bash
journalctl --user -f | grep -iE "referenceerror|typeerror|error:|not a type|binding loop"
```

---

## 🚨 Errores Críticos (Rompen la interfaz)
Si ves alguno de estos, arréglalo inmediatamente. Significan que una pestaña, un componente o todo el plasmoide ha fallado por completo:

* **`ReferenceError: [variable] is not defined`**
  *(Error de Referencia)*: Intentas usar un ID, propiedad o función que no existe o está fuera del alcance (scope) del componente actual.
* **`TypeError: Cannot read property '...' of null / undefined`**
  *(Error de Tipo)*: Estás intentando acceder a una propiedad de un objeto que aún no se ha cargado o está vacío (muy común al leer modelos de datos inexistentes).
* **`Component is not ready` / `Error while loading page:`**
  *(Falla de Carga)*: Ocurre cuando un archivo QML hace referencia a un componente que no existe, no está importado, o tiene un error de sintaxis crítico.
* **`[Component] is not a type`**
  *(Tipo inexistente)*: Olvidaste hacer el `import` correspondiente en la cabecera del archivo, o hay un error tipográfico en el nombre del componente (ej. escribir `Rectangl` en vez de `Rectangle`).

## ⚠️ Advertencias Importantes (Causan bugs)
El plasmoide seguirá funcionando, pero podrías notar problemas visuales o lógicos:

* **`Unable to assign [undefined] to QString / int / double`**
  QML 6 es muy estricto con los tipos. Si una propiedad de texto espera un "String" y le llega un nulo (`undefined`), lanzará este aviso. Se soluciona asegurando un valor por defecto: `texto: miVariable || ""`.
* **`Binding loop detected for property "..."`**
  *(Bucle infinito)*: Dos propiedades se actualizan mutuamente en ciclo. Consumirá ciclos de CPU y puede congelar el plasmoide.

## 👻 Ruido de KDE Plasma (Ignorables)
El motor de Plasma y Qt arrojan advertencias internas que **no son errores de tu código**. Ignóralos con seguridad:

* ❌ `Final member StackingOrder is overridden in class QQmlDMAbstractItemModelData...` 
  *(Bug interno de Qt al usar Repeaters o ListViews en Plasma 6. Aparece cientos de veces).*
* ❌ `qt.svg.draw: The requested buffer size is too big, ignoring` 
  *(Aviso inofensivo que salta a veces al escalar gráficos vectoriales SVG en el dock).*
* ❌ `QML [Objeto]: Created graphical object was not placed in the graphics scene.` 
  *(Ocurre brevemente mientras las pestañas de configuración o ventanas modales se construyen en memoria).*
* ❌ `qt.qml.propertyCache.append: Member [propiedad] overrides a member of the base object.` 
  *(Advertencia interna de herencia de tipos en librerías nativas).*
