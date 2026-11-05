# Contributing

Read [AGENTS.md](AGENTS.md) first; it is canonical for this repository. Use
English for code, identifiers, comments, logs, test output and visible fallback
text, and keep each change scoped to one concrete behaviour or responsibility.

## Before you start

- Read the [README](README.md) and the compatibility table it declares.
- Report security problems through [SECURITY.md](SECURITY.md), never in a public
  issue or pull request.
- Open a [bug report](.github/ISSUE_TEMPLATE/bug_report.yml),
  [feature request](.github/ISSUE_TEMPLATE/feature_request.yml),
  [documentation report](.github/ISSUE_TEMPLATE/documentation.yml) or
  [question](.github/ISSUE_TEMPLATE/question.yml).
- [SUPPORT.md](SUPPORT.md) lists what a report needs and what is out of scope.

## Branches and commits

- Update `main`, then create one branch per change with `branch-baseline`:
  `feat/`, `fix/`, `docs/`, `refactor/` or `chore/`. Never start work on `main`
  and never reuse a merged branch.
- Keep unrelated work out of the branch. A review compares `git diff main...HEAD`.
- Subjects use `feat:`, `fix:`, `docs:`, `refactor:` or `chore:` followed by the
  observable change. Do not put a version number in a normal commit subject.
- Stage by exact path; `git add .` and `git add -A` are forbidden.
- Apply `commit-push-versioning` for the commit and push, and `pr-delivery` for
  the pull request.

## Versioning and changelog

Versions identify releases, not commits.

- Pending work accumulates under `## Unreleased` at the top of
  [CHANGELOG.md](CHANGELOG.md).
- Tests, documentation, skills, repository metadata, development tooling and
  comment- or formatting-only changes need neither a changelog entry nor a
  version change. Use `docs:` or `chore:`.
- When the maintainer prepares a release, `Unreleased` entries move under a dated
  `## [<version>] - <YYYY-MM-DD>` heading and every declaration is synchronized in
  the same commit: `KPlugin.Version` in `metadata.json`,
  `project(... VERSION ...)` in `CMakeLists.txt` and `Project-Id-Version` in the
  POT catalog. `project_version_test` fails when those disagree with
  `python3 scripts-dev/check-version.py`.
- The scheme stays `0.9.x.y`; a release advances it once regardless of how many
  commits or features it contains.

## Repository tree

| Path | Owns | Never holds |
| --- | --- | --- |
| `metadata.json` | plugin identity, declared compatibility and version | runtime logic |
| `contents/` | the QML runtime: surfaces, config schema, localized catalogs | C++ sources |
| `src/` | C++ types registered into QML | QML surfaces |
| `tests/` | every CTest entry and its fixtures | shipped QML |
| `scripts-user/` | reversible user entry points and their `lib/` | developer-only tooling |
| `scripts-dev/` | developer orchestration, validation profiles, distro builds | runtime dependencies |
| `po/` | translation catalogs and the POT template | source strings |
| `.agents/` | `AGENTS.md`, the skills and their catalog | runtime code |
| `.github/` | issue forms, the pull request template and funding | credentials |
| `docs/`, `bitacora/` | the local engineering record, ignored by Git | anything a build reads |
| `kde-sdk/` | the local KDE SDK reference tree, ignored by Git | anything shipped |

Generated output, captures, secrets, credentials and build trees never live in a
tracked directory. `docs/` and `bitacora/` are ignored, so a tracked file must not
link to them: a clone does not receive them.

## Local development

```bash
./scripts-dev/setup.sh                     # detect the host and orchestrate the build
./scripts-dev/setup.sh --dependencies-only # install or verify build dependencies
./scripts-dev/setup.sh --local-test        # build, test and install for a runtime check
./scripts-dev/check-build-environment.sh   # report the effective toolchain
```

A manual cycle is:

```bash
cmake -S . -B build -DBUILD_TESTING=ON
cmake --build build
ctest --test-dir build --output-on-failure
```

Run a single check with
`ctest --test-dir build -R '^<name>$' --output-on-failure`. Each test owns unique
temporary directories and must clean its processes, sockets, caches and packages
after success, failure, signal and timeout.

Additional checks:

```bash
python3 scripts-dev/skill_inventory.py --check
./scripts-dev/update-translations.sh
python3 scripts-dev/test-integrity-guard.py --check
```

## Quality and evidence

- Source reading, `qmllint`, offscreen component tests, full CTest, a plasmoide
  load test, a real Plasma session and visual inspection are separate evidence
  levels. State which ones you ran; never present offscreen success as visual or
  Plasma validation.
- `qmllint` debt has a per-distribution baseline in `scripts-dev/`. Never raise
  it; a reduction is recorded downward in the same validated change.
- Visible text is translatable through ki18n. After adding, changing or removing
  it, run `scripts-dev/update-translations.sh` and keep every supported catalog
  complete.
- Do not remove, disable or weaken a behavioural test. Diagnose the production
  code first and add a regression that observes the contract. A legitimate change
  to a protected test is registered before with
  `python3 scripts-dev/test-integrity-guard.py --update --authorized "<motive>"`.
- A prose-only change — READMEs, `CHANGELOG.md`, `docs/`, `AGENTS.md`, skill text,
  `CONTRIBUTING.md`, `SECURITY.md`, `SUPPORT.md` — runs no suite. Run only the
  check whose input you touched and say why the suite was skipped. A documentation
  update shipped with code follows the code.

## Pull requests

- Target `main` from your branch and follow the
  [pull request template](.github/PULL_REQUEST_TEMPLATE.md).
- Describe the observable result, the validation actually performed, and what
  remains unverified.
- Remove personal paths, usernames, tokens, logs and private file contents.
- Every pull request runs the `PR guard` workflow. It rejects binaries,
  symlinks, new executable files and edits to the build or review tooling, and
  re-runs the repository gates. A workflow run from a fork waits for maintainer
  approval before it starts.
- Expect a reply within seven days. If a pull request has none by then, a
  comment on the thread is welcome; opening a duplicate is not.
- Pull requests are squash-merged and the delivery branch is deleted afterwards,
  only when the maintainer asks for it.
- Draft the pull request while the change still awaits review or a real Plasma
  check.

## Reviewing contributions

The same bar applies to a patch written here and to one sent from a fork.

- Read a contribution before approving anything it triggers. Approving a
  workflow run executes the pull request's own workflow definition, so check the
  diff first, especially `.github/`, and never run a fork's code outside an
  approved run.
- Authorize a change to a protected test only after deciding that it is
  legitimate, and record the decision and its motive with
  `--update --authorized`.
- Say no explicitly. Thank the person, explain why the change does not fit, and
  link to the document that states the rule. One or two sentences are enough;
  leaving a pull request unanswered is worse than closing it.
- Review the code, not the person. Prefix each comment with its intent —
  `issue:`, `suggestion:`, `question:`, `nitpick:` — and state whether it blocks
  the merge. Praise what deserves it; invented praise is worse than none.
- Squash merging preserves authorship. When a patch is rewritten or completed
  here, add a `Co-authored-by` trailer, and thank the contributor on the pull
  request once the change is in.
- Merging grants no permissions. Collaborator access is a separate, deliberate
  decision.

## Licensing and attribution

The project is GPL-3.0-or-later. Preserve the license and copyright of reused
code and assets, and record new attribution in [NOTICE](NOTICE).
