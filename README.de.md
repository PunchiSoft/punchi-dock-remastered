# Punchi Dock Remastered

<p align="center">
  <img src="contents/images/punchi-dock-remastered.svg" width="120" alt="Logo von Punchi Dock Remastered">
</p>

<p align="center">
  <a href="https://github.com/PunchiSoft/punchi-dock-remastered/releases/latest"><img src="https://img.shields.io/github/v/release/PunchiSoft/punchi-dock-remastered?label=release" alt="Neueste veröffentlichte Version"></a>
  <a href="metadata.json"><img src="https://img.shields.io/badge/KDE_Plasma-6-blue" alt="KDE Plasma 6"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-GPL--3.0--or--later-blue" alt="Lizenz GPL-3.0-or-later"></a>
</p>

[English](README.md) | [Español](README.es.md) | [Deutsch](README.de.md) | [Português (Brasil)](README.pt_BR.md)

Punchi Dock Remastered vereint Anwendungsstarter, geöffnete Fenster, Ordner,
Mediensteuerung und Desktop-Werkzeuge in einem anpassbaren Dock für KDE Plasma 6.
Verwende es als schwebendes Dock oder innerhalb eines Plasma-Panels, horizontal
oder vertikal, mit dem aktiven Plasma-Design oder einem eigenen Hintergrund.

