# Translations

[English](README.md) | [Español](README.es.md)

Punchi Dock Remastered uses English as the only runtime source language. User
interface strings in QML, JavaScript, and C++ must be written in English and
wrapped with the appropriate ki18n function. Translated labels belong only in
the PO catalogs.

The current translation domain is:

```text
plasma_applet_org.kde.plasma.punchi-dock-remastered
```

Update the POT template and every existing PO catalog with:

```bash
scripts/update-translations.sh
```

Before committing a catalog, verify it with:

```bash
msgfmt --check --check-format --output-file=/dev/null po/<language>.po
```

The packaging script compiles reviewed PO files and includes only their MO
catalogs under `contents/locale/<language>/LC_MESSAGES/` in the final
`.plasmoid`, matching the KPackage contents prefix used by Plasma.
English is the source fallback and does not use an `en.po` catalog. Spanish is
the first maintained translation. The next priority languages are German (`de`)
and Brazilian Portuguese (`pt_BR`), followed by French (`fr`) and Italian
(`it`), but a catalog must not be advertised or packaged as supported until it
has been reviewed and passes the translation tests.
