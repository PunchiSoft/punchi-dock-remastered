# Test integrity mechanism

The tests are the evidence of the Punchi Dock contract, not an obstacle to a
favourable result. A green suite obtained by weakening a test hides the bug the
test existed to catch.

The canonical policy lives in `AGENTS.md`, section "Test integrity". This folder
holds the data the guard uses; this file documents how to operate it.

## What is protected

| Group | What it covers | How it is protected |
|---|---|---|
| Tests | Every file under `tests/` tracked by Git | SHA-256 per file |
| Infrastructure | `tests/CMakeLists.txt`, the QML runner, the test helper configs, `tests/translation_catalog_semantics.py` | SHA-256 (they live under `tests/`) |
| Canonical names | The `ctest -N` name set of the profile | Name manifest; the set may grow, never lose an entry |
| Quantity | The number of tests per profile | `MIN_TESTS` floor |
| Deactivation signals | `DISABLED`, `WILL_FAIL`, `SKIP_RETURN_CODE`, `skip(`, `ignoreWarning`, `QEXPECT_FAIL`, `ctest -E`, `ctest ... \|\| true` | Documented pattern baseline |
| Gates | `scripts-user/lib/package-plasmoid.sh` | Functional contract: must keep running `ctest` and this guard, unmasked and unfiltered |

The mechanism data files themselves (`hashes.txt`, the name manifests, the floor
files, `patterns-baseline.txt`) are protected by the update rules: the ordinary
update path can only add. Removing an entry, replacing a hash or lowering the
floor is refused unless the user authorizes it.

`hashes.txt` is not listed inside itself: a file cannot hash its own content.
Its integrity relies on the update rules and on the reviewed diff.

## Files

| File | Role |
|---|---|
| `hashes.txt` | SHA-256 of every protected path |
| `manifest-<profile>.txt` | Canonical CTest names for one platform profile |
| `patterns-baseline.txt` | Pre-existing deactivation signals, reviewed and documented |
| `../../scripts-dev/tests-baseline-<profile>.env` | `MIN_TESTS` floor for one platform profile |

## Commands

```bash
# Verify. Fails when something protected changed without authorization.
python3 scripts-dev/test-integrity-guard.py --check

# Record the current state. Additions need no authorization; a destructive
# change is refused unless the user authorized it.
python3 scripts-dev/test-integrity-guard.py --update
python3 scripts-dev/test-integrity-guard.py --update --authorized "<motive>"

# List the deactivation signals and their state. Never fails.
python3 scripts-dev/test-integrity-guard.py --report

# Exercise the guard on temporary fixtures. Never touches the project.
python3 scripts-dev/test-integrity-guard.py --self-test
```

Useful options: `--profile`, `--root`, `--build-dir`, `--ctest-names-file`.

Exit codes: `0` pass, `1` a protected change needs authorization, `2` environment
or usage problem.

## Procedure when a test fails

1. Investigate the production code first. Do not assume the test is wrong.
2. If the test itself seems to need a change, stop before touching it and report:
   test name and path, observed failure, contract it verifies, estimated cause,
   why the test and not the code should change, and the concrete proposal.
3. Wait for explicit authorization.
4. Only then modify the test and run
   `--update --authorized "<motive>"`, which prints the receipt to keep in the
   session record and in the modification or review document.
5. Commit the test change and the updated mechanism data together, so the diff of
   the manifest is the evidence of what was authorized.

Adding a brand-new test file needs no authorization. Once the file is tracked by
Git it must be incorporated with `--update`, which only adds entries. If
registering it requires editing `tests/CMakeLists.txt`, that edit is a protected
change: report it before making it.

## Known limits

- The guard reports a change; it does not judge whether a changed assertion is
  weaker or stronger. The reviewed diff is the decision artifact.
- A local mechanism cannot stop a determined agent from editing the tool or the
  data by hand. It converts a silent change into a visible, dated, reviewable one.
- The floor and the name manifest are only verified when a configured build
  directory exists. The hash layer always applies.
- Purely cosmetic trimming of a name manifest is not detected, but the test it
  names still runs and is still hashed, so no protection is actually lost.
- A legitimate change to the mechanism itself is recorded through the same
  authorized update path as a legitimate test change.
