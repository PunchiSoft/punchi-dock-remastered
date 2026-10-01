---
name: security
description: "Audit Punchi Dock security: command execution, untrusted JSON themes, configuration data, filesystem paths, KIO URLs, MPRIS metadata, resource limits, permissions, and package contents. Use when the user asks for a security audit, vulnerabilities, injection risks, untrusted input handling, local permissions, or security fixes. Do not apply generic web API authentication checks unless the task adds a server or remote API."
---

# Security audit for Punchi Dock

## Scope and mode

Treat an audit as read-only unless the user explicitly asks to implement a
fix. Punchi Dock is a local KDE Plasma plasmoid, not a web service: it has no
HTTP routes, user accounts, sessions, or API authentication boundary by
default. State that distinction instead of reporting missing authentication as
a vulnerability.

Use `preflight-security-review` for a narrow check before modifying,
packaging, committing, or publishing. Use this skill for the deeper,
evidence-based audit of the runtime and its trust boundaries.

## Required audit flow

1. Read `AGENTS.md`, inspect `git status --short`, and define the requested
   scope. Do not expose local paths, logs, personal data, or secrets found
   during the review.
2. Map data sources to sinks. Record whether each input is trusted local user
   configuration, local file content, desktop/service metadata, drag-and-drop
   data, media metadata, or a network-derived URL.
3. Inspect the relevant implementation and direct consumers. Prefer `rg` and
   targeted reads; do not infer behaviour from names alone.
4. Assess reachability, preconditions, impact, existing mitigations, and a
   minimal compatible fix. Do not report a hypothetical issue as confirmed
   without code evidence.
5. Classify each finding as `critical`, `high`, `medium`, `low`, or
   `informational`. Include an explicit `not applicable` section for web-only
   checks such as API authentication when no server exists.
6. If the user requests remediation, make the smallest security-scoped change,
   add or update a focused test where practical, and run proportional build,
   test, package, and QML runtime validation.

## Mandatory surfaces

Inspect the surfaces that apply to the requested scope:

- **Commands and processes:** `QProcess`, shell invocations, command runners,
  `.desktop` launchers, and command strings from dock configuration or menu
  actions. Verify that untrusted fields cannot become shell syntax.
- **Theme import and storage:** JSON validation, size/count limits, recursive
  directory imports, canonical paths, symlinks, filenames, atomic writes, and
  deletion restricted to the managed theme library.
- **Filesystem and URLs:** `QUrl`, KIO jobs, local paths, drag-and-drop URLs,
  folder listings, trash operations, and traversal outside the intended scope.
- **External metadata:** MPRIS titles, artwork URLs, service identifiers, and
  desktop-file metadata. Treat them as untrusted display or URL data.
- **Configuration and models:** persisted JSON, type/range validation, stale
  configuration, and values crossing QML/C++ boundaries.
- **Resource use:** malformed or oversized JSON, unbounded recursion, large
  directory scans, repeated processes, animations, and untrusted data that can
  cause memory, CPU, or UI denial of service.
- **Distribution and privacy:** package contents, debug logs, demo archives,
  credentials, personal paths, telemetry, unexpected network access, and
  permissions.

Consult the local KDE SDK when an API's path, URL, process, or permission
semantics are material to a finding. Do not use online examples as proof when
local source or official Qt/KDE documentation is available.

## Project-specific expectations

- A local user choosing a launcher command is an intentional capability, not
  automatically command injection. It becomes a vulnerability when data from a
  less trusted source is concatenated into a shell command or bypasses the
  documented local-user boundary.
- External theme files are data, not executable plugins. Keep their schema
  declarative and bounded; never add script, QML, URL, or arbitrary resource
  loading support without an explicit security design.
- Treat imports, drag-and-drop data, MPRIS metadata, and filesystem content as
  untrusted even when they originate from the current desktop session.
- Do not add authentication, telemetry, network calls, privilege elevation, or
  broad sandboxing merely because a web-security checklist suggests them.

## Reporting format

For every finding, provide:

1. title and severity;
2. affected file and evidence;
3. simple-language explanation;
4. realistic impact and preconditions;
5. existing mitigation, if any;
6. minimal recommended remediation and test;
7. status: confirmed, needs runtime confirmation, mitigated, or not applicable.

End with a short table of audited surfaces, findings, and residual risk. State
exactly what was inspected and what was not. Do not provide exploit payloads
or destructive commands unless the user explicitly needs a safe reproduction.

## Completion criteria

- Findings are tied to source evidence and severity is justified.
- Web-only checks are not misapplied to the plasmoid.
- No secrets, personal data, or unsafe proof-of-concept details are exposed.
- Proposed fixes preserve Plasma 6 compatibility and the established UI →
  controller → service → KDE separation.
