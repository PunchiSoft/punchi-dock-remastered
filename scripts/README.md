# Development audit scripts

This directory contains developer-only validation tools. They are excluded from
the plasmoid package and must never become runtime dependencies.

## KConfig contract auditor

`audit-plasma-config.py` checks the static path from the KConfig schema to the
declared KCM pages and the runtime configuration map.

Run it from the project root:

```bash
python3 scripts/audit-plasma-config.py --project-root .
```

Use JSON when another tool needs to consume the result:

```bash
python3 scripts/audit-plasma-config.py --project-root . --format json
```

Add `--verbose` to the text output to list every schema entry and its KCM owner.
The command exits with `0` when the contract passes and `1` when it finds a
structural error, so it can be used directly in CI.

The summary reports:

- entries and groups parsed from `contents/config/main.xml`;
- pages resolved from `contents/config/config.qml`;
- schema-facing `cfg_*` properties exposed by those pages;
- direct reactive accesses through `Plasmoid.configuration` in runtime code;
- runtime-managed entries and known multi-page owners;
- errors and warnings with stable diagnostic codes.

Run the auditor whenever a change adds, removes, renames, moves, or changes the
ownership of a KConfig entry, a `cfg_*` property, a configuration page, or a
runtime configuration access. CTest runs it automatically as
`plasma_config_audit`; its isolated regression suite is
`plasma_config_auditor_test`.

### Interpreting failures

- `schema-without-kcm`: a user-facing schema entry has no `cfg_*` owner in a
  declared top-level KCM page.
- `cfg-without-schema` or `kcm-without-schema`: a QML property has no matching
  schema entry.
- `schema-without-reactive-reference` or `schema-without-runtime-consumer`: the
  schema key is not read or written through the runtime configuration map.
- `runtime-key-without-schema`: runtime code accesses a key absent from the
  schema.
- `config-page-*`: a declared KCM source is missing, duplicated, or escapes
  `contents/ui/`.
- `unexpected-multiple-owners` or `expected-owner-set-changed`: ownership is
  ambiguous or differs from an explicitly reviewed exception.

Do not silence a failure by broadening an exception. First confirm the intended
owner and runtime path. Update `RUNTIME_ONLY_KEYS` or
`EXPECTED_MULTI_PAGE_OWNERS` only when the architecture deliberately changes,
then add or adjust an isolated regression test.

### Evidence boundary

This is a static connectivity audit. A passing result does not prove Apply,
Cancel, persistence, hot refresh, visual effect, or behavior in a real Plasma
session. Keep QML/runtime tests and manual Plasma validation for those contracts.
