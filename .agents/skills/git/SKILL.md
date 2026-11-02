---
name: git
description: Route Git work to the delivery skills that own each stage. Use when a task mentions Git, branches, commits, pushes, pull requests or versioning and the specific stage skill is not obvious yet.
---

# Git entry point

Git work is split by stage. Read the skill that owns the stage you are in instead
of improvising a flow here.

| Stage | Skill | Use it when |
|---|---|---|
| Base | `branch-baseline` | starting a change, creating or switching a branch, or doubting the base |
| Commit and push | `commit-push-versioning` | the user asks to commit, push, or both; version and changelog decision |
| Pull request | `pr-delivery` | opening, updating or checking the delivery pull request |
| Delivery evidence | `verification-before-completion` | deciding whether the collected evidence is enough to call it done |

## Rules that hold in every stage

- Never commit on `main`; one branch per change, created from updated `main`.
- Stage by exact path; `git add .`, `git add -A` and `git add --all` are
  forbidden because they pull in unrelated files.
- Never force push, rewrite published history, tag, release, merge or delete a
  branch without an explicit request.
- Preserve uncommitted work that is not yours.
- Versions identify releases, not commits: pending work accumulates under
  `## Unreleased` in `CHANGELOG.md`.

## Coordination

`session-closure` runs the Git steps at the end of a working session.
`modification-cycle` and `bugfix-delivery-cycle` decide what belongs in the
change; the delivery skills only say how it reaches `main`.
