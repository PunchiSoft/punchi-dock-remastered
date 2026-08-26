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
scripts-dev/update-translations.sh
```

Before committing a catalog, verify it with:

```bash
msgfmt --check --check-format --output-file=/dev/null po/<language>.po
```

The packaging script compiles reviewed PO files and includes only their MO
catalogs under `contents/locale/<language>/LC_MESSAGES/` in the final
`.plasmoid`, matching the KPackage contents prefix used by Plasma.
English is the source fallback and does not use an `en.po` catalog. Spanish is
the first maintained translation. German (`de`) and Brazilian Portuguese
(`pt_BR`) are complete initial translation drafts included for testing; they
require native-speaker review before being treated as maintained translations.
French (`fr`) and Italian (`it`) remain future priorities. A catalog must pass
the translation tests and receive language review before it is advertised as
maintained support.

## Review help wanted

Native German and Brazilian Portuguese speakers are welcome to review the
current `de.po` and `pt_BR.po` catalogs. Please focus on natural wording,
plural forms, KDE/Plasma terminology, accessibility labels, and text that may
be too long for compact controls. Report proposed changes through the project
issue tracker or submit a focused pull request.
