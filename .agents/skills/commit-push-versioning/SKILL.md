---
name: commit-push-versioning
description: Prepare an authorized commit and push, decide whether the work prepares a release, review the exact staged content, and hand the branch to pr-delivery. Use when the user asks to commit, push, or both.
---

# Commit and push

Use when the user asks to commit, push, or both. That request authorizes the
requested Git operations on the current branch, its configured upstream, and the
delivery pull request `pr-delivery` opens once the work is approved; it does not
authorize tags, releases, force pushes, unrelated remotes, merges or branch
deletion.

## Branch first

Commit on a delivery branch, never on `main`. When the work still sits on `main`,
apply `branch-baseline` and create the branch before staging anything. One branch
per change; never reuse a branch that was already merged. Report the branch
alongside the commit and let the user decide when to merge.

## Version and changelog

Versions identify releases, not commits. Pending work accumulates under
`## Unreleased` at the top of `CHANGELOG.md`; the declared version changes only
when a release is prepared.

- A behavior change or a user-visible capability adds its entry under
  `## Unreleased`.
- Tests, documentation, skills, repository metadata, development tooling and
  comment-, formatting- or wording-only changes need neither a changelog entry
  nor a version change. Use `docs:` or `chore:` for them.
- When the user explicitly asks to prepare a release, move the `Unreleased`
  entries under a new `## [<version>] - <YYYY-MM-DD>` heading, choose the next
  number in the existing `0.9.x.y` scheme, and synchronize every declaration in
  the same commit: `KPlugin.Version` in `metadata.json`,
  `project(... VERSION ...)` in `CMakeLists.txt` and `Project-Id-Version` in
  `po/plasma_applet_org.kde.plasma.punchi-dock-remastered.pot`. Then run
  `python3 scripts-dev/check-version.py`; `project_version_test` fails when a
  declaration disagrees.
- A release may contain many commits and several features. Its version advances
  once for the whole release, not once per commit and not once per backup.
- Never infer the next version from a trailing component, a stale build
  directory, an installed copy, a Git tag or a note in `bitacora/`.

## Review and publish

1. Inspect `git status`, the branch and its upstream, and the staged, unstaged
   and untracked changes. Preserve existing work; never reset, clean or discard
   user changes. Stop if the current branch is `main`.
2. Identify the intended commit scope and review its full diff, using
   `code-review` when it spans several files or changes behavior. Keep ignored
   build output, credentials, diagnostics and unrelated changes out. Ask only if
   mixed changes cannot be separated safely.
3. Run the validation the change requires, following the proportional protocol
   in `AGENTS.md`: full CTest after touching runtime code, the `qmllint`
   baseline after QML, `scripts-dev/update-translations.sh` after visible text,
   the security preflight before publishing and
   `python3 scripts-dev/test-integrity-guard.py --check` always.
4. Stage only the reviewed files by exact path, inspect the exact staged diff,
   and run `git diff --cached --check` before committing.
5. Commit with `feat:`, `fix:`, `docs:`, `refactor:` or `chore:` followed by the
   observable change. Do not put a version number in a normal commit subject.
6. Before pushing, confirm the branch and configured upstream still match the
   requested destination; push without force and verify the resulting branch
   state.
7. Hand the pushed branch to `pr-delivery`, which opens the delivery pull request
   unless the user asked to stop after the push.

A session closure also writes its `bitacora/` entry first, as `session-closure`
requires; an ordinary commit does not need one.

If the requested upstream is missing, diverged or unexpectedly different, stop
before pushing and report the specific blocker. Do not merge on the strength of a
commit or push request.
