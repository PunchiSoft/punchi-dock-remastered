# Traducciones

[English](README.md) | [Español](README.es.md)

Punchi Dock Remastered utiliza inglés como único idioma fuente del runtime. Los
textos de interfaz en QML, JavaScript y C++ deben escribirse en inglés y
envolverse con la función ki18n correspondiente. Las traducciones de etiquetas
pertenecen únicamente a los catálogos PO.

El dominio de traducción actual es:

```text
plasma_applet_org.kde.plasma.punchi-dock-remastered
```

Actualiza la plantilla POT y todos los catálogos PO existentes con:

```bash
scripts/update-translations.sh
```

Antes de confirmar un catálogo, verifícalo con:

```bash
msgfmt --check --check-format --output-file=/dev/null po/<idioma>.po
```

El script de empaquetado compila los archivos PO revisados e incluye únicamente
sus catálogos MO bajo `contents/locale/<idioma>/LC_MESSAGES/` dentro del
`.plasmoid`, coincidiendo con el prefijo de contenidos KPackage utilizado por
Plasma.

El inglés es el fallback fuente y no utiliza un catálogo `en.po`. Español es la
primera traducción mantenida. Los siguientes idiomas prioritarios son alemán
(`de`) y portugués de Brasil (`pt_BR`), seguidos por francés (`fr`) e italiano
(`it`), pero ningún catálogo debe anunciarse ni empaquetarse como soportado
hasta que haya sido revisado y supere las pruebas de traducción.
