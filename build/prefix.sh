export PATH=/home/CMUNOZJ/.local/bin:$PATH

# LD_LIBRARY_PATH only needed if you are building without rpath
# export LD_LIBRARY_PATH=/home/CMUNOZJ/.local/lib64:$LD_LIBRARY_PATH

export XDG_DATA_DIRS=/home/CMUNOZJ/.local/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}
export XDG_CONFIG_DIRS=/home/CMUNOZJ/.local/etc/xdg:${XDG_CONFIG_DIRS:-/etc/xdg}

export QT_PLUGIN_PATH=/home/CMUNOZJ/.local/lib64/plugins:$QT_PLUGIN_PATH
export QML2_IMPORT_PATH=/home/CMUNOZJ/.local/lib64/qml:$QML2_IMPORT_PATH

export QT_QUICK_CONTROLS_STYLE_PATH=/home/CMUNOZJ/.local/lib64/qml/QtQuick/Controls.2/:$QT_QUICK_CONTROLS_STYLE_PATH

export MANPATH=/home/CMUNOZJ/.local/share/man:${MANPATH:-/usr/local/share/man:/usr/share/man}

export SASL_PATH=/home/CMUNOZJ/.local/lib64/sasl2:${SASL_PATH:-/usr/lib64/sasl2}
