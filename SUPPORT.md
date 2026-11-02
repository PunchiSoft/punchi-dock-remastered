# Support

Punchi Dock Remastered is maintained on a best-effort basis. There is no support
contract, response time or fix guarantee.

## Where to ask

- Bug reports: use the repository bug form. It asks for the versions and steps a
  reproduction needs.
- Feature requests: use the feature request form and describe the observable
  behaviour you want.
- Documentation problems: use the documentation form.
- Questions: use the question form.
- Security problems: use the private advisory route in
  [SECURITY.md](SECURITY.md). Do not open a public issue.

Issues are the support channel.

## Before you report

1. Read the [README](README.md), especially the compatibility table and the
   installation notes for your distribution.
2. Reproduce once from a clean state: remove the installed widget, reinstall the
   release asset, and restart `plasmashell` only if your session requires it.
3. Search existing issues and pull requests.

## What a report needs

- Distribution and version.
- KDE Plasma and KWin versions, and the session type (Wayland or X11).
- Qt and KDE Frameworks versions, for example `plasmashell --version` and
  `qtpaths6 --qt-version`.
- How the widget was installed: KDE Store, local `.plasmoid` asset, or
  `kpackagetool6` from a checkout.
- The Punchi Dock version shown in the widget settings, in `metadata.json` or in
  the release asset name.
- Steps to reproduce, the expected result and the observed result.
- Relevant `plasmashell` log lines, for example
  `journalctl --user -b --no-pager | grep -i -E 'punchi|plasmoid'`.

Remove usernames, home paths, tokens, window titles and private file content
before pasting logs or screenshots.

## Not supported

- KDE Plasma 5.
- Desktop environments and compositors that are not KDE Plasma.
- Distribution and Qt combinations that are not listed as validated. They need
  their own build and their own testing.
- Bugs caused by Plasma, KWin, Qt or KDE Frameworks outside this project.
