---
name: verification-before-completion
description: Decide whether the collected evidence is enough to declare a change finished, and report what remains unverified. Use when a task looks complete, before claiming success, closing a review, or opening a pull request.
---

# Verification before completion

"Done" is a claim about evidence, not about effort. Decide which levels the change
needed and which ones actually ran.

## Evidence levels

| Level | Shows | Cannot show |
|---|---|---|
| 1 Source reading | what the code says | that it runs |
| 2 Lint and static metadata | `qmllint` diagnostics, baseline debt, imports | behaviour |
| 3 Unit and Qt Quick Test | C++ logic and QML contracts offscreen | how Plasma composes them |
| 4 Full CTest | the configured graph is green | a real desktop |
| 5 Plasmoid load | every QML type resolves while the representation instantiates | KWin placement, input or theming |
| 6 Real Plasma session | panel, blur, popups, activation, theme on Wayland/X11 | how the result feels |
| 7 Visual inspection | what is on screen | unseen states |

## Procedure

1. Restate the request and its acceptance criteria.
2. List the levels the change cannot be validated without.
3. Mark each level executed, failed or not executed, with the command that ran.
4. Re-run the scoped test after the final edit, never before it.
5. Clean temporary state and confirm nothing outside the scope changed.
6. State the residual risk in one sentence per unexecuted level.

## Required before claiming completion

- The scoped test covering the changed behaviour passed after the last edit.
- The `ctest` result is quoted with its filter and count, not summarized as
  "all good".
- The five verifications in `AGENTS.md` are reported separately when the suite
  applies: CTest, `qmllint` baseline, translation catalogs, security preflight and
  the test-integrity gate.
- Every Plasma, KWin or Wayland claim names the distribution, Plasma, Qt and
  Framework versions and the session type it was observed on.
- Every removed or weakened test is called out with its authorization. A new or
  modified protected test needs
  `python3 scripts-dev/test-integrity-guard.py --update --authorized "<motive>"`.
- No plasmashell restart, test instance or temporary package is left behind.

## Documentation-only changes

A change that edits only prose — READMEs, `CHANGELOG.md`, `docs/`, `AGENTS.md`,
skill text, code comments, `CONTRIBUTING.md`, `SECURITY.md`, `SUPPORT.md` — needs
no suite: no test observes prose, so a green run is not evidence about it. Run
the proportional check instead and say why the suite was skipped.

The exception is a file a test parses. A skill's front matter, a baseline, a
catalog or a configuration a test reads gets that single test, never the suite.
Documentation shipped together with code is validated as code.

## Gotchas

- A test that passed before the last edit proves nothing about the final tree.
- Offscreen success is routinely mistaken for desktop behaviour; a plasmoide can
  instantiate under `offscreen` and still fail in a Plasma panel.
- `git diff` ignores untracked files. Check `git status --short` before saying the
  scope is clean.
- "Tests are green" without a count or filter can hide a suite that never ran
  because configuration failed.
- A documentation claim is part of the deliverable; an unverified README sentence
  is unfinished work.

## Coordination

`testing` chooses and runs the tests; this skill judges whether their evidence is
sufficient. `code-review` finds defects; this skill reports coverage.
`pr-delivery` publishes only the levels this skill accepted.

## Validation

```bash
git status --short
ctest --test-dir build --output-on-failure
python3 scripts-dev/test-integrity-guard.py --check
```

Close with what ran, what passed, what did not run, and the remaining risk.
