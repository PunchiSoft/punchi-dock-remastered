# Punchi Dock Remastered

<p align="center">
  <img src="contents/images/punchi-dock-remastered.svg" width="160" alt="Punchi Dock Remastered Logo">
</p>

<p align="center">
  <a href="https://github.com/PunchiSoft/punchi-dock-remastered/releases/tag/v0.9.7.55">
    <img src="https://img.shields.io/badge/release-v0.9.7.55-4caf50" alt="Version v0.9.7.55">
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/lizenz-GPL--3.0--or--later-blue" alt="Lizenz GPL-3.0-or-later">
  </a>
  <a href="https://www.paypal.com/donate/?hosted_button_id=HXFSZU4K8C38W">
    <img src="https://img.shields.io/badge/Spenden-PayPal-0070ba" alt="Mit PayPal spenden">
  </a>
</p>

[English](README.md) | [Español](README.es.md) | [Deutsch](README.de.md) | [Português (Brasil)](README.pt_BR.md)

Punchi Dock Remastered ist ein natives Starter-Dock und eine Aufgabenleiste für KDE Plasma 6, primär für Wayland entwickelt. Es kann als frei schwebendes Dock oder integriert in ein Plasma-Panel betrieben werden und folgt dabei dem aktiven Farbschema.

Dieses Repository ist ein modularer Rewrite des ursprünglichen [Punchi Dock Plasmoids](https://github.com/PunchiSoft/punchi-dock-plasmoid). Das Projekt bereitet derzeit seinen Weg zur stabilen Version 1.0 vor.

Die aktuelle Version ist
[v0.9.7.55](https://github.com/PunchiSoft/punchi-dock-remastered/releases/tag/v0.9.7.55).

## Neuigkeiten in Version 0.9.7.55

- **Audio-Untermenü im Kontrollzentrum und dynamische Gerätesymbole**: Dedizierte Seite zur Verwaltung von Audio-Ausgabe-/Eingabegeräten und App-Lautstärken, dynamische Schallwellen-Symbole passend zur Schiebereglerposition, automatische Kopfhörererkennung und universelles Equalizer-Symbol (`view-media-equalizer`).
- **Plasma-Lautstärke-OSD-Schalter**: Integrierte KConfig-Steuerung (`plasmaparc`) zur Anzeige oder Ausblendung der globalen KDE-Lautstärkeleiste.
- **Einheitliche Interaktionen und symmetrische Geometrie**: Zeigehand-Mauszeiger und Tooltips auf allen Karten sowie symmetrischer Rand für die Nachtlicht-Einstellungen.

Siehe das [Änderungsprotokoll für 0.9.7.55](CHANGELOG.md#09755---2026-09-02) für detaillierte Versionshinweise und die durchgeführte Validierung.

## Screenshots

| PunchiMenu Normal — empfohlene Vorschau |
|:--:|
| <img src="Images/PunchiMenuNormal.png?v=0.9.7" alt="PunchiMenu Normal mit Anwendungskategorien, Raster und Favoriten" width="760"> |

| PunchiMenu Vollbild |
|:--:|
| <img src="Images/PunchiMenuFullScreen.png?v=0.9.7" alt="PunchiMenu Vollbild-Anwendungsstarter" width="760"> |

| MPRIS-Mediensteuerung |
|:--:|
| <img src="Images/MPRIS-Controls.png" alt="MPRIS-Popup-Layouts mit Coverbild und Wiedergabesteuerung" width="760"> |

| Dock-Layouts |
|:--:|
| <img src="Images/desktop-layouts.png" alt="Punchi Dock in horizontalen, vertikalen und Panel-Layouts" width="760"> |

| Ordner-Raster | Kalender und Uhr |
|:--:|:--:|
| <img src="Images/MenuGrid.png" alt="Ordner-Popup in Rasteransicht" width="300"> | <img src="Images/Calendar_clock.png" alt="Kalender- und Uhr-Popup" width="300"> |

## Sprachen

- Englisch ist die Quellsprache und Standard-Rückfallebene.
- Spanisch (`es`) ist die derzeit aktiv gepflegte Benutzeroberflächen-Übersetzung.
- Deutsch (`de`) und brasilianisches Portugiesisch (`pt_BR`) sind als vollständige Übersetzungskataloge enthalten.

Siehe den [Leitfaden für Übersetzungen](po/README.md) für Katalogrichtlinien und Mitwirkung.

## Funktionen

- Schwebendes Dock und Plasma-Panel-Modi.
- Angeheftete Starter und optionale dynamische Programmleiste.
- Benutzerdefinierte Starter mit sicherer Beibehaltung von Befehlen und Parametern.
- Fensterkarten, Live-Vorschauen und gruppierte Fenstersteuerungen (Auswahl zwischen Karten, Live-Vorschauen oder reiner Menüanzeige).
- Konfigurierbare Ordner mit Raster-, Listen- und Detailansicht, direktem Umschalten aus dem Kontextmenü sowie Drag-and-Drop von Startern aus PunchiMenu oder vom Schreibtisch, Notizen, Papierkorb, Trennlinien und Kalender.
- PunchiMenu-Anwendungsstarter mit Normal- und Vollbilddarstellung, Suche, Kategorien, Favoriten, Ordnern, selektivem Ausblenden, Tastaturbedienung und globalem Tastaturkürzel.
- Vollbild-Kontrollzentrum mit Schnellverbindungen für WLAN und Bluetooth, Helligkeits- und Lautstärkesteuerung, Nicht stören, Hell-/Dunkel-Umschaltung, Live-Nachtlicht-Einstellung und persistentem Benachrichtigungsverlauf.
- Optionaler PipeWire-Audio-Visualisierer mit sechs Stilen, dynamischen oder Plasma-Farben und bis zu 48 visuellen Elementen.
- Plasma-angepasste Popups mit konfigurierbaren Animationen, anpassbarem Abstand und fließenden Übergängen.
- Native Anwendungs- und Fensteraktionen in Kontextmenüs.
- Optionale Kennzeichnungs-Badges mit Fensteranzahl für gruppierte Anwendungen.
- Kontextuelle MPRIS-Medienkarten mit Cover, Titelinformationen, Steuerung und Stummschaltung.
- Kompaktes MPRIS-Dockelement mit Spielerauswahl und Direktausführung.
- Persistente Dockelement-Neuanordnung per langem Mausklick oder Tastatur sowie sicheres Datei-Drag-and-Drop auf Starter und den Papierkorb.
- Asynchrone Papierkorb-Aktionen mit Fortschrittsanzeige, Signalton und KDE-Benachrichtigungen.
- Externe JSON-Hintergrundstile in verwalteter Benutzerbibliothek mit Plasma-Rückfallebene.
- Standardkonforme XDG-Benutzerspeicherung: JSON-Stile (`~/.local/share/punchi-dock-remastered/`) und Konfiguration (`~/.config/punchi-dock/`) verwenden isolierten, atomaren Speicher zum Schutz vor Beschädigungen bei Updates.
- Natives C++-QML-Integrationsmodul für Anwendungsentdeckung, Audiospektrum und Papierkorbfunktionen.

## Systemanforderungen

- KDE Plasma 6 oder neuer.
- Wayland-Sitzung empfohlen (sekundäre X11-Unterstützung).
- PipeWire für den optionalen Audio-Visualisierer erforderlich.
- **Offizielle Referenzdistribution**: Fedora 44 `x86_64` mit KDE Plasma 6+.
- **Offizielles Universal-Paket**: Erstellt auf Debian 13 (Trixie) mit binären C-Shims (`compat/`), lauffähig auf modernen Distributionen mit Plasma 6 (Fedora, Arch Linux, Debian, Kubuntu und Derivaten).
- **Lokale Kompilierung aus dem Quellcode**:
  - Erfordert CMake 3.22+, C++20-Compiler, Qt 6.6+, ECM/KF6 6.0+, Plasma 6.0+ und PipeWire-Entwicklungsdateien (bereitgestellt über die Paketverwaltung der eigenen Distribution).
  - Automatisierte Assistenten mit und ohne Tests ermöglichen die Kompilierung und Installation in einem Schritt.

## Ein vorgefertigtes Paket installieren

Endanwender können ein offizielles vorkompiliertes `.plasmoid`-Paket direkt installieren, ohne Compiler oder Entwicklungswerkzeuge zu benötigen.

Installation oder Aktualisierung über das universelle Skript:

```bash
./scripts-user/setup-universal.sh pfad/zum/paket.plasmoid
```

Oder manuell mit `kpackagetool6`:

```bash
# Erstinstallation
kpackagetool6 --type Plasma/Applet --install ./punchi-dock-remastered-<version>-<distro>-x86_64.plasmoid

# Aktualisierung
kpackagetool6 --type Plasma/Applet --upgrade ./punchi-dock-remastered-<version>-<distro>-x86_64.plasmoid
```

## Aus dem Quellcode kompilieren

Das Plasmoid enthält ein natives C++-Modul zur Integration in Plasma 6, PipeWire und die Aufgabenverwaltung. Es kann auf jeder modernen Linux-Distribution mit Plasma 6 kompiliert werden.

### Build-Abhängigkeiten nach Distribution

Der Assistent `setup.sh` prüft und meldet fehlende Pakete automatisch. Zur manuellen Vorabinstallation:

#### Fedora / RHEL / Nobara
```bash
sudo dnf install \
    gcc-c++ cmake extra-cmake-modules \
    qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qtshadertools \
    plasma-workspace-devel pipewire-devel \
    kf6-kconfig-devel kf6-ki18n-devel kf6-kio-devel \
    gettext zip unzip
```

#### Arch Linux / Manjaro / EndeavourOS
```bash
sudo pacman -S --needed \
    base-devel cmake extra-cmake-modules \
    qt6-base qt6-declarative qt6-shadertools \
    plasma-workspace pipewire \
    kconfig ki18n kio kservice
```

#### Debian 13 (Trixie) / Kubuntu / Ubuntu
```bash
sudo apt update && sudo apt install \
    build-essential cmake extra-cmake-modules \
    qt6-base-dev qt6-declarative-dev qt6-shader-baker \
    libplasma-dev libpipewire-0.3-dev \
    libkf6config-dev libkf6i18n-dev libkf6kio-dev \
    gettext zip unzip
```

### Enthaltene Build-Assistenten

Das Repository enthält automatisierte Assistenten für unterschiedliche Anforderungen:

#### 1. Benutzer-Assistent (Schnell & Sicher, ohne Tests)

Entwickelt für die lokale Kompilierung und Installation in wenigen Sekunden ohne Ausführung von Entwicklertests:

```bash
./scripts-user/setup.sh
```

- Konfiguriert CMake mit `BUILD_TESTING=OFF` (überspringt `qmllint` und CTest).
- Erkennt automatisch die Distribution (Fedora, Arch Linux, Debian, Kubuntu und Derivate) und überprüft die Abhängigkeiten.
- Bietet interaktive **Konfiguration der Build-Parallelität und Speicherschutz** (Sicherer Modus mit 1 Kern für VMs / <= 4 GB RAM, Ausbalanciert, Schnell oder Benutzerdefiniert).
- Unterstützt direkte CLI-Befehle:

```bash
# Kompilieren und installieren mit sicherem Speicherprofil (1 Thread)
./scripts-user/setup.sh --install -j 1

# Nur das lokale .plasmoid-Paket mit 4 Threads erstellen
./scripts-user/setup.sh --build-only --jobs 4

# Plasmoid vom aktuellen Desktop deinstallieren
./scripts-user/setup.sh --uninstall
```

Das erstellte Paket befindet sich unter `dist/punchi-dock-remastered-<version>-<distro>-<arch>-local-build.plasmoid`. Siehe [scripts-user/README.md](scripts-user/README.md).

#### 2. Entwickler-Hauptassistent (Strikte Validierung mit Tests)

Entwickelt für Entwickler und Beitragende zur vollständigen Überprüfung der Codebasis:

```bash
./scripts-dev/setup.sh
```

- Führt `qmllint` zur statischen QML-Codeanalyse durch.
- Konfiguriert CMake mit `BUILD_TESTING=ON` und führt die vollständige Testsuite mit 67 CTest-Prüfungen aus (Architekturverträge, Shader, Lebenszyklus, Plasma-Integration und natives Backend).
- Unterstützt CLI-Optionen:

```bash
./scripts-dev/setup.sh --local-test           # Kompilieren, alle 67 Tests validieren und in Plasma installieren
./scripts-dev/setup.sh --local-test -j 1      # Sicherer Modus (1 Kern) für virtuelle Maschinen / wenig RAM
./scripts-dev/setup.sh --local-test --jobs 8 # Schneller Modus mit 8 parallelen Threads
./scripts-dev/setup.sh --clean-install         # Saubere Neuinstallation von Grund auf
./scripts-dev/setup.sh --dependencies-only    # Offizielle Build-Abhängigkeiten der Distribution installieren
./scripts-dev/setup.sh --lang de --help       # Hilfe auf Deutsch (unterstützt auch en, es, pt_BR)
```

Siehe [scripts-dev/README.md](scripts-dev/README.md) für zusätzliche Entwickler-Tools (`check-build-environment.sh`, `update-translations.sh`, `validar-empaquetado-limpio.sh`).

## Projektstruktur

- `contents/`: Plasmoid-Laufzeitpaket.
- `contents/ui/components/`: Wiederverwendbare QML-Oberflächenkomponenten.
- `contents/code/`: Gemeinsame JavaScript-Logik und Standardwerte.
- `src/`: Natives C++-QML-Integrationsmodul.
- `scripts-user/`: Benutzer-Installations- und Build-Assistent.
- `scripts-dev/`: Strikte Entwicklungs-, Test- und Wartungswerkzeuge.
- `metadata.json`: KPackage-Metadaten und Plasma-Kompatibilitätsdeklaration.

## Das Projekt unterstützen

Punchi Dock Remastered ist freie Software. Fehlerberichte, reproduzierbare Testergebnisse, Dokumentationsverbesserungen, Übersetzungen und Code-Beiträge sind willkommene Möglichkeiten zur Unterstützung.

Freiwillige finanzielle Spenden können über die [offizielle PayPal-Spendenseite](https://www.paypal.com/donate/?hosted_button_id=HXFSZU4K8C38W) geleistet werden.

## Lizenz

Punchi Dock Remastered steht unter der [GNU General Public License v3.0 oder neuer](LICENSE).
