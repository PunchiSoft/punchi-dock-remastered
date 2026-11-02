---
name: pr-delivery
description: Open, verify, and close the delivery pull request for an approved branch, with a commit-derived title, a structured English body, real validation evidence, and rebase-only conflict handling. Use when the user asks to open, publish, update, or check a pull request.
---

# Pull request delivery

Use when the user asks to open, publish, update or check a pull request, or asks
for commit and push after approving implemented and validated work. Merging,
tags, releases, branch deletion and rewriting another branch each need their own
request.

## Before opening

- The work sits on one delivery branch created from updated `main` by
  `branch-baseline`, never on `main`.
- `commit-push-versioning` already committed the reviewed scope. If the branch
  prepares a release, it moved the `Unreleased` entries into a dated heading and
  synchronized every version declaration.
- The evidence exists: the validation the change required, including full CTest
  and any real Plasma session check actually performed. Never present offscreen,
  static or lint results as desktop behaviour.
- `verification-before-completion` settled which evidence levels were executed;
  the body reports those and names what was not executed.
- `git status` contains no unrelated or ignored material, the branch is pushed,
  and its head matches the commit that was reviewed.

## Title and body

Use the primary commit subject as the title. Follow
`.github/PULL_REQUEST_TEMPLATE.md` and keep the body short and structured,
describing observed behaviour instead of a file list:

```markdown
## Summary
<Cause, or the new capability, and its observable effect.>

## Changes
- <Behaviour changed and the layer that owns it.>
- <Regression test added or adjusted.>

## Validation
| Check | Result |
|---|---|
| Full CTest | <n>/<n> passed |
| qmllint baseline | <total>/<unqualified>/<missing-property>/<layout>/<import> |
| Translations | <catalogs state> |
| Test integrity | <gate result> |
| Security preflight | <result> |
| Real Plasma session | <what was observed, or "not run"> |

## References
- Fixes #<issue> (only when that issue exists and this change closes it)

## Pending
- <Limitation, unvalidated surface, follow-up>
```

Omit a section instead of writing "none". Keep failed attempts out of the summary
unless they explain the final shape. State explicitly when a visual, KWin,
Wayland or packaging check was not performed.

## Create

- `gh pr create --base main --head <branch> --body-file <file>` with the reviewed
  markdown, so the body keeps its formatting; remove the temporary file
  afterwards.
- Use `--draft` while the change still awaits user approval or real-session
  validation.
- Apply only labels that already exist (`gh label list`); never invent labels,
  milestones, assignees or issue references.
- Link an issue with `Fixes #n` only when the pull request closes it; otherwise
  write `Part of #n`.

## Verify

- Read `gh pr view --json url,mergeable,mergeStateStatus,baseRefName,headRefName`
  and confirm the base is `main`, the head is the delivery branch, and the
  changed files match the reviewed scope.
- When the base moved, rebase onto `origin/main`; never create a merge commit from
  the delivery branch. Resolve conflicts preserving the behaviour already
  validated, re-run the affected checks, then publish with `--force-with-lease`
  and never plain `--force`.
- Reconcile the release version and its declarations if the rebase crosses
  another release.

## Close

- Report the URL, the state and any check that remains; update the modification
  or review note with the final evidence.
- Pull requests are squash-merged and the delivery branch is deleted afterwards,
  but only when the user asks: do not merge, tag, release or delete a branch on
  your own, and never delete a branch that still has unmerged commits.

## Anti-patterns

- Opening the pull request before validation or before the work was approved.
- Mixing unrelated changes, private notes or ignored build output into the branch.
- A body that lists files instead of behaviour.
- Claiming dock, KWin or visual validation from CTest alone.
- Plain force pushes, invented labels or unrelated `Fixes` references.
