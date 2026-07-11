# Corrección del menú contextual de la papelera

## Causa

`DockItem.qml` intentaba ejecutar `root.openTrashMenu(...)`. El identificador `root` pertenece a `main.qml` y no forma parte del contexto interno de un componente `DockItem`, por lo que el clic derecho no podía abrir el diálogo.

## Solución

- `DockItem` expone la señal `contextMenuRequested(visualParent)`.
- El `MouseArea` acepta el botón derecho solamente cuando `itemType` es `trash`.
- `main.qml` recibe la señal y abre `trashMenuDialog` únicamente para elementos de papelera.
- Se añadió acceso equivalente con la tecla Menú y `Shift+F10`.
- El componente conserva el clic izquierdo y la navegación por teclado existentes.

## Validación

- `DockItem.qml`, `main.qml` y `TrashMenuPopup.qml` pasan `qmllint`.
- El paquete reconstruido pasa `unzip -t`.
- La instalación local se actualizó correctamente con `kpackagetool6`.
- La prueba gráfica automatizada no se ejecutó porque el mecanismo externo de aprobación alcanzó su límite; queda pendiente comprobar manualmente el clic derecho en Plasma.
