# Punchi Dock demo themes

This directory is included in the repository as an example package for people
who want to customise the Punchi Dock background. It contains
`themes demo V 0.1.5.tar.gz`, a collection of JSON themes ready to import.

It is not part of the plasmoid and is not installed automatically. It is kept
here so the catalogue can be downloaded, shared, and updated without adding
example themes to the dock runtime.

## How to use the themes

1. Extract `themes demo V 0.1.5.tar.gz`.
2. Open Punchi Dock configuration and go to **Appearance**.
3. Under **Dock background theme**, select **External JSON theme**.
4. Select **Import…**, then choose **Import folder…**.
5. Select the `themes/` directory created when extracting the archive.
6. Choose an imported theme and apply the configuration.

You can also import one JSON file at a time with **Import file…**.

## What is included

The catalogue contains flat 2D backgrounds, experimental 2.5D backgrounds,
parametric silhouettes, and animated backgrounds. Themes can provide
gradients, borders, shadows, and separator styling. Animated themes adapt
their flow to the dock axis when the floating dock is vertical.

The separator catalog supports `line`, `dot`, `square`, `capsule`, `star`,
`diamond`, `ring`, `doubleLine`, and `chevron`. The archive includes dedicated
examples for every extended shape:

| Shape | JSON value | Sample theme |
|---|---|---|
| Diamond | `diamond` | 16. Obsidiana 2D |
| Ring | `ring` | 19. Cerámica 2D |
| Chevron | `chevron` | 20. Industrial plano |
| Double line | `doubleLine` | 21. Tela técnica |
| Star | `star` | 22. Holográfico 2D |
| Square | `square` | 24. Segmentado |

Set the shape through `separator.style`. Values outside this closed catalog are
rejected, and orientation-aware shapes adapt to horizontal and vertical docks.

JSON themes apply only to the floating dock. To restore the native appearance,
select **Plasma theme** in Appearance or from the dock context menu.

## Safety and storage

Theme files are JSON data: they do not run scripts, download resources, or
include code. Punchi Dock validates each theme before importing it and stores
a copy in its local theme library. Removing an imported theme from the
configuration does not modify this demo package.

## Creating or editing a theme

Use the included JSON files as references. Keep custom themes declarative:
theme files cannot run scripts or load external resources. The full separator
schema and property limits are documented in the `themes/README.md` file inside
the archive.
