# Security policy

Punchi Dock Remastered is a KDE Plasma 6 plasmoid distributed under
GPL-3.0-or-later. `main` and the latest published release receive attention on a
best-effort basis; there is no long-term support branch, response time or fix
guarantee.

## Reporting a vulnerability

Do not open a public issue for a security problem.

Use GitHub's private vulnerability reporting:

<https://github.com/PunchiSoft/punchi-dock-remastered/security/advisories/new>

If that form is unavailable, open an issue asking for a private channel without
describing the problem, the affected surface or the reproduction steps in public.

Include the affected component and version or commit, reproduction steps, impact,
and any suggested mitigation. Remove personal paths, usernames, tokens, window
titles and private file contents from logs and screenshots.

## In scope

- Command construction and process execution paths.
- Untrusted JSON themes and configuration data.
- Filesystem paths, KIO URLs, desktop entry and shortcut writers.
- MPRIS and task-manager metadata handling.
- Package contents, permissions and install scripts.

## Out of scope

- Bugs caused by Plasma, KWin, Qt or KDE Frameworks outside this project; report
  those upstream.
- Distributions or sessions the project does not declare as validated.
- Vulnerabilities that require an already compromised user session.
