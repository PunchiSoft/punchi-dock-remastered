#!/bin/bash
set -e

# Cambiar al directorio del script para evitar fallos si se ejecuta desde fuera
cd "$(dirname "$0")"

PLASMOID_NAME="org.kde.plasma.punchi-dock-remastered"
ZIP_FILE="dist/punchi-dock-remastered.plasmoid"

echo "==> [1/5] Validando código QML (qmllint)..."
find contents/ui -name "*.qml" -exec qmllint {} + || {
    echo "❌ Se encontraron errores de sintaxis en los archivos QML. Abortando."
    exit 1
}
echo "✅ Sintaxis QML correcta."

echo "==> [2/5] Empaquetando Punchi Dock Remastered..."
mkdir -p dist
rm -f "$ZIP_FILE"
# El paquete distribuible debe contener solo la estructura valida del plasmoide.
zip -rq "$ZIP_FILE" metadata.json LICENSE contents
unzip -tq "$ZIP_FILE" >/dev/null

echo "==> [3/5] Instalando paquete en KDE..."
kpackagetool6 --type Plasma/Applet -u "$ZIP_FILE" 2>/dev/null || kpackagetool6 --type Plasma/Applet -i "$ZIP_FILE"

echo "==> [4/5] Reiniciando Plasma Shell..."
if command -v kquitapp6 >/dev/null 2>&1; then
    kquitapp6 plasmashell >/dev/null 2>&1 || true
else
    killall plasmashell >/dev/null 2>&1 || true
fi

sleep 1

if command -v kstart >/dev/null 2>&1; then
    kstart plasmashell >/dev/null 2>&1
elif command -v kstart6 >/dev/null 2>&1; then
    kstart6 plasmashell >/dev/null 2>&1
else
    plasmashell >/dev/null 2>&1 &
fi

echo "==> [5/5] Recopilando logs de inicialización (esperando 4 segundos)..."
sleep 4
# Filtramos todo el journal de usuario, no solo el servicio
journalctl --user --since "10 seconds ago" | grep -iE "punchi|qml|typeerror|referenceerror|dockmodel" > debug.log || true

echo "==> ¡Listo! Instalación completada. Los logs han sido guardados en 'debug.log'."