Es enthält PunchiMenu zum Finden und Organisieren von Anwendungen und ist eine
modulare Neufassung des ursprünglichen [Punchi Dock Plasmoids](https://github.com/PunchiSoft/punchi-dock-plasmoid).
Das Projekt wird aktiv auf dem Weg zu Version 1.0 weiterentwickelt.

[Funktionen](#funktionen) · [Screenshots](#screenshots) · [Installation](#installation) · [Kompatibilität](#kompatibilität) · [Tests](#tests-und-qualität) · [Support](#support-und-mitwirkung)

<p align="center">
  <img src="Images/dock-presentation-20261001.png" width="900" alt="Illustration von Punchi Dock Remastered: MPRIS, PunchiMenu, Fächerordner und JSON-Designs mit Zoom">
</p>

<p align="center"><em>Illustration</em></p>

Dieses README beschreibt den aktuellen Quellcode. Herunterladbare Pakete folgen
ihren [Versionshinweisen](https://github.com/PunchiSoft/punchi-dock-remastered/releases);
als in Entwicklung gekennzeichnete Funktionen können in der neuesten Veröffentlichung fehlen.

## Funktionen

### Anwendungen und Fenster

- **Starter und geöffnete Anwendungen:** Hefte Anwendungen an, füge eigene Starter
  oder Terminalbefehle hinzu, ordne Elemente um und zeige einen optionalen Bereich
  für geöffnete Anwendungen an.
- **Fenstersteuerung:** Nutze gruppierte Fenster, Anwendungsaktionen,
  Fensteranzahl-Anzeigen, Arbeitsflächenfilter und konfigurierbare Karten oder Live-Vorschaubilder.
- **Zuletzt verwendete Anwendungen — in Entwicklung:** Zeige optional bis zu drei
  zuletzt verwendete Anwendungen als Dock-Symbole oder in einem Container an.
  Angeheftete Anwendungen und Anwendungen mit geöffneten Fenstern werden ausgeschlossen.
  Die Funktion ist standardmäßig ausgeschaltet und verwendet den von KDE erfassten
  Verlauf; die Verfügbarkeit hängt von den gemeldeten Anwendungen ab.

### Ordner und Anwendungssammlungen

- **Vier Darstellungen:** Wähle Raster, Liste, Detail oder Fächer mit einstellbaren
  Symbolen, Beschriftungen, Typografie, Skalierung und Öffnungsanimationen.
- **Flexible Inhalte:** Erstelle eigene Sammlungen, befülle sie aus Kategorien
  installierter Anwendungen oder öffne Einträge aus einem Ordner im Dateisystem.
- **Direkte Bedienung:** Ziehe Starter aus PunchiMenu oder vom Desktop hinein,
  wechsle die Darstellung im Kontextmenü und öffne den zugehörigen Ordner in Dolphin.

### PunchiMenu

- **Anwendungen finden:** Suche, durchsuche Kategorien, verwalte Favoriten,
  organisiere benannte Ordner und blende ausgewählte Anwendungen aus.
- **Darstellung wählen:** Verwende ein schwebendes Menü im Normalmodus oder die Vollbilddarstellung.
- **Tastaturbedienung:** Navigiere mit sichtbarem Fokus, verwende ein einstellbares
  globales Tastenkürzel und greife auf die nativen KDE-Sitzungsaktionen zu.

### Medien und Desktop-Werkzeuge

- **Mediensteuerung:** Steuere MPRIS-kompatible Player mit Coverbildern,
  Titelinformationen, Wiedergabeaktionen, Player-Auswahl und einem kompakten Dock-Element.
- **Audiovisualisierer (EQ):** Zeigt das Spektrum der Systemaudioausgabe über PipeWire hinter den Dock-Symbolen an, im schwebenden Dock und im Plasma-Panel, horizontal oder vertikal. Wähle sechs visuelle Stile, Plasma-Designfarben oder dynamische Farben, Intensität und Bewegungsrichtung. Das Spektrum kann über dem Plasma-Hintergrund erscheinen oder ihn ersetzen. Dies ist ein visueller Effekt; er verändert den Klang nicht.
- **Alltagswerkzeuge:** Füge Papierkorb, Kalender und Uhr, schnelle Notizen und
  Trennelemente hinzu. Papierkorbaktionen bieten Fortschrittsanzeigen und KDE-Benachrichtigungen.
- **Kontrollzentrum — vorläufig:** Greife auf Oberflächen für WLAN, Bluetooth,
  Audio, Helligkeit, Nachtlicht, Benachrichtigungen und häufige Systemaktionen zu.
  Diese Komponente ist weiterhin in Entwicklung; erweiterte Einstellungen nutzen
  die offiziellen KDE-Module.

### Erscheinungsbild und Bedienung

- Unterstützung für das native Plasma-Panel mit automatisch berechnetem Zoom.
- **Plasma-Integration:** Anpassung an helle und dunkle Designs mit thematischen
  Popup-Oberflächen, Schatten und Unschärfe, soweit unterstützt.
- **Eigenes Erscheinungsbild:** Wähle flache 2D- oder regalartige 2,5D-Hintergründe,
  externe JSON-Designs, Indikatoren, Beschriftungen, Abstände und Hover-Effekte.
- **Direkte Konfiguration:** Übernimm Einstellungen ohne Neustart der Plasma Shell,
  mit Tastaturnavigation, zugänglichen Namen, Skalierung und reduziertem Bewegungsverhalten.

### Drag-and-drop

- **Dock:** Ordne Elemente um, hefte Anwendungsstarter aus PunchiMenu oder vom Desktop an, füge Anwendungen zu eigenen Containern hinzu und ziehe lokale Dateien auf kompatible Anwendungen oder den Papierkorb.
- **PunchiMenu:** Ordne im Normal- und Vollbildmodus Anwendungen und Ordner bei manueller Sortierung um, erstelle Ordner, indem du eine Anwendung auf eine andere ziehst, füge Anwendungen zu bestehenden Ordnern hinzu und ziehe Starter zum Dock oder Desktop.

## Screenshots

<p align="center">
  <img src="Images/dock-layouts-20261001.png" width="900" alt="Vertikales Dock und zwei horizontale Docks, mit und ohne JSON-Design">
</p>

### MPRIS

<p align="center">
  <img src="Images/mpris-presentations-eq-20261002.png" width="900" alt="MPRIS-Medienkarten mit Coverbildern und Wiedergabesteuerung">
</p>

<p align="center"><em>Illustration</em></p>

### Ordner-Popups

<p align="center">
  <img src="Images/popup-presentations-20261002.png" width="900" alt="Illustrative Übersicht der Ordnerdarstellungen: Fächer oben links, Detail oben rechts, Liste unten links und Raster unten rechts">
</p>

<p align="center"><em>Illustration</em></p>

<details>
<summary>PunchiMenu, Mediensteuerung und Desktop-Anordnungen</summary>

| PunchiMenu Normal | PunchiMenu Vollbild — frühe Vorschau |
|:--:|:--:|
| <img src="Images/punchimenu-normal-20261001.png" width="430" alt="PunchiMenu Normal mit Suche, Anwendungen und Favoriten"> | <img src="Images/punchimenu-fullscreen-20261001.png" width="430" alt="Frühe Vorschau von PunchiMenu im Vollbildmodus"> |

<p align="center">
  <img src="Images/punchimenu-compact-20261001.png" width="260" alt="PunchiMenu Kompakt">
</p>

<p align="center">
  <img src="Images/folder-presentations-20261001.png" width="900" alt="Illustrative Übersicht der Ordnerdarstellungen: Fächer oben links, Detail oben rechts, Liste unten links und Raster unten rechts">
</p>

Illustrative Zusammenstellung der Darstellungen Fächer, Detail, Liste und Raster,
basierend auf Desktop-Aufnahmen vom 1. Oktober 2026.

</details>

## Installation

### Vorkompiliertes Paket

Wähle für ein vorgefertigtes Paket eine zu deinem System passende Datei aus den
[GitHub Releases](https://github.com/PunchiSoft/punchi-dock-remastered/releases).
Installiere oder aktualisiere sie aus einer lokalen Kopie dieses Repositorys:

```bash
./scripts-user/setup-universal.sh --no-restart path/to/package.plasmoid
```

Alternativ installierst du mit `kpackagetool6 --type Plasma/Applet --install path/to/package.plasmoid`;
verwende `--upgrade` statt `--install`, um eine bestehende Installation zu aktualisieren.
### Quellcode herunterladen, kompilieren und installieren

1. **Quellcode herunterladen**

   ```bash
   git clone https://github.com/PunchiSoft/punchi-dock-remastered.git
   ```

2. **In den Projektordner wechseln**

   ```bash
   cd punchi-dock-remastered
   ```

3. **Build-Abhängigkeiten prüfen**

   ```bash
   ./scripts-user/setup.sh --check-deps
   ```

4. **Kompilieren und installieren**

   ```bash
   ./scripts-user/setup.sh --install --no-restart
   ```

Füge Punchi Dock Remastered anschließend über Plasmas Oberfläche zum Hinzufügen
von Miniprogrammen hinzu. Falls ein aktualisiertes natives Modul weiterhin geladen
ist, melde dich ab und wieder an, um die neue Version zu laden.

### Welches Skript sollte ich verwenden?

- **Benutzerskripte (`scripts-user/`):** Kompilieren, paketieren oder installieren den Dock für den täglichen Gebrauch, ohne Entwicklertests oder QML-Lint auszuführen. Build-Abhängigkeiten und Paketprüfungen bleiben erforderlich.
- **Entwicklerskripte (`scripts-dev/`):** Validieren Änderungen vor einem Beitrag oder der Distribution mit QML-Lint, CTest sowie Prüfungen für Übersetzungen, Testintegrität und Pakete.

Führe diese Befehle als Desktop-Benutzer im Stammverzeichnis des Repositorys aus.

| Ziel | Befehl | Wirkung |
|---|---|---|
| Ein heruntergeladenes Paket installieren | `./scripts-user/setup-universal.sh --no-restart path/to/package.plasmoid` | Installiert oder aktualisiert das Paket ohne Plasma-Neustart; kein Compiler erforderlich. |
| Aus dem Quellcode kompilieren und installieren | `./scripts-user/setup.sh --install --no-restart` | Prüft Abhängigkeiten, kompiliert und installiert für das aktuelle System ohne Entwicklertests. |
| Nur ein Paket erstellen | `./scripts-user/setup.sh --build-only --jobs 4` | Erstellt ein lokales Paket in `dist/`, ohne es zu installieren. |
| Eine Aktion interaktiv auswählen | `./scripts-user/setup.sh` | Bietet Kompilierung, Paketinstallation, Deinstallation, Neustart und Parallelitätsoptionen. |
| Den Entwicklungsablauf verwenden | `./scripts-dev/setup.sh` | Öffnet den strikten Assistenten für Kompilierung, Validierung und Paketierung; die Vorbereitung von Abhängigkeiten kann sudo erfordern. |
| Eine Installation in Plasma testen | `./scripts-dev/setup.sh --local-test` | Kompiliert, validiert, installiert, startet die Plasma Shell neu und sammelt Startdiagnosen. |

Lokale Builds sind für das aktuelle System bestimmt; sie sind nicht automatisch
universelle Pakete. Vollständige Optionen und Abhängigkeiten findest du bei den
[Benutzerskripten](scripts-user/README.md) und [Entwicklerskripten](scripts-dev/README.md).

## Kompatibilität

- **Desktop:** Linux mit KDE Plasma 6; Wayland ist das primäre Ziel, X11 wird über
  einen sekundären Pfad unterstützt.
- **Deklarierte Mindestanforderungen für Builds:** CMake 3.22, ein C++20-Compiler,
  Qt 6.6, KDE Frameworks 6.0 und Plasma 6.0 sowie die erforderlichen Entwicklungsbibliotheken.
- **Native Builds:** Entwicklungs-Builds richten sich hauptsächlich an Fedora 44 und neuer und verwenden die Qt- und KDE-Bibliotheken des Hostsystems. Build-Profile für Arch Linux und Debian 13 sind ebenfalls verfügbar.
- **Universelles Paket:** Offizielle universelle Builds werden unter Debian 13 kompiliert. Die Binärkompatibilität muss mit demselben Paket auf jedem Zielsystem geprüft werden.
- **Qualitätsprüfungen:** Die beobachtete Testumgebung besteht aus Fedora 44, Qt 6.11.2, Plasma 6.7.5, KDE Frameworks 6.30.0, GCC 16.2.1 und CMake 4.3.0. Diese Ergebnisse gelten für diese Umgebung; neuere Versionen und andere Distributionen benötigen eigene Validierung.
- **Native Pakete:** Verwende das für deine Umgebung bestimmte Paket. Deklarierte
  Mindestversionen bestätigen nicht jede Kombination; distributionsübergreifende
  Binärkompatibilität erfordert Tests desselben Artefakts auf jedem Zielsystem.
- **Audio:** Der optionale Visualizer verarbeitet PipeWire-Audio; Quellcode-Builds
  benötigen dessen Entwicklungsdateien.
- **Sprachen:** Englisch ist Quellsprache und Fallback; Spanisch wird gepflegt.
  Deutsch und brasilianisches Portugiesisch sind als erste Übersetzungen enthalten
  und warten auf muttersprachliche Prüfung. Siehe [Übersetzungsleitfaden](po/README.md).

## Tests und Qualität

Punchi Dock verbindet QML-Oberflächen, nativen C++-Code, persistente Konfiguration
und KDE-Dienste. Tests helfen, Regressionen wie ein nicht ladendes Miniprogramm,
wirkungslose Einstellungen, fehlerhafte Modellaktualisierungen oder fehlende
Paketdateien zu erkennen, bevor solche Änderungen die Benutzer erreichen.

| Prüfung | Zweck |
|---|---|
| CTest | Prüft native Logik, Komponenteninteraktionen, Laden und Zerstören des Miniprogramms, Konfigurationsverträge und Integration mit kontrollierten Providern. |
| QML-Lint | Erkennt nicht auflösbare Imports, Eigenschaften und Bindings; der Entwicklungsablauf weist Erhöhungen gegenüber der Warnungsbaseline der Umgebung zurück. |
| Übersetzungsprüfungen | Prüfen vollständige Kataloge, Formatplatzhalter und die Übersetzungsregeln des Projekts. |
| Testintegrität | Erkennt Änderungen an geschützten Tests, kanonischen Testnamen und der Mindestgröße der Testsuite. |
| Paketprüfungen | Prüfen das bereitgestellte Modul und die Übersetzungen und halten Entwicklungsdateien aus dem installierten Plasmoid heraus. |

Diese Prüfungen ergänzen manuelle Tests in Plasma. Bestandene isolierte Tests
belegen weder visuelle Korrektheit noch das Verhalten des Compositors oder
Kompatibilität mit jeder Distribution. Validierungsergebnisse beziehen sich
auf ihre konkrete Version und Umgebung.

Für reproduzierbare Validierung verwende die Abhängigkeiten und die Lint-Baseline deiner Plattform, kompiliere mit der aktuellen Toolchain neu und führe Tests mit isolierter Konfiguration und isolierten Sitzungen aus. Veraltete Build-Artefakte, fehlende Dienste oder eine abweichende Baseline können Fehler verursachen. Geschützte Tests müssen die Integritätsprüfung bestehen; nicht committete Git-Änderungen allein machen einen Testlauf nicht ungültig.

Um CTest ohne Installation des Plasmoids oder Neustart von Plasma auszuführen,
bereite die Build-Abhängigkeiten vor und führe Folgendes aus:

```bash
cmake -S . -B build -DBUILD_TESTING=ON
cmake --build build --parallel 2
ctest --test-dir build --output-on-failure
```

Dies führt die konfigurierte CTest-Suite aus; der vollständige Wartungsablauf
wendet zusätzlich die getrennten Prüfungen für Lint, Kataloge, Integrität und
Paketierung an. Siehe [Entwicklerskripte](scripts-dev/README.md) und
[Testintegrität](scripts-dev/test-integrity/README.md).

## Support und Mitwirkung

Melde Probleme über [GitHub Issues](https://github.com/PunchiSoft/punchi-dock-remastered/issues).
Nenne die Plasma- und Qt-Versionen, Distribution, Wayland- oder X11-Sitzung,
Paketquelle, Reproduktionsschritte sowie erwartetes und beobachtetes Verhalten.
Screenshots und gezielte Logs helfen, sofern sie keine privaten Informationen offenlegen.

Code-Beiträge, reproduzierbare Tests, Dokumentationsverbesserungen und
Übersetzungsreviews sind willkommen. Siehe [Entwicklungsablauf](scripts-dev/README.md)
und [Übersetzungsleitfaden](po/README.md).

<details>
<summary>Projektstruktur</summary>

- `contents/`: QML, JavaScript, Konfiguration und Ressourcen für die Laufzeit.
- `src/`: native C++-Integration.
- `tests/`: Verhaltens-, Laufzeit-, Integrations- und Vertragsprüfungen.
- `scripts-user/`: Build- und Installationswerkzeuge für Benutzer.
- `scripts-dev/`: Validierungs-, Paketierungs- und Wartungswerkzeuge.
- `metadata.json`: Paketidentität und deklarierte Plasma-Kompatibilität.

Interne Notizen, Entwicklungsdateien und Testwerkzeuge werden nicht in das installierte Paket aufgenommen.

</details>

### KI-gestützte Entwicklung

KI-Agenten sind eine integrale Entwicklungshilfe, um Programmierung zu beschleunigen, Probleme zu untersuchen, Refactorings zu unterstützen und Dokumentation sowie Tests vorzubereiten. Ihre Anweisungen werden in [AGENTS.md](AGENTS.md) und [`.agents/`](.agents/) versioniert. Die Projektverantwortlichen bleiben für technische Entscheidungen, Überprüfung und Validierung verantwortlich.

Die Agentenanweisungen und Skills wurden vom Autor von Punchi Dock Remastered durch eigene Recherche, das Lesen von Online-Ressourcen, Wikipedia und Reddit-Diskussionen erstellt und konfiguriert. Diese Anweisungen sind auf die Architektur und den Entwicklungsablauf des Projekts abgestimmt.

Finanzielle Unterstützung ist freiwillig: [Spenden über PayPal](https://www.paypal.com/donate/?hosted_button_id=HXFSZU4K8C38W).
Eine Spende ist niemals Voraussetzung für die Nutzung des Projekts.

## Lizenz

Punchi Dock Remastered steht unter der [GNU General Public License v3.0 oder neuer](LICENSE).

Urheberrechtshinweise, Lizenzbedingungen und Anforderungen zur Namensnennung
gelten gleichermaßen für menschliche und KI-gestützte Weiterverwendung.
KI-gestütztes Kopieren, Ändern, Weiterverbreiten, Zusammenfassen oder Erzeugen
von Code auf Grundlage dieses Projekts hebt die Verpflichtungen nicht auf:
GPL-3.0-or-later einhalten, erforderliche Hinweise bewahren, den zugehörigen
Quellcode bereitstellen, soweit vorgeschrieben, und Punchi Dock Remastered sowie
seine Mitwirkenden nennen, soweit anwendbar.

Die Änderungshistorie findest du in [CHANGELOG.md](CHANGELOG.md) und den
[GitHub Releases](https://github.com/PunchiSoft/punchi-dock-remastered/releases).
